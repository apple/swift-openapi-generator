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

extension FileTranslator {

    /// Returns a declaration for an allOf or anyOf schema.
    ///
    /// The last declaration in the list is the structure for the allOf/anyOf,
    /// but any additional declarations in the array might be for nested types
    /// defined as unnamed schemas in the OpenAPI document.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared structure.
    ///   - openAPIDescription: A user-specified description from the OpenAPI
    ///   document.
    ///   - schemas: The child schemas of the allOf/anyOf.
    func translateAllOrAnyOf(
        typeName: TypeName,
        openAPIDescription: String?,
        type: AllOrAnyOf,
        schemas: [JSONSchema]
    ) throws -> Declaration {
        let properties: [PropertyBlueprint] =
            try schemas
            .enumerated()
            .map { index, schema in
                let key = "value\(index+1)"
                let rawPropertyType = try typeAssigner.typeUsage(
                    forAllOrAnyOrOneOfChildSchemaNamed: key,
                    withSchema: schema,
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
                if TypeMatcher.isInlinable(schema) {
                    associatedDeclarations = try translateSchema(
                        typeName: propertyType.typeName,
                        schema: schema,
                        overrides: .none
                    )
                } else {
                    associatedDeclarations = []
                }
                return PropertyBlueprint(
                    comment: comment,
                    originalName: key,
                    typeUsage: propertyType,
                    associatedDeclarations: associatedDeclarations,
                    asSwiftSafeName: swiftSafeName
                )
            }
        let comment: Comment? =
            typeName
            .docCommentWithUserDescription(openAPIDescription)
        let codableStrategy: StructBlueprint.OpenAPICodableStrategy
        switch type {
        case .allOf:
            codableStrategy = .allOf
        case .anyOf:
            codableStrategy = .anyOf
        }
        let structDecl = translateStructBlueprint(
            .init(
                comment: comment,
                access: config.access,
                typeName: typeName,
                conformances: Constants.ObjectStruct.conformances,
                shouldGenerateCodingKeys: false,
                codableStrategy: codableStrategy,
                properties: properties
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
    func translateOneOf(
        typeName: TypeName,
        openAPIDescription: String?,
        discriminator: OpenAPI.Discriminator?,
        schemas: [JSONSchema]
    ) throws -> Declaration {
        let cases: [(String, [String]?, Comment?, TypeUsage, [Declaration])]
        if let discriminator {
            // > When using the discriminator, inline schemas will not be considered.
            // > — https://spec.openapis.org/oas/v3.0.3#discriminator-object
            let includedSchemas: [JSONReference<JSONSchema>] =
                schemas
                .compactMap { schema in
                    guard case let .reference(ref, _) = schema.value else {
                        return nil
                    }
                    return ref
                }
            let mappedTypes = try discriminator.allTypes(
                schemas: includedSchemas,
                typeAssigner: typeAssigner
            )
            cases = mappedTypes.map { mappedType in
                let comment: Comment? = .child(
                    originalName: mappedType.typeName.shortSwiftName,
                    userDescription: nil,
                    parent: typeName
                )
                let caseName = safeSwiftNameForOneOfMappedType(mappedType)
                return (caseName, mappedType.rawNames, comment, mappedType.typeName.asUsage, [])
            }
        } else {
            cases = try schemas.enumerated()
                .map { index, schema in
                    let key = "case\(index+1)"
                    let childType = try typeAssigner.typeUsage(
                        forAllOrAnyOrOneOfChildSchemaNamed: key,
                        withSchema: schema,
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
                    if TypeMatcher.isInlinable(schema) {
                        associatedDeclarations = try translateSchema(
                            typeName: childType.typeName,
                            schema: schema,
                            overrides: .none
                        )
                    } else {
                        associatedDeclarations = []
                    }
                    return (caseName, nil, comment, childType, associatedDeclarations)
                }
        }

        let caseDecls: [Declaration] = cases.flatMap { caseInfo in
            let (caseName, _, comment, childType, associatedDeclarations) = caseInfo
            return associatedDeclarations + [
                .commentable(
                    comment,
                    .enumCase(
                        name: caseName,
                        kind: .nameWithAssociatedValues([
                            .init(
                                label: nil,
                                type: childType.fullyQualifiedSwiftName
                            )
                        ])
                    )
                )
            ]
        }

        let caseNames = cases.map(\.0)

        let codingKeysDecls: [Declaration]
        let decoder: Declaration
        if let discriminator {
            let originalName = discriminator.propertyName
            let swiftName = swiftSafeName(for: originalName)
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
            decoder = translateOneOfWithoutDiscriminatorDecoder(
                caseNames: caseNames
            )
        }

        let encoder = translateOneOfEncoder(caseNames: caseNames)

        let comment: Comment? =
            typeName
            .docCommentWithUserDescription(openAPIDescription)
        let enumDecl: Declaration = .enum(
            isFrozen: true,
            accessModifier: config.access,
            name: typeName.shortSwiftName,
            conformances: Constants.ObjectStruct.conformances,
            members: caseDecls + codingKeysDecls + [
                decoder,
                encoder,
            ]
        )
        return .commentable(comment, enumDecl)
    }
}
