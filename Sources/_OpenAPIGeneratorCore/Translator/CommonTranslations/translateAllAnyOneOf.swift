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

/// Describes one of the two options: allOf or anyOf.
enum AllOrAnyOf {

    /// An allOf schema.
    case allOf

    /// An anyOf schema.
    case anyOf
}

extension TypesFileTranslator {

    /// Returns a declaration for an allOf or anyOf schema.
    ///
    /// The last declaration in the list is the structure for the allOf/anyOf,
    /// but any additional declarations in the array might be for nested types
    /// defined as unnamed schemas in the OpenAPI document.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared structure.
    ///   - openAPIDescription: A user-specified description from the OpenAPI document.
    ///   - type: The type of schema (allOf or anyOf).
    ///   - schemas: The child schemas of the allOf/anyOf.
    /// - Throws: An error if there is an issue during translation.
    /// - Returns: A declaration representing the translated allOf/anyOf structure.
    func translateAllOrAnyOf(typeName: TypeName, openAPIDescription: String?, type: AllOrAnyOf, schemas: [JSONSchema])
        throws -> Declaration
    {
        let properties: [(property: PropertyBlueprint, isKeyValuePair: Bool)] = try schemas.enumerated()
            .map { index, schema in
                let key = "value\(index+1)"
                let rawPropertyType = try typeAssigner.typeUsage(
                    forAllOrAnyOrOneOfChildSchemaNamed: key,
                    withSchema: schema,
                    components: components,
                    inParent: typeName
                )
                let propertyType: TypeUsage
                switch type {
                case .allOf:
                    // AllOf uses all required properties.
                    propertyType = rawPropertyType.withOptional(false)
                case .anyOf:
                    // AnyOf uses all optional properties.
                    propertyType = rawPropertyType.withOptional(true)
                }
                let comment: Comment? = .property(
                    originalName: key,
                    userDescription: schema.description,
                    parent: typeName
                )
                let associatedDeclarations: [Declaration]
                if typeMatcher.isInlinable(schema) {
                    associatedDeclarations = try translateSchema(
                        typeName: propertyType.typeName,
                        schema: schema,
                        overrides: .none
                    )
                } else {
                    associatedDeclarations = []
                }
                let blueprint = PropertyBlueprint(
                    comment: comment,
                    originalName: key,
                    typeUsage: propertyType,
                    associatedDeclarations: associatedDeclarations,
                    context: context
                )
                var referenceStack = ReferenceStack.empty
                let isKeyValuePairSchema = try typeMatcher.isKeyValuePair(
                    schema,
                    referenceStack: &referenceStack,
                    components: components
                )
                return (blueprint, isKeyValuePairSchema)
            }
        let comment: Comment? = typeName.docCommentWithUserDescription(openAPIDescription)
        let isKeyValuePairValues = properties.map(\.isKeyValuePair)
        let propertyValues = properties.map(\.property)
        let codableStrategy: StructBlueprint.OpenAPICodableStrategy
        switch type {
        case .allOf: codableStrategy = .allOf(propertiesIsKeyValuePairSchema: isKeyValuePairValues)
        case .anyOf: codableStrategy = .anyOf(propertiesIsKeyValuePairSchema: isKeyValuePairValues)
        }
        let structDecl = translateStructBlueprint(
            .init(
                comment: comment,
                access: config.access,
                typeName: typeName,
                conformances: Constants.ObjectStruct.conformances,
                shouldGenerateCodingKeys: false,
                codableStrategy: codableStrategy,
                properties: propertyValues
            )
        )
        return structDecl
    }

