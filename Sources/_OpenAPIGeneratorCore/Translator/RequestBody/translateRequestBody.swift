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

    /// Returns a list of declarations that define a Swift type for
    /// the request body content and type name.
    /// - Parameters:
    ///   - typeName: The type name to declare the request body type under.
    ///   - requestBody: The request body to declare.
    /// - Returns: A list of declarations; empty list if the request body is
    /// unsupported.
    func translateRequestBodyContentInTypes(
        requestBody: TypedRequestBody
    ) throws -> [Declaration] {
        let content = requestBody.content
        let decl = try translateSchema(
            typeName: content.resolvedTypeUsage.typeName,
            schema: content.content.schema,
            overrides: .init(
                isOptional: !requestBody.request.required,
                userDescription: requestBody.request.description
            )
        )
        return decl
    }

    /// Returns a list of declarations for the specified request body wrapped
    /// in an Input type's nested Body type.
    ///
    /// The last declaration is an enum case, any prepended declarations
    /// represent unnamed types declared inline as Swift types.
    /// - Parameter requestBody: The request body to declare.
    /// - Returns: A list of declarations; empty if the request body is
    /// unsupported.
    func requestBodyContentCase(
        for requestBody: TypedRequestBody
    ) throws -> [Declaration] {
        var bodyMembers: [Declaration] = []
        let content = requestBody.content
        if TypeMatcher.isInlinable(content.content.schema) {
            let inlineTypeDecls = try translateRequestBodyContentInTypes(
                requestBody: requestBody
            )
            bodyMembers.append(contentsOf: inlineTypeDecls)
        }
        let identifier = contentSwiftName(content.content.contentType)
        let associatedType = content.resolvedTypeUsage
        let contentCase: Declaration = .enumCase(
            .init(
                name: identifier,
                kind: .nameWithAssociatedValues([
                    .init(type: associatedType.fullyQualifiedNonOptionalSwiftName)
                ])
            )
        )
        bodyMembers.append(contentCase)
        return bodyMembers
    }

    /// Returns a property blueprint for the specified request body in
    /// the specified parent Swift structure.
    /// - Parameters:
    ///   - unresolvedRequestBody: An unresolved request body.
    ///   - parent: The type name of the parent structure.
    func parseRequestBodyAsProperty(
        for unresolvedRequestBody: UnresolvedRequest?,
        inParent parent: TypeName
    ) throws -> PropertyBlueprint {
        let bodyEnumTypeName: TypeName
        let isRequestBodyOptional: Bool
        let extraDecls: [Declaration]
        if let _requestBody = unresolvedRequestBody,
            let requestBody = try typedRequestBody(
                from: _requestBody,
                inParent: parent
            )
        {
            isRequestBodyOptional = !requestBody.request.required
            bodyEnumTypeName = requestBody.typeUsage.typeName
            if requestBody.isInlined {
                extraDecls = [
                    try translateRequestBodyInTypes(
                        requestBody: requestBody
                    )
                ]
            } else {
                extraDecls = []
            }
        } else {
            isRequestBodyOptional = true
            bodyEnumTypeName = parent.appending(
                swiftComponent: Constants.Operation.Body.typeName
            )
            extraDecls = [
                translateRequestBodyInTypes(
                    typeName: bodyEnumTypeName,
                    members: []
                )
            ]
        }

        let bodyEnumTypeUsage = bodyEnumTypeName.asUsage
            .withOptional(isRequestBodyOptional)
        let bodyProperty = PropertyBlueprint(
            comment: nil,
            originalName: "body",
            typeUsage: bodyEnumTypeUsage,
            default: nil,
            associatedDeclarations: extraDecls,
            asSwiftSafeName: swiftSafeName
        )
        return bodyProperty
    }

    /// Returns a declaration that defines a Swift type for the request body.
    /// - Parameters:
    ///   - requestBody: The request body to declare.
    /// - Returns: A list of declarations; empty list if the request body is
    /// unsupported.
    func translateRequestBodyInTypes(
        requestBody: TypedRequestBody
    ) throws -> Declaration {
        let type = requestBody.typeUsage.typeName
        let members = try requestBodyContentCase(for: requestBody)
        return translateRequestBodyInTypes(
            typeName: type,
            members: members
        )
    }

    /// Returns a declaration that defines a Swift type for the request body.
    /// - Parameters:
    ///   - typeName: The request body enum type name.
    ///   - members: The request body enum members to include.
    /// - Returns: A declaration of the enum.
    func translateRequestBodyInTypes(
        typeName: TypeName,
        members: [Declaration]
    ) -> Declaration {
        let bodyEnumDecl: Declaration = .enum(
            isFrozen: true,
            accessModifier: config.access,
            name: typeName.shortSwiftName,
            conformances: Constants.Operation.Output.conformances,
            members: members
        )
        return bodyEnumDecl
    }
}

