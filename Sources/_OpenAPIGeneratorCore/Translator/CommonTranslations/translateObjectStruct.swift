//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import OpenAPIKit

extension TypesFileTranslator {

    /// Returns a declaration of an object schema.
    ///
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared structure.
    ///   - openAPIDescription: A user-specified description from the OpenAPI
    ///     document.
    ///   - objectContext: The context for the object, including information
    ///     such as the names and schemas of the object's properties.
    ///   - isDeprecated: A flag indicating whether the object is deprecated.
    /// - Throws: An error if there is an issue during translation.
    /// - Returns: A declaration representing the translated object schema.
    func translateObjectStruct(
        typeName: TypeName,
        openAPIDescription: String?,
        objectContext: JSONSchema.ObjectContext,
        isDeprecated: Bool
    ) throws -> Declaration {
        let documentedProperties: [PropertyBlueprint] = try objectContext.properties
            .filter { key, value in

                let foundIn = "\(typeName.description)/\(key)"

                // Properties that are only defined in the `required` list but don't
                // have a proper definition in the `properties` map are skipped, as they
                // often imply a typo or a mistake in the document. So emit a diagnostic as well.
                guard !value.inferred else {
                    try diagnostics.emit(
                        .warning(
                            message:
                                "A property name only appears in the required list, but not in the properties map - this is likely a typo; skipping this property.",
                            context: ["foundIn": foundIn]
                        )
                    )
                    return false
                }

                // We need to catch a special case here:
                // type: string + format: binary.
                // It means binary data (unlike format: byte, which means base64
                // and cannot be used in a structured object, such as in JSON.
                // It's only valid as the root schema of a request or response.
                // However, it _is_ a supported schema, so the following
                // filtering would not exclude it.
                // Since this is the only place we filter which schemas are
                // allowed in object properties, explicitly filter these out
                // here.
                if value.isString && value.formatString == "binary" {
                    try diagnostics.emitUnsupportedSchema(
                        reason: "Binary properties in object schemas.",
                        schema: value,
                        foundIn: foundIn
                    )
                    return false
                }

                return try validateSchemaIsSupported(value, foundIn: "\(typeName.description)/\(key)")
            }
            .map { key, value in
                let propertyType = try typeAssigner.typeUsage(
                    forObjectPropertyNamed: key,
                    withSchema: value,
                    components: components,
                    inParent: typeName
                )
                let comment: Comment? = .property(
                    originalName: key,
                    userDescription: value.description,
                    parent: typeName
                )
                let associatedDeclarations: [Declaration]
                if typeMatcher.isInlinable(value) {
                    associatedDeclarations = try translateSchema(
                        typeName: propertyType.typeName,
                        schema: value,
                        overrides: .none
                    )
                } else {
                    associatedDeclarations = []
                }
                return PropertyBlueprint(
                    comment: comment,
                    isDeprecated: value.deprecated,
                    originalName: key,
                    typeUsage: propertyType,
                    associatedDeclarations: associatedDeclarations,
                    context: context
                )
            }

        let comment = typeName.docCommentWithUserDescription(openAPIDescription)

        let (codableStrategy, extraProperty) = try parseAdditionalProperties(in: objectContext, parent: typeName)

        let extraProperties: [PropertyBlueprint]
        if let extraProperty { extraProperties = [extraProperty] } else { extraProperties = [] }

        return translateStructBlueprint(
            StructBlueprint(
                comment: comment,
                isDeprecated: isDeprecated,
                access: config.access,
                typeName: typeName,
                conformances: Constants.ObjectStruct.conformances,
                shouldGenerateCodingKeys: true,
                codableStrategy: codableStrategy,
                properties: documentedProperties + extraProperties
            )
        )
    }

    /// Parses the appropriate information about additionalProperties for
    /// an object struct.
    /// - Parameters:
    ///   - objectContext: The context describing the object.
    ///   - parent: The parent type name where this function is called from.
    /// - Returns: The kind of Codable implementation required for the struct,
    ///   and an extra property to be added to the struct, if needed.
    /// - Throws: An error if there is an issue during parsing.
    func parseAdditionalProperties(in objectContext: JSONSchema.ObjectContext, parent: TypeName) throws -> (
        StructBlueprint.OpenAPICodableStrategy, PropertyBlueprint?
    ) {
        guard let additionalProperties = objectContext.additionalProperties else { return (.synthesized, nil) }

        let typeUsage: TypeUsage
        let associatedDeclarations: [Declaration]

        switch additionalProperties {
        case .a(let hasAdditionalProperties):
            guard hasAdditionalProperties else { return (.enforcingNoAdditionalProperties, nil) }
            typeUsage = TypeName.objectContainer.asUsage
            associatedDeclarations = []
        case .b(let schema):
            let valueTypeUsage = try typeAssigner.typeUsage(
                forObjectPropertyNamed: Constants.AdditionalProperties.variableName,
                withSchema: schema,
                components: components,
                inParent: parent
            )
            if typeMatcher.isInlinable(schema) {
                associatedDeclarations = try translateSchema(
                    typeName: valueTypeUsage.typeName,
                    schema: schema,
                    overrides: .none
                )
            } else {
                associatedDeclarations = []
            }
            // The schema specified in `additionalProperties` represents
            // the value of a dictionary, rather than the property itself.
            // Transform the type usage to reflect that here.
            typeUsage = valueTypeUsage.asDictionaryValue
        }

        let extraProperty = PropertyBlueprint(
            comment: .doc("A container of undocumented properties."),
            originalName: Constants.AdditionalProperties.variableName,
            typeUsage: typeUsage,
            default: .emptyInit,
            isSerializedInTopLevelDictionary: false,
            associatedDeclarations: associatedDeclarations,
            context: context
        )
        return (.allowingAdditionalProperties, extraProperty)
    }
}