    /// Returns a declaration for a oneOf schema.
    ///
    /// The last declaration in the list is the structure for the oneOf,
    /// but any additional declarations in the array might be for nested types
    /// defined as unnamed schemas in the OpenAPI document.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared structure.
    ///   - openAPIDescription: A user-specified description from the OpenAPI
    ///   document.
    ///   - discriminator: A discriminator specified in the OpenAPI document.
    ///   - schemas: The child schemas of the oneOf.
    /// - Throws: An error if there is an issue during translation.
    /// - Returns: A declaration representing the translated oneOf structure.
    func translateOneOf(
        typeName: TypeName,
        openAPIDescription: String?,
        discriminator: OpenAPI.Discriminator?,
        schemas: [JSONSchema]
    ) throws -> Declaration {
        let cases: [(String, [String]?, Bool, Comment?, TypeUsage, [Declaration])]
        if let discriminator {
            // > When using the discriminator, inline schemas will not be considered.
            // > — https://spec.openapis.org/oas/v3.0.3#discriminator-object
            let includedSchemas: [JSONReference<JSONSchema>] = schemas.compactMap { schema in
                guard case let .reference(ref, _) = schema.value else { return nil }
                return ref
            }
            let mappedTypes = try discriminator.allTypes(schemas: includedSchemas, typeAssigner: typeAssigner)
            cases = mappedTypes.map { mappedType in
                let comment: Comment? = .child(
                    originalName: mappedType.typeName.shortSwiftName,
                    userDescription: nil,
                    parent: typeName
                )
                let caseName = safeSwiftNameForOneOfMappedType(mappedType)
                return (caseName, mappedType.rawNames, true, comment, mappedType.typeName.asUsage, [])
            }
        } else {
            cases = try schemas.enumerated()
                .map { index, schema in
                    let key = "case\(index+1)"
                    let childType = try typeAssigner.typeUsage(
                        forAllOrAnyOrOneOfChildSchemaNamed: key,
                        withSchema: schema,
                        components: components,
                        inParent: typeName
                    )
                    let caseName: String
                    // Only use the type name for the case for references,
                    // as inline schemas have nothing that guarantees uniqueness.
                    if schema.isReference {
                        // Use the type name.
                        caseName = childType.typeName.shortSwiftName
                    } else {
                        // Use a position-based key.
                        caseName = key
                    }
                    let comment: Comment? = .child(
                        originalName: key,
                        userDescription: schema.description,
                        parent: typeName
                    )
                    let associatedDeclarations: [Declaration]
                    if typeMatcher.isInlinable(schema) {
                        associatedDeclarations = try translateSchema(
                            typeName: childType.typeName,
                            schema: schema,
                            overrides: .none
                        )
                    } else {
                        associatedDeclarations = []
                    }
                    var referenceStack = ReferenceStack.empty
                    let isKeyValuePair = try typeMatcher.isKeyValuePair(
                        schema,
                        referenceStack: &referenceStack,
                        components: components
                    )
                    return (caseName, nil, isKeyValuePair, comment, childType, associatedDeclarations)
                }
        }

        let caseDecls: [Declaration] = cases.flatMap { caseInfo in
            let (caseName, _, _, comment, childType, associatedDeclarations) = caseInfo
            return associatedDeclarations + [
                .commentable(
                    comment,
                    .enumCase(
                        name: caseName,
                        kind: .nameWithAssociatedValues([.init(label: nil, type: .init(childType))])
                    )
                )
            ]
        }

        let codingKeysDecls: [Declaration]
        let decoder: Declaration
        if let discriminator {
            let originalName = discriminator.propertyName
            let swiftName = context.asSwiftSafeName(originalName)
            codingKeysDecls = [
                .enum(
                    accessModifier: config.access,
                    name: Constants.Codable.codingKeysName,
                    conformances: Constants.Codable.conformances,
                    members: [
                        .enumCase(
                            name: swiftName,
                            kind: swiftName == originalName ? .nameOnly : .nameWithRawValue(.string(originalName))
                        )
                    ]
                )
            ]
            decoder = translateOneOfWithDiscriminatorDecoder(
                discriminatorName: swiftName,
                cases: cases.map { ($0.0, $0.1!) }
            )
        } else {
            codingKeysDecls = []
            decoder = translateOneOfWithoutDiscriminatorDecoder(cases: cases.map { ($0.0, $0.2) })
        }

        let encoder = translateOneOfEncoder(cases: cases.map { ($0.0, $0.2) })

        let comment: Comment? = typeName.docCommentWithUserDescription(openAPIDescription)
        let enumDecl: Declaration = .enum(
            isFrozen: true,
            accessModifier: config.access,
            name: typeName.shortSwiftName,
            conformances: Constants.ObjectStruct.conformances,
            members: caseDecls + codingKeysDecls + [decoder, encoder]
        )
        return .commentable(comment, enumDecl)
    }
}
