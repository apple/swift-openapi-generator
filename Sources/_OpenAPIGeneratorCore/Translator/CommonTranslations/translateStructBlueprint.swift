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
    /// - Returns: A `Declaration` representing the generated Swift structure.
    func translateStructBlueprint(_ blueprint: StructBlueprint) -> Declaration {

        let typeName = blueprint.typeName
        let allProperties = blueprint.properties
        let serializableProperties = allProperties.filter(\.isSerializedInTopLevelDictionary)

        let propertyDecls = allProperties.flatMap(translatePropertyBlueprint)

        var members = propertyDecls
        let initializers = translateStructBlueprintInitializers(
            typeName: typeName,
            properties: allProperties,
            initializerContext: blueprint.initializerContext
        )
        members.append(contentsOf: initializers)

        if blueprint.shouldGenerateCodingKeys && !serializableProperties.isEmpty {
            let codingKeysDecl = translateStructBlueprintCodingKeys(properties: serializableProperties)
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

    /// Returns declarations of initializers for a structure.
    /// - Parameters:
    ///   - typeName: The type name of the structure.
    ///   - properties: The properties to include in the initializer.
    ///   - initializerContext: Context that determines what initializers to generate.
    /// - Returns: An array of `Declaration` representing the initializers.
    func translateStructBlueprintInitializers(
        typeName: TypeName,
        properties: [PropertyBlueprint],
        initializerContext: StructBlueprint.InitializerContext
    ) -> [Declaration] {
        var initializers: [Declaration] = []

        // Always include the memberwise initializer
        let memberwiseInit = translateMemberwiseInitializer(typeName: typeName, properties: properties)
        initializers.append(memberwiseInit)

        // Add context-specific initializers
        switch initializerContext {
        case .memberwise:
            break // No additional initializers
        case .multipartPayload(let originalSchema):
            if let valueInit = translateMultipartValueInitializer(
                typeName: typeName,
                properties: properties,
                originalSchema: originalSchema
            ) {
                initializers.append(valueInit)
            }
        }

        return initializers
    }

    /// Returns a declaration of the memberwise initializer for a structure.
    /// - Parameters:
    ///   - typeName: The type name of the structure.
    ///   - properties: The properties to include in the initializer.
    /// - Returns: A `Declaration` representing the memberwise initializer.
    func translateMemberwiseInitializer(typeName: TypeName, properties: [PropertyBlueprint]) -> Declaration {
        let comment: Comment = properties.initializerComment(typeName: typeName.shortSwiftName)

        let decls: [(ParameterDescription, String)] = properties.map { property in
            (
                ParameterDescription(
                    label: property.swiftSafeName,
                    type: .init(property.typeUsage),
                    defaultValue: property.defaultValue?.asExpression
                ), property.swiftSafeName
            )
        }

        let parameters = decls.map(\.0)
        let assignments: [CodeBlock] = decls.map(\.1)
            .map { variableName in
                .expression(
                    .assignment(
                        Expression.identifierPattern("self").dot(variableName).equals(.identifierPattern(variableName))
                    )
                )
            }

        return .commentable(
            comment,
            .function(accessModifier: config.access, kind: .initializer, parameters: parameters, body: assignments)
        )
    }

    /// Returns a value initializer for multipart payload structs with primitive types.
    /// - Parameters:
    ///   - typeName: The type name of the structure.
    ///   - properties: The properties of the structure.
    ///   - originalSchema: The original schema before any transformations.
    /// - Returns: A value initializer declaration if applicable, nil otherwise.
    func translateMultipartValueInitializer(
        typeName: TypeName,
        properties: [PropertyBlueprint],
        originalSchema: JSONSchema
    ) -> Declaration? {
        let typeMatcher = TypeMatcher(context: context)
        guard let matchedType = typeMatcher.tryMatchBuiltinType(for: originalSchema.value) else {
            return nil
        }

        let valueTypeName = matchedType.typeName
        let needsStringConversion: Bool

        switch originalSchema.value {
        case .integer, .boolean, .number:
            // For these types, if tryMatchBuiltinType succeeded, it means they are
            // simple primitive types (e.g., Int, Bool, Double) and not enums.
            // They will be converted to String for the HTTPBody.
            needsStringConversion = true
        case .string:
            // For string schemas, we must ensure it's a plain Swift.String.
            // Other string-based formats (Date, binary Data, base64 Data)
            // are not handled by this specific "value" initializer.
            guard valueTypeName == .string else { return nil }
            needsStringConversion = false
        case .object, .array, .all, .one, .any, .not, .reference, .fragment, .null:
            // Other schema types are not supported for this value initializer,
            // even if they might be considered "built-in" by the TypeMatcher
            // for other purposes.
            return nil
        }

        // Find headers and body properties
        let headersProperty = properties.first { $0.originalName == Constants.Operation.Output.Payload.Headers.variableName }
        let bodyProperty = properties.first { $0.originalName == Constants.Operation.Body.variableName }

        // This initializer requires a body part to set the value.
        guard bodyProperty != nil else { return nil }

        var parameters: [ParameterDescription] = []

        // Add headers parameter if a headers property exists
        if let headersProperty {
            parameters.append(ParameterDescription(
                label: headersProperty.swiftSafeName,
                type: .init(headersProperty.typeUsage),
                defaultValue: nil
            ))
        }

        // Add the main value parameter
        parameters.append(ParameterDescription(
            label: "value",
            type: .init(valueTypeName.asUsage),
            defaultValue: nil
        ))

        let bodyContentExpression: Expression
        if needsStringConversion {
            bodyContentExpression = .functionCall(
                calledExpression: .identifierType(TypeName.string),
                arguments: [.init(label: nil, expression: .identifierPattern("value"))]
            )
        } else {
            bodyContentExpression = .identifierPattern("value")
        }

        var bodyStatements: [CodeBlock] = []

        // Assign headers if provided
        if let headersProperty {
            bodyStatements.append(.expression(
                .assignment(
                    left: .identifierPattern("self").dot(headersProperty.swiftSafeName),
                    right: .identifierPattern(headersProperty.swiftSafeName)
                )
            ))
        }

        // Initialize the body property using the value
        bodyStatements.append(.expression(
            .assignment(
                left: .identifierPattern("self").dot(Constants.Operation.Body.variableName),
                right: .functionCall(
                    calledExpression: .identifierType(TypeName.runtime("HTTPBody")),
                    arguments: [.init(label: nil, expression: bodyContentExpression)]
                )
            )
        ))

        return .function(
            accessModifier: config.access,
            kind: .initializer(failable: false),
            parameters: parameters,
            body: bodyStatements
        )
    }

    /// Returns a list of declarations for a specified property blueprint.
    ///
    /// May return multiple declarations when the property contains an unnamed
    /// JSON schema, in which case a type declaration of that type is included
    /// in the returned array.
    /// - Parameter property: Information about the property.
    /// - Returns: A list of Swift declarations representing the translated property.
    func translatePropertyBlueprint(_ property: PropertyBlueprint) -> [Declaration] {
        let propertyDecl: Declaration = .commentable(
            property.comment,
            .variable(
                accessModifier: config.access,
                kind: .var,
                left: property.swiftSafeName,
                type: .init(property.typeUsage)
            )
            .deprecate(if: property.isDeprecated)
        )
        return property.associatedDeclarations + [propertyDecl]
    }

    /// Returns a declaration of a coding keys enum.
    /// - Parameter properties: The properties of the structure.
    /// - Returns: A coding keys enum declaration.
    func translateStructBlueprintCodingKeys(properties: [PropertyBlueprint]) -> Declaration {
        let members: [Declaration] = properties.map { property in
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
    /// - Parameter typeName: The name of the structure type.
    /// - Returns: A comment string describing the initializer.
    func initializerComment(typeName: String) -> Comment {
        Comment.functionComment(
            abstract: "Creates a new `\(typeName)`.",
            parameters: map { ($0.swiftSafeName, $0.comment?.firstLineOfContent) }
        )!  // This force-unwrap is safe as the method never returns nil when
        // a non-nil abstract is provided.
    }
}
