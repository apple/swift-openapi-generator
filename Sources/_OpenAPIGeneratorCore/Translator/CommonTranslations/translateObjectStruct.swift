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
import OpenAPIKit30

extension FileTranslator {

    /// Returns a declaration of an object schema.
    ///
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared structure.
    ///   - openAPIDescription: A user-specified description from the OpenAPI
    ///   document.
    ///   - objectContext: The context for the object, including information
    ///   such as the names and schemas of the object's properties.
    func translateObjectStruct(
        typeName: TypeName,
        openAPIDescription: String?,
        objectContext: JSONSchema.ObjectContext,
        isDeprecated: Bool
    ) throws -> Declaration {

        let documentedProperties: [PropertyBlueprint] =
            try objectContext
            .properties
            .filter { key, value in
                try validateSchemaIsSupported(
                    value,
                    foundIn: "\(typeName.description)/\(key)"
                )
            }
            .map { key, value in
                let propertyType = try typeAssigner.typeUsage(
                    forObjectPropertyNamed: key,
                    withSchema: value,
                    inParent: typeName
                )
                let comment: Comment? = .property(
                    originalName: key,
                    userDescription: value.description,
                    parent: typeName
                )
                let associatedDeclarations: [Declaration]
                if TypeMatcher.isInlinable(value) {
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
                    asSwiftSafeName: swiftSafeName
                )
            }

        let comment =
            typeName
            .docCommentWithUserDescription(openAPIDescription)

        let (codableStrategy, extraProperty) = try parseAdditionalProperties(
            in: objectContext,
            parent: typeName
        )

        let extraProperties: [PropertyBlueprint]
        if let extraProperty {
            extraProperties = [extraProperty]
        } else {
            extraProperties = []
        }

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
    /// - Parameter objectContext: The context describing the object.
    /// - Returns: The kind of Codable implementation required for the struct,
    /// and an extra property to be added to the struct, if needed.
    func parseAdditionalProperties(
        in objectContext: JSONSchema.ObjectContext,
        parent: TypeName
    ) throws -> (StructBlueprint.OpenAPICodableStrategy, PropertyBlueprint?) {
        guard let additionalProperties = objectContext.additionalProperties else {
            return (.synthesized, nil)
        }

        let typeUsage: TypeUsage
        let associatedDeclarations: [Declaration]

        switch additionalProperties {
        case .a(let hasAdditionalProperties):
            guard hasAdditionalProperties else {
                return (.enforcingNoAdditionalProperties, nil)
            }
            typeUsage = TypeName.objectContainer.asUsage
            associatedDeclarations = []
        case .b(let schema):
            let valueTypeUsage = try typeAssigner.typeUsage(
                forObjectPropertyNamed: "additionalProperties",
                withSchema: schema,
                inParent: parent
            )
            if TypeMatcher.isInlinable(schema) {
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

        let extraProperty: PropertyBlueprint = .init(
            comment: .doc("A container of undocumented properties."),
            originalName: "additionalProperties",
            typeUsage: typeUsage,
            default: .emptyInit,
            isSerializedInTopLevelDictionary: false,
            associatedDeclarations: associatedDeclarations,
            asSwiftSafeName: swiftSafeName
        )
        return (.allowingAdditionalProperties, extraProperty)
    }
}
