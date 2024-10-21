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

    /// Returns an expression representing the call to converter to set the provided header into
    /// a header fields container.
    /// - Parameter header: The header to set.
    /// - Returns: An expression.
    func translateMultipartOutgoingHeader(_ header: TypedResponseHeader) -> Expression {
        .try(
            .identifierPattern("converter").dot("setHeaderFieldAs\(header.codingStrategy.runtimeName)")
                .call([
                    .init(label: "in", expression: .inOut(.identifierPattern("headerFields"))),
                    .init(label: "name", expression: .literal(header.name)),
                    .init(
                        label: "value",
                        expression: .identifierPattern("value").dot("headers").dot(header.variableName)
                    ),
                ])
        )
    }

    /// Returns an expression representing the call to converter to get the provided header from
    /// a header fields container.
    /// - Parameter header: The header to get.
    /// - Returns: A function argument description.
    func translateMultipartIncomingHeader(_ header: TypedResponseHeader) -> FunctionArgumentDescription {
        let methodName =
            "get\(header.isOptional ? "Optional" : "Required")HeaderFieldAs\(header.codingStrategy.runtimeName)"
        let convertExpr: Expression = .try(
            .identifierPattern("converter").dot(methodName)
                .call([
                    .init(label: "in", expression: .identifierPattern("headerFields")),
                    .init(label: "name", expression: .literal(header.name)),
                    .init(label: "as", expression: .identifierType(header.typeUsage.withOptional(false)).dot("self")),
                ])
        )
        return .init(label: header.variableName, expression: convertExpr)
    }
}

extension TypesFileTranslator {

    /// Returns the specified response header extracted into a property
    /// blueprint.
    ///
    /// - Parameters:
    ///   - header: A response parameter.
    ///   - parent: The type name of the parent struct.
    /// - Returns: A property blueprint.
    /// - Throws: An error if there's an issue while parsing the response header.
    func parseResponseHeaderAsProperty(for header: TypedResponseHeader, parent: TypeName) throws -> PropertyBlueprint {
        let schema = header.schema
        let typeUsage = header.typeUsage
        let associatedDeclarations: [Declaration]
        if typeMatcher.isInlinable(schema) {
            associatedDeclarations = try translateSchema(typeName: typeUsage.typeName, schema: schema, overrides: .none)
        } else {
            associatedDeclarations = []
        }
        let comment = parent.docCommentWithUserDescription(header.header.description, subPath: header.name)
        return .init(
            comment: comment,
            originalName: header.name,
            typeUsage: typeUsage,
            default: header.header.required ? nil : .nil,
            associatedDeclarations: associatedDeclarations,
            context: context
        )
    }

    /// Returns a list of declarations for the specified reusable response
    /// header defined under the specified key in the OpenAPI document.
    /// - Parameters:
    ///   - componentKey: The component key used for the reusable response
    ///   header in the OpenAPI document.
    ///   - header: The response header to declare.
    /// - Returns: A list of declarations. If more than one declaration is
    /// returned, the last one is the header type declaration, while any
    /// previous ones represent unnamed types in the OpenAPI document that
    /// need to be defined inline.
    /// - Throws: An error if there's an issue while translating the response header or its inline types.
    func translateResponseHeaderInTypes(componentKey: OpenAPI.ComponentKey, header: TypedResponseHeader) throws
        -> [Declaration]
    {
        let typeName = typeAssigner.typeName(for: componentKey, of: OpenAPI.Header.self)
        return try translateResponseHeaderInTypes(typeName: typeName, header: header)
    }

    /// Returns a list of declarations for the specified reusable response
    /// header defined under the specified key in the OpenAPI document.
    /// - Parameters:
    ///   - typeName: The computed Swift type name for the header.
    ///   - header: The response header to declare.
    /// - Returns: A list of declarations. If more than one declaration is
    /// returned, the last one is the header type declaration, while any
    /// previous ones represent unnamed types in the OpenAPI document that
    /// need to be defined inline.
    /// - Throws: An error if there's an issue while translating the response header or its inline types.
    func translateResponseHeaderInTypes(typeName: TypeName, header: TypedResponseHeader) throws -> [Declaration] {
        let decl = try translateSchema(
            typeName: typeName,
            schema: header.schema,
            overrides: .init(userDescription: header.header.description)
        )
        return decl
    }
}

extension ClientFileTranslator {

    /// Returns an expression that extracts the value of the specified response
    /// header from a property on an Input value to a request.
    /// - Parameters:
    ///   - header: The response header to extract.
    ///   - responseVariableName: The name of the response variable.
    /// - Returns: A function argument expression.
    /// - Throws: An error if there's an issue while generating the extraction expression.
    func translateResponseHeaderInClient(_ header: TypedResponseHeader, responseVariableName: String) throws
        -> FunctionArgumentDescription
    {
        .init(
            label: header.variableName,
            expression: .try(
                .identifierPattern("converter")
                    .dot(
                        "get\(header.isOptional ? "Optional" : "Required")HeaderFieldAs\(header.codingStrategy.runtimeName)"
                    )
                    .call([
                        .init(label: "in", expression: .identifierPattern(responseVariableName).dot("headerFields")),
                        .init(label: "name", expression: .literal(header.name)),
                        .init(
                            label: "as",
                            expression: .identifierType(header.typeUsage.withOptional(false)).dot("self")
                        ),
                    ])
            )
        )
    }
}

extension ServerFileTranslator {

    /// Returns an expression that populates a function argument call with
    /// the result of extracting the header value from a response into
    /// an Output.
    /// - Parameters:
    ///   - header: The header to extract.
    ///   - responseVariableName: The name of the response variable.
    /// - Returns: A function argument expression.
    /// - Throws: An error if there's an issue while generating the expression for setting the header field.
    func translateResponseHeaderInServer(_ header: TypedResponseHeader, responseVariableName: String) throws
        -> Expression
    {
        .try(
            .identifierPattern("converter").dot("setHeaderFieldAs\(header.codingStrategy.runtimeName)")
                .call([
                    .init(
                        label: "in",
                        expression: .inOut(.identifierPattern(responseVariableName).dot("headerFields"))
                    ), .init(label: "name", expression: .literal(header.name)),
                    .init(
                        label: "value",
                        expression: .identifierPattern("value").dot("headers").dot(header.variableName)
                    ),
                ])
        )
    }
}