extension ClientFileTranslator {

    /// Returns an expression that extracts the specified request body from
    /// a property on an Input value to a request.
    /// - Parameters:
    ///   - requestBody: The request body to extract.
    ///   - requestVariableName: The name of the request variable.
    ///   - inputVariableName: The name of the Input variable.
    /// - Returns: An assignment expression.
    func translateRequestBodyInClient(
        _ requestBody: TypedRequestBody,
        requestVariableName: String,
        inputVariableName: String
    ) throws -> Expression {
        let contents = [requestBody.content]
        var cases: [SwitchCaseDescription] = contents.map { typedContent in
            let content = typedContent.content
            let contentType = content.contentType
            let contentTypeIdentifier = contentSwiftName(contentType)
            let contentTypeHeaderValue = contentType.headerValueForSending

            let bodyAssignExpr: Expression = .assignment(
                left: .identifier(requestVariableName).dot("body"),
                right: .try(
                    .identifier("converter")
                        .dot(
                            "set\(requestBody.request.required ? "Required" : "Optional")RequestBodyAs\(contentType.codingStrategy.runtimeName)"
                        )
                        .call([
                            .init(label: nil, expression: .identifier("value")),
                            .init(
                                label: "headerFields",
                                expression: .inOut(
                                    .identifier(requestVariableName).dot("headerFields")
                                )
                            ),
                            .init(
                                label: "contentType",
                                expression: .literal(contentTypeHeaderValue)
                            ),
                        ])
                )
            )
            let caseDesc: SwitchCaseDescription = .init(
                kind: .case(.dot(contentTypeIdentifier), ["value"]),
                body: [
                    .expression(bodyAssignExpr)
                ]
            )
            return caseDesc
        }
        if !requestBody.request.required {
            let noneCase: SwitchCaseDescription = .init(
                kind: .case(.dot("none")),
                body: [
                    .expression(
                        .assignment(
                            left: .identifier(requestVariableName).dot("body"),
                            right: .literal(.nil)
                        )
                    )
                ]
            )
            cases.insert(noneCase, at: 0)
        }
        return .switch(
            switchedExpression: .identifier(inputVariableName).dot("body"),
            cases: cases
        )
    }
}

extension ServerFileTranslator {

    /// Returns a declaration of a local variable of the specified name and type
    /// assigned to the specified request body extracted from a request.
    /// - Parameters:
    ///   - requestBody: The request body to extract.
    ///   - requestVariableName: The name of the request variable.
    ///   - bodyVariableName: The name of the body variable.
    ///   - inputTypeName: The type of the Input.
    /// - Returns: A variable declaration.
    func translateRequestBodyInServer(
        _ requestBody: TypedRequestBody?,
        requestVariableName: String,
        bodyVariableName: String,
        inputTypeName: TypeName
    ) throws -> Declaration {
        guard let requestBody else {
            let bodyTypeUsage =
                inputTypeName.appending(
                    swiftComponent: Constants.Operation.Body.typeName
                )
                .asUsage
            return .variable(
                kind: .let,
                left: bodyVariableName,
                type: bodyTypeUsage.asOptional.fullyQualifiedSwiftName,
                right: .literal(.nil)
            )
        }

        let bodyTypeUsage = requestBody.typeUsage
        let typedContent = requestBody.content
        let contentTypeUsage = typedContent.resolvedTypeUsage
        let content = typedContent.content
        let contentType = content.contentType
        let contentTypeIdentifier = contentSwiftName(contentType)
        let codingStrategyName = contentType.codingStrategy.runtimeName
        let isOptional = !requestBody.request.required

        let transformExpr: Expression = .closureInvocation(
            argumentNames: ["value"],
            body: [
                .expression(
                    .dot(contentTypeIdentifier)
                        .call([
                            .init(label: nil, expression: .identifier("value"))
                        ])
                )
            ]
        )
        let initExpr: Expression = .try(
            .identifier("converter")
                .dot("get\(isOptional ? "Optional" : "Required")RequestBodyAs\(codingStrategyName)")
                .call([
                    .init(
                        label: nil,
                        expression:
                            .identifier(
                                contentTypeUsage
                                    .fullyQualifiedNonOptionalSwiftName
                            )
                            .dot("self")
                    ),
                    .init(
                        label: "from",
                        expression: .identifier(requestVariableName).dot("body")
                    ),
                    .init(label: "transforming", expression: transformExpr),
                ])
        )
        return .variable(
            kind: .let,
            left: bodyVariableName,
            type:
                bodyTypeUsage
                .withOptional(isOptional)
                .fullyQualifiedSwiftName,
            right: initExpr
        )
    }
}
