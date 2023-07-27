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

extension TypesFileTranslator {

    /// Returns the specified parameter extracted into a property blueprint.
    ///
    /// - Parameters:
    ///   - unresolvedParameter: An unresolved parameter.
    ///   - parent: The parent type name.
    /// - Returns: A property blueprint; nil when the parameter is unsupported.
    func parseParameterAsProperty(
        for unresolvedParameter: UnresolvedParameter,
        inParent parent: TypeName
    ) throws -> PropertyBlueprint? {
        guard
            let parameter = try parseAsTypedParameter(
                from: unresolvedParameter,
                inParent: parent
            )
        else {
            return nil
        }
        let associatedDeclarations: [Declaration]
        if let inlineableSchema = parameter.inlineableSchema {
            associatedDeclarations = try translateSchema(
                typeName: parameter.typeUsage.typeName,
                schema: inlineableSchema,
                overrides: .none
            )
        } else {
            associatedDeclarations = []
        }
        return .init(
            isDeprecated: parameter.parameter.deprecated,
            originalName: parameter.name,
            typeUsage: parameter.typeUsage,
            associatedDeclarations: associatedDeclarations,
            asSwiftSafeName: swiftSafeName
        )
    }

    /// Returns a list of declarations that define a Swift type for the parameter, where the parameter
    /// name is based on the component key.
    /// - Parameters:
    ///   - componentKey: The component key for the parameter.
    ///   - parameter: The typed parameter.
    /// - Returns: A list of declarations; empty list if the parameter is unsupported.
    func translateParameterInTypes(
        componentKey: OpenAPI.ComponentKey,
        parameter: TypedParameter
    ) throws -> [Declaration] {
        let typeName = typeAssigner.typeName(for: componentKey, of: OpenAPI.Parameter.self)
        return try translateParameterInTypes(
            typeName: typeName,
            parameter: parameter
        )
    }

    /// Returns a list of declarations that define a Swift type for the parameter and type name.
    /// - Parameters:
    ///   - typeName: The type name to declare the parameter type under.
    ///   - parameter: The parameter to declare.
    /// - Returns: A list of declarations; empty list if the parameter is unsupported.
    func translateParameterInTypes(
        typeName: TypeName,
        parameter: TypedParameter
    ) throws -> [Declaration] {
        let decl = try translateSchema(
            typeName: typeName,
            schema: parameter.schema,
            overrides: .init(
                isOptional: !parameter.required,
                userDescription: parameter.parameter.description
            )
        )
        return decl
    }
}

extension ClientFileTranslator {

    /// Returns a templated string that includes all path parameters in
    /// the specified operation, and an expression of an array literal
    /// with all those parameters.
    /// - Parameter description: The OpenAPI operation.
    func translatePathParameterInClient(
        description: OperationDescription
    ) throws -> (String, Expression) {
        try description.templatedPathForClient
    }

    /// Returns an expression that extracts the specified query, header, or
    /// cookie parameter value from a property on an Input value to a request.
    /// - Parameters:
    ///   - parameter: The parameter to extract.
    ///   - requestVariableName: The name of the request variable.
    ///   - inputVariableName: The name of the Input variable.
    /// - Returns: The expression; nil if the parameter is unsupported.
    func translateNonPathParameterInClient(
        _ parameter: TypedParameter,
        requestVariableName: String,
        inputVariableName: String
    ) throws -> Expression? {
        let methodPrefix: String
        let containerExpr: Expression
        switch parameter.location {
        case .header:
            methodPrefix = "HeaderField"
            containerExpr = .identifier(requestVariableName).dot("headerFields")
        case .query:
            methodPrefix = "QueryItem"
            containerExpr = .identifier(requestVariableName)
        default:
            diagnostics.emitUnsupported(
                "Parameter of type \(parameter.location.rawValue)",
                foundIn: parameter.description
            )
            return nil
        }
        return .try(
            .identifier("converter")
                .dot("set\(methodPrefix)As\(parameter.codingStrategy.runtimeName)")
                .call(
                    [
                        .init(
                            label: "in",
                            expression: .inOut(containerExpr)
                        ),
                        .init(label: "name", expression: .literal(parameter.name)),
                        .init(
                            label: "value",
                            expression: .identifier(inputVariableName)
                                .dot(parameter.location.shortVariableName)
                                .dot(parameter.variableName)
                        ),
                    ]
                )
        )
    }
}

extension ServerFileTranslator {

    /// Returns an expression that populates a function argument call with the
    /// result of extracting the parameter value from a request into an Input.
    /// - Parameter typedParameter: The parameter to extract from a request.
    func translateParameterInServer(
        _ typedParameter: TypedParameter
    ) throws -> FunctionArgumentDescription? {
        let parameter = typedParameter.parameter
        let parameterTypeName = typedParameter
            .typeUsage
            .fullyQualifiedNonOptionalSwiftName

        func methodName(_ parameterLocationName: String, _ requiresOptionality: Bool = true) -> String {
            let optionality: String
            if requiresOptionality {
                optionality = parameter.required ? "Required" : "Optional"
            } else {
                optionality = ""
            }
            return "get\(optionality)\(parameterLocationName)As\(typedParameter.codingStrategy.runtimeName)"
        }

        let convertExpr: Expression
        switch parameter.location {
        case .path:
            convertExpr = .try(
                .identifier("converter").dot(methodName("PathParameter", false))
                    .call([
                        .init(label: "in", expression: .identifier("metadata").dot("pathParameters")),
                        .init(label: "name", expression: .literal(parameter.name)),
                        .init(
                            label: "as",
                            expression: .identifier(parameterTypeName).dot("self")
                        ),
                    ])
            )
        case .query:
            convertExpr = .try(
                .identifier("converter").dot(methodName("QueryItem"))
                    .call([
                        .init(label: "in", expression: .identifier("metadata").dot("queryParameters")),
                        .init(label: "name", expression: .literal(parameter.name)),
                        .init(
                            label: "as",
                            expression: .identifier(parameterTypeName).dot("self")
                        ),
                    ])
            )
        case .header:
            convertExpr = .try(
                .identifier("converter")
                    .dot(methodName("HeaderField"))
                    .call([
                        .init(label: "in", expression: .identifier("request").dot("headerFields")),
                        .init(label: "name", expression: .literal(parameter.name)),
                        .init(
                            label: "as",
                            expression: .identifier(parameterTypeName).dot("self")
                        ),
                    ])
            )
        default:
            diagnostics.emitUnsupported(
                "Parameter of type \(parameter.location)",
                foundIn: "\(typedParameter.description)"
            )
            return nil
        }

        return FunctionArgumentDescription(
            label: typedParameter.variableName,
            expression: convertExpr
        )
    }
}
