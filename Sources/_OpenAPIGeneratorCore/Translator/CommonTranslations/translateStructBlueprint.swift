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

extension FileTranslator {

    /// Returns a declaration of the specified blueprint.
    /// - Parameter blueprint: Structure blueprint containing the information
    /// required to generate the Swift structure.
    func translateStructBlueprint(
        _ blueprint: StructBlueprint
    ) -> Declaration {

        let typeName = blueprint.typeName
        let allProperties = blueprint.properties
        let serializableProperties = allProperties.filter(\.isSerializedInTopLevelDictionary)

        let propertyDecls =
            allProperties
            .flatMap(translatePropertyBlueprint)

        var members = propertyDecls
        let initDecl = translateStructBlueprintInitializer(
            typeName: typeName,
            properties: allProperties
        )
        members.append(initDecl)

        if blueprint.shouldGenerateCodingKeys && !serializableProperties.isEmpty {
            let codingKeysDecl = translateStructBlueprintCodingKeys(
                properties: serializableProperties
            )
            members.append(codingKeysDecl)
        }

        if let customDecoder = translateStructBlueprintDecoder(
            strategy: blueprint.codableStrategy,
            properties: serializableProperties
        ) {
            members.append(customDecoder)
        }

        if let customEncoder = translateStructBlueprintEncoder(
            strategy: blueprint.codableStrategy,
            properties: serializableProperties
        ) {
            members.append(customEncoder)
        }

        let structDesc = StructDescription(
            accessModifier: config.access,
            name: typeName.shortSwiftName,
            conformances: blueprint.conformances,
            members: members
        )

        return .commentable(blueprint.comment, .struct(structDesc).deprecate(if: blueprint.isDeprecated))
    }

    /// Returns a declaration of an initializer declared in a structure.
    /// - Parameters:
    ///   - typeName: The type name of the structure.
    ///   - properties: The properties to include in the initializer.
    func translateStructBlueprintInitializer(
        typeName: TypeName,
        properties: [PropertyBlueprint]
    ) -> Declaration {

        let comment: Comment = .doc(
            properties.initializerComment(
                typeName: typeName.shortSwiftName
            )
        )

        let decls: [(ParameterDescription, String)] =
            properties
            .map { property in
                (
                    ParameterDescription(
                        label: property.swiftSafeName,
                        type: property.renderedFullyQualifiedSwiftName,
                        defaultValue: property.defaultValue?.asExpression
                    ),
                    property.swiftSafeName
                )
            }

        let parameters = decls.map(\.0)
        let assignments: [CodeBlock] = decls.map(\.1)
            .map { variableName in
                .expression(
                    .assignment(
                        Expression
                            .identifier("self")
                            .dot(variableName)
                            .equals(.identifier(variableName))
                    )
                )
            }

        return .commentable(
            comment,
            .function(
                accessModifier: config.access,
                kind: .initializer,
                parameters: parameters,
                body: assignments
            )
        )
    }

    /// Returns a list of declarations for a specified property blueprint.
    ///
    /// May return multiple declarations when the property contains an unnamed
    /// JSON schema, in which case a type declaration of that type is included
    /// in the returned array.
    /// - Parameter property: Information about the property.
    func translatePropertyBlueprint(
        _ property: PropertyBlueprint
    ) -> [Declaration] {
        let propertyTypeName = property.renderedFullyQualifiedSwiftName
        let propertyDecl: Declaration = .commentable(
            property.comment,
            .variable(
                .init(
                    accessModifier: config.access,
                    kind: .var,
                    left: property.swiftSafeName,
                    type: propertyTypeName
                )
            )
            .deprecate(if: property.isDeprecated)
        )
        return property.associatedDeclarations + [propertyDecl]
    }

    /// Returns a declaration of a coding keys enum.
    /// - Parameter blueprint: Information about the structure.
    func translateStructBlueprintCodingKeys(
        properties: [PropertyBlueprint]
    ) -> Declaration {
        let members: [Declaration] =
            properties
            .map { property in
                let swiftName = property.swiftSafeName
                let rawName = property.originalName
                return .enumCase(
                    name: swiftName,
                    kind: swiftName == rawName ? .nameOnly : .nameWithRawValue(.string(property.originalName))
                )
            }
        return .enum(
            accessModifier: config.access,
            name: Constants.Codable.codingKeysName,
            conformances: Constants.Codable.conformances,
            members: members
        )
    }
}

fileprivate extension Array where Element == PropertyBlueprint {

    /// Returns the comment string for an initializer of a structure with
    /// the properties contained in the current array.
    func initializerComment(typeName: String) -> String {
        var components: [String] = [
            "Creates a new `\(typeName)`."
        ]
        if !isEmpty {
            var parameterComponents: [String] = []
            parameterComponents.append("- Parameters:")
            for parameter in self {
                parameterComponents.append(
                    "  - \(parameter.swiftSafeName): \(parameter.comment?.firstLineOfContent ?? "")"
                )
            }
            components.append("")
            components.append(parameterComponents.joined(separator: "\n"))
        }
        return components.joined(separator: "\n")
    }
}
