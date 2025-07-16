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
    /// - Parameter content: The typed schema content to declare.
    /// - Returns: A list of declarations; empty list if the content is
    /// unsupported.
    /// - Throws: An error if there is an issue translating and declaring the schema content.
    func translateRequestBodyContentInTypes(_ content: TypedSchemaContent) throws -> [Declaration] {
        if content.content.contentType.isMultipart { return try translateMultipartBody(content) }
        let decls = try translateSchema(
            typeName: content.resolvedTypeUsage.typeName,
            schema: content.content.schema,
            overrides: .none
        )
        return decls
    }

    /// Returns a list of declarations for the specified request body wrapped
    /// in an Input type's nested Body type.
    ///
    /// The last declaration is an enum case, any prepended declarations
    /// represent unnamed types declared inline as Swift types.
    /// - Parameter requestBody: The request body to declare.
    /// - Returns: A list of declarations; empty if the request body is
    /// unsupported.
    /// - Throws: An error if there is an issue translating and declaring the request body content cases.
    func requestBodyContentCases(for requestBody: TypedRequestBody) throws -> [Declaration] {
        var bodyMembers: [Declaration] = []
        let typeName = requestBody.typeUsage.typeName
        let contentTypeName = typeName.appending(jsonComponent: "content")
        let contents = requestBody.contents
        for content in contents {
            if typeMatcher.isInlinable(content.content.schema) || typeMatcher.isReferenceableMultipart(content.content)
            {
                let inlineTypeDecls = try translateRequestBodyContentInTypes(content)
                bodyMembers.append(contentsOf: inlineTypeDecls)
            }
            let contentType = content.content.contentType
            let identifier = context.safeNameGenerator.swiftContentTypeName(for: contentType)
            let associatedType = content.resolvedTypeUsage.withOptional(false)
            let contentCase: Declaration = .commentable(
                contentType.docComment(typeName: contentTypeName),
                .enumCase(name: identifier, kind: .nameWithAssociatedValues([.init(type: .init(associatedType))]))
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
    /// - Throws: An error if there's an issue while parsing the request body or generating the property blueprint.
    /// - Returns: The property blueprint; nil if no body is specified.
    func parseRequestBodyAsProperty(for unresolvedRequestBody: UnresolvedRequest?, inParent parent: TypeName) throws
        -> PropertyBlueprint?
    {
        guard let _requestBody = unresolvedRequestBody,
            let requestBody = try typedRequestBody(from: _requestBody, inParent: parent)
        else { return nil }

        let isRequestBodyOptional = !requestBody.request.required
        let bodyEnumTypeName = requestBody.typeUsage.typeName
        let extraDecls: [Declaration]
        if requestBody.isInlined {
            extraDecls = [try translateRequestBodyInTypes(requestBody: requestBody)]
        } else {
            extraDecls = []
        }

        let bodyEnumTypeUsage = bodyEnumTypeName.asUsage.withOptional(isRequestBodyOptional)
        let bodyProperty = PropertyBlueprint(
            comment: nil,
            originalName: "body",
            typeUsage: bodyEnumTypeUsage,
            default: nil,
            associatedDeclarations: extraDecls,
            context: context
        )
        return bodyProperty
    }

    /// Returns a declaration that defines a Swift type for the request body.
    /// - Parameter requestBody: The request body to declare.
    /// - Returns: A list of declarations; empty list if the request body is
    /// unsupported.
    /// - Throws: An error if there is an issue translating the request body.
    func translateRequestBodyInTypes(requestBody: TypedRequestBody) throws -> Declaration {
        let type = requestBody.typeUsage.typeName
        let members = try requestBodyContentCases(for: requestBody)
        return translateRequestBodyInTypes(typeName: type, members: members)
    }

    /// Returns a declaration that defines a Swift type for the request body.
    /// - Parameters:
    ///   - typeName: The request body enum type name.
    ///   - members: The request body enum members to include.
    /// - Returns: A declaration of the enum.
    func translateRequestBodyInTypes(typeName: TypeName, members: [Declaration]) -> Declaration {
        let bodyEnumDecl: Declaration = .enum(
            isFrozen: true,
            accessModifier: config.access,
            name: typeName.shortSwiftName,
            conformances: Constants.Operation.Output.conformances,
            members: members
        )
        let comment: Comment? = typeName.docCommentWithUserDescription(nil)
        return .commentable(comment, bodyEnumDecl)
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
    /// - Throws: An error if there is an issue translating the request body.
    func translateRequestBodyInClient(
        _ requestBody: TypedRequestBody,
        requestVariableName: String,
        bodyVariableName: String,
        inputVariableName: String
    ) throws -> Expression {
        let contents = requestBody.contents
        var cases: [SwitchCaseDescription] = try contents.map { typedContent in
            let content = typedContent.content
            let contentType = content.contentType
            let contentTypeIdentifier = context.safeNameGenerator.swiftContentTypeName(for: contentType)
            let contentTypeHeaderValue = contentType.headerValueForSending

            let extraBodyAssignArgs: [FunctionArgumentDescription]
            if contentType.isMultipart {
                extraBodyAssignArgs = try translateMultipartSerializerExtraArgumentsInClient(typedContent)
            } else {
                extraBodyAssignArgs = []
            }
            let bodyAssignExpr: Expression = .assignment(
                left: .identifierPattern(bodyVariableName),
                right: .try(
                    .identifierPattern("converter")
                        .dot(
                            "set\(requestBody.request.required ? "Required" : "Optional")RequestBodyAs\(contentType.codingStrategy.runtimeName)"
                        )
                        .call(
                            [
                                .init(label: nil, expression: .identifierPattern("value")),
                                .init(
                                    label: "headerFields",
                                    expression: .inOut(.identifierPattern(requestVariableName).dot("headerFields"))
                                ), .init(label: "contentType", expression: .literal(contentTypeHeaderValue)),
                            ] + extraBodyAssignArgs
                        )
                )
            )
            let caseDesc = SwitchCaseDescription(
                kind: .case(.dot(contentTypeIdentifier), ["value"]),
                body: [.expression(bodyAssignExpr)]
            )
            return caseDesc
        }
        if !requestBody.request.required {
            let noneCase = SwitchCaseDescription(
                kind: .case(.dot("none")),
                body: [.expression(.assignment(left: .identifierPattern(bodyVariableName), right: .literal(.nil)))]
            )
            cases.insert(noneCase, at: 0)
        }
        return .switch(switchedExpression: .identifierPattern(inputVariableName).dot("body"), cases: cases)
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
    /// - Throws: An error if there is an issue extracting or validating the request body.
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
            right: .identifierPattern("converter").dot("extractContentTypeIfPresent")
                .call([.init(label: "in", expression: .identifierPattern(requestVariableName).dot("headerFields"))])
        )
        codeBlocks.append(.declaration(contentTypeDecl))
        codeBlocks.append(
            .declaration(.variable(kind: .let, left: bodyVariableName, type: .init(requestBody.typeUsage)))
        )

        let typedContents = requestBody.contents
        let contentTypeOptions = typedContents.map { typedContent in
            typedContent.content.contentType.headerValueForValidation
        }
        let chosenContentTypeDecl: Declaration = .variable(
            kind: .let,
            left: "chosenContentType",
            right: .try(
                .identifierPattern("converter").dot("bestContentType")
                    .call([
                        .init(label: "received", expression: .identifierPattern("contentType")),
                        .init(label: "options", expression: .literal(.array(contentTypeOptions.map { .literal($0) }))),
                    ])
            )
        )
        codeBlocks.append(.declaration(chosenContentTypeDecl))

        func makeCase(typedContent: TypedSchemaContent) throws -> SwitchCaseDescription {
            let contentTypeUsage = typedContent.resolvedTypeUsage
            let content = typedContent.content
            let contentType = content.contentType
            let codingStrategy = contentType.codingStrategy
            let codingStrategyName = codingStrategy.runtimeName
            let transformExpr: Expression = .closureInvocation(
                argumentNames: ["value"],
                body: [
                    .expression(
                        .dot(context.safeNameGenerator.swiftContentTypeName(for: typedContent.content.contentType))
                            .call([.init(label: nil, expression: .identifierPattern("value"))])
                    )
                ]
            )
            let extraBodyAssignArgs: [FunctionArgumentDescription]
            if contentType.isMultipart {
                extraBodyAssignArgs = try translateMultipartDeserializerExtraArgumentsInServer(typedContent)
            } else {
                extraBodyAssignArgs = []
            }
            let converterExpr: Expression = .identifierPattern("converter")
                .dot("get\(isOptional ? "Optional" : "Required")RequestBodyAs\(codingStrategyName)")
                .call(
                    [
                        .init(
                            label: nil,
                            expression: .identifierType(contentTypeUsage.withOptional(false)).dot("self")
                        ), .init(label: "from", expression: .identifierPattern("requestBody")),
                        .init(label: "transforming", expression: transformExpr),
                    ] + extraBodyAssignArgs
                )
            let bodyExpr: Expression
            switch codingStrategy {
            case .json, .uri, .urlEncodedForm:
                // Buffering.
                bodyExpr = .try(.await(converterExpr))
            case .binary, .multipart:
                // Streaming.
                bodyExpr = .try(converterExpr)
            }
            let bodyAssignExpr: Expression = .assignment(left: .identifierPattern("body"), right: bodyExpr)
            return .init(
                kind: .case(.literal(typedContent.content.contentType.headerValueForValidation)),
                body: [.expression(bodyAssignExpr)]
            )
        }

        let cases = try typedContents.map(makeCase)
        let switchExpr: Expression = .switch(
            switchedExpression: .identifierPattern("chosenContentType"),
            cases: cases + [
                .init(
                    kind: .default,
                    body: [
                        .expression(
                            .identifierPattern("preconditionFailure")
                                .call([
                                    .init(
                                        label: nil,
                                        expression: .literal("bestContentType chose an invalid content type.")
                                    )
                                ])
                        )
                    ]
                )
            ]
        )
        codeBlocks.append(.expression(switchExpr))
        return codeBlocks
    }
}
