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

    /// Returns a list of declarations that define a Swift type for
    /// the request body content.
    /// - Parameters:
    ///   - content: The typed schema content to declare.
    /// - Returns: A list of declarations; empty list if the content is
    /// unsupported.
    func translateRequestBodyContentInTypes(
        _ content: TypedSchemaContent
    ) throws -> [Declaration] {
        let decl = try translateSchema(
            typeName: content.resolvedTypeUsage.typeName,
            schema: content.content.schema,
            overrides: .none
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
    func requestBodyContentCases(
        for requestBody: TypedRequestBody
    ) throws -> [Declaration] {
        var bodyMembers: [Declaration] = []
        let typeName = requestBody.typeUsage.typeName
        let contentTypeName = typeName.appending(jsonComponent: "content")
        let contents = requestBody.contents
        for content in contents {
            if TypeMatcher.isInlinable(content.content.schema) {
                let inlineTypeDecls = try translateRequestBodyContentInTypes(
                    content
                )
                bodyMembers.append(contentsOf: inlineTypeDecls)
            }
            let contentType = content.content.contentType
            let identifier = contentSwiftName(contentType)
            let associatedType = content.resolvedTypeUsage
            let contentCase: Declaration = .commentable(
                contentType.docComment(typeName: contentTypeName),
                .enumCase(
                    name: identifier,
                    kind: .nameWithAssociatedValues([
                        .init(type: associatedType.fullyQualifiedNonOptionalSwiftName)
                    ])
                )
            )
            bodyMembers.append(contentCase)
        }
        return bodyMembers
    }

    /// Returns a property blueprint for the specified request body in
    /// the specified parent Swift structure.
    /// - Parameters:
    ///   - unresolvedRequestBody: An unresolved request body.
    ///   - parent: The type name of the parent structure.
    /// - Returns: The property blueprint; nil if no body is specified.
    func parseRequestBodyAsProperty(
        for unresolvedRequestBody: UnresolvedRequest?,
        inParent parent: TypeName
    ) throws -> PropertyBlueprint? {
        guard let _requestBody = unresolvedRequestBody,
            let requestBody = try typedRequestBody(
                from: _requestBody,
                inParent: parent
            )
        else {
            return nil
        }

        let isRequestBodyOptional = !requestBody.request.required
        let bodyEnumTypeName = requestBody.typeUsage.typeName
        let extraDecls: [Declaration]
        if requestBody.isInlined {
            extraDecls = [
                try translateRequestBodyInTypes(
                    requestBody: requestBody
                )
            ]
        } else {
            extraDecls = []
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
        let members = try requestBodyContentCases(for: requestBody)
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
        let comment: Comment? = typeName.docCommentWithUserDescription(nil)
        return .commentable(
            comment,
            bodyEnumDecl
        )
    }
}

extension ClientFileTranslator {

    /// Returns an expression that extracts the specified request body from
    /// a property on an Input value and sets it on a request.
    /// - Parameters:
    ///   - requestBody: The request body to extract.
    ///   - requestVariableName: The name of the request variable.
    ///   - bodyVariableName: The name of the body variable.
    ///   - inputVariableName: The name of the Input variable.
    /// - Returns: An assignment expression.
    func translateRequestBodyInClient(
        _ requestBody: TypedRequestBody,
        requestVariableName: String,
        bodyVariableName: String,
        inputVariableName: String
    ) throws -> Expression {
        let contents = requestBody.contents
        var cases: [SwitchCaseDescription] = contents.map { typedContent in
            let content = typedContent.content
            let contentType = content.contentType
            let contentTypeIdentifier = contentSwiftName(contentType)
            let contentTypeHeaderValue = contentType.headerValueForSending

            let bodyAssignExpr: Expression = .assignment(
                left: .identifier(bodyVariableName),
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
            let caseDesc = SwitchCaseDescription(
                kind: .case(.dot(contentTypeIdentifier), ["value"]),
                body: [
                    .expression(bodyAssignExpr)
                ]
            )
            return caseDesc
        }
        if !requestBody.request.required {
            let noneCase = SwitchCaseDescription(
                kind: .case(.dot("none")),
                body: [
                    .expression(
                        .assignment(
                            left: .identifier(bodyVariableName),
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
        _ requestBody: TypedRequestBody,
        requestVariableName: String,
        bodyVariableName: String,
        inputTypeName: TypeName
    ) throws -> [CodeBlock] {
        var codeBlocks: [CodeBlock] = []

        let isOptional = !requestBody.request.required

        let contentTypeDecl: Declaration = .variable(
            kind: .let,
            left: "contentType",
            right: .identifier("converter")
                .dot("extractContentTypeIfPresent")
                .call([
                    .init(
                        label: "in",
                        expression: .identifier(requestVariableName)
                            .dot("headerFields")
                    )
                ])
        )
        codeBlocks.append(.declaration(contentTypeDecl))
        codeBlocks.append(
            .declaration(
                .variable(
                    kind: .let,
                    left: bodyVariableName,
                    type: requestBody.typeUsage.fullyQualifiedSwiftName
                )
            )
        )

        func makeIfBranch(typedContent: TypedSchemaContent, isFirstBranch: Bool) -> IfBranch {
            let isMatchingContentTypeExpr: Expression = .identifier("converter")
                .dot("isMatchingContentType")
                .call([
                    .init(
                        label: "received",
                        expression: .identifier("contentType")
                    ),
                    .init(
                        label: "expectedRaw",
                        expression: .literal(
                            typedContent
                                .content
                                .contentType
                                .headerValueForValidation
                        )
                    ),
                ])
            let condition: Expression
            if isFirstBranch {
                condition = .binaryOperation(
                    left: .binaryOperation(
                        left: .identifier("contentType"),
                        operation: .equals,
                        right: .literal(.nil)
                    ),
                    operation: .booleanOr,
                    right: isMatchingContentTypeExpr
                )
            } else {
                condition = isMatchingContentTypeExpr
            }
            let contentTypeUsage = typedContent.resolvedTypeUsage
            let content = typedContent.content
            let contentType = content.contentType
            let codingStrategy = contentType.codingStrategy
            let codingStrategyName = codingStrategy.runtimeName
            let transformExpr: Expression = .closureInvocation(
                argumentNames: ["value"],
                body: [
                    .expression(
                        .dot(contentSwiftName(typedContent.content.contentType))
                            .call([
                                .init(label: nil, expression: .identifier("value"))
                            ])
                    )
                ]
            )
            let converterExpr: Expression =
                .identifier("converter")
                .dot("get\(isOptional ? "Optional" : "Required")RequestBodyAs\(codingStrategyName)")
                .call([
                    .init(
                        label: nil,
                        expression:
                            .identifier(
                                contentTypeUsage.fullyQualifiedNonOptionalSwiftName
                            )
                            .dot("self")
                    ),
                    .init(label: "from", expression: .identifier("requestBody")),
                    .init(
                        label: "transforming",
                        expression: transformExpr
                    ),
                ])
            let bodyExpr: Expression
            if codingStrategy == .binary {
                bodyExpr = .try(converterExpr)
            } else {
                bodyExpr = .try(.await(converterExpr))
            }
            return .init(
                condition: .try(condition),
                body: [
                    .expression(
                        .assignment(
                            left: .identifier("body"),
                            right: bodyExpr
                        )
                    )
                ]
            )
        }

        let typedContents = requestBody.contents

        let primaryIfBranch = makeIfBranch(
            typedContent: typedContents[0],
            isFirstBranch: true
        )
        let elseIfBranches =
            typedContents
            .dropFirst()
            .map { typedContent in
                makeIfBranch(
                    typedContent: typedContent,
                    isFirstBranch: false
                )
            }

        codeBlocks.append(
            .expression(
                .ifStatement(
                    ifBranch: primaryIfBranch,
                    elseIfBranches: elseIfBranches,
                    elseBody: [
                        .expression(
                            .unaryKeyword(
                                kind: .throw,
                                expression: .identifier("converter")
                                    .dot("makeUnexpectedContentTypeError")
                                    .call([
                                        .init(
                                            label: "contentType",
                                            expression: .identifier("contentType")
                                        )
                                    ])
                            )
                        )
                    ]
                )
            )
        )
        return codeBlocks
    }
}
