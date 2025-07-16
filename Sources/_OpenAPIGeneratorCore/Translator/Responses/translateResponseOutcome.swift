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

    /// Returns the declarations of a response needed in Types.swift,
    /// represented by enum cases with associated values, where the associated
    /// value is of a type defined right above, one for each response.
    /// - Parameters:
    ///   - outcome: The OpenAPI response.
    ///   - operation: The OpenAPI operation.
    ///   - operationJSONPath: The JSON path to the operation in the OpenAPI
    ///   document.
    /// - Returns: A tuple containing a declaration of the enum case, a declaration of the
    /// structure unique to the response that contains the response headers
    /// and a body payload, a declaration of a throwing getter and, an optional convenience static property.
    /// - Throws: An error if there's an issue generating the declarations, such
    ///           as unsupported response types or invalid definitions.
    func translateResponseOutcomeInTypes(
        _ outcome: OpenAPI.Operation.ResponseOutcome,
        operation: OperationDescription,
        operationJSONPath: String
    ) throws -> (
        payloadStruct: Declaration?, enumCase: Declaration, staticMember: Declaration?, throwingGetter: Declaration
    ) {
        let typedResponse = try typedResponse(from: outcome, operation: operation)
        let responseStructTypeName = typedResponse.typeUsage.typeName
        let responseKind = outcome.status.value.asKind
        let enumCaseName = responseKind.identifier

        let responseStructDecl: Declaration?
        if typedResponse.isInlined {
            responseStructDecl = try translateResponseInTypes(
                typeName: typedResponse.typeUsage.typeName,
                response: typedResponse
            )
        } else {
            responseStructDecl = nil
        }

        var associatedValues: [EnumCaseAssociatedValueDescription] = []
        if responseKind.wantsStatusCode {
            associatedValues.append(.init(label: "statusCode", type: .init(TypeName.int)))
        }
        associatedValues.append(.init(type: .init(responseStructTypeName)))

        let enumCaseDocComment = responseKind.docComment(
            userDescription: typedResponse.response.description,
            jsonPath: operationJSONPath + "/responses/" + responseKind.jsonPathComponent
        )
        let enumCaseDesc = EnumCaseDescription(name: enumCaseName, kind: .nameWithAssociatedValues(associatedValues))
        let enumCaseDecl: Declaration = .commentable(enumCaseDocComment, .enumCase(enumCaseDesc))

        let staticMemberDecl: Declaration?
        let responseHasNoHeaders = typedResponse.response.headers?.isEmpty ?? true
        let responseHasNoContent = typedResponse.response.content.isEmpty
        if responseHasNoContent && responseHasNoHeaders && !responseKind.wantsStatusCode {
            let staticMemberDesc = VariableDescription(
                accessModifier: config.access,
                isStatic: true,
                kind: .var,
                left: .identifier(.pattern(enumCaseName)),
                type: .member(["Self"]),
                getter: [
                    .expression(
                        .functionCall(
                            calledExpression: .dot(enumCaseName),
                            arguments: [.functionCall(calledExpression: .dot("init"))]
                        )
                    )
                ]
            )
            staticMemberDecl = .commentable(enumCaseDocComment, .variable(staticMemberDesc))
        } else {
            staticMemberDecl = nil
        }

        let throwingGetterDesc = VariableDescription(
            accessModifier: config.access,
            kind: .var,
            left: .identifierPattern(enumCaseName),
            type: .init(responseStructTypeName),
            getter: [
                .expression(
                    .switch(
                        switchedExpression: .identifierPattern("self"),
                        cases: [
                            SwitchCaseDescription(
                                kind: .case(
                                    .dot(responseKind.identifier),
                                    responseKind.wantsStatusCode ? ["_", "response"] : ["response"]
                                ),
                                body: [.expression(.return(.identifierPattern("response")))]
                            ),
                            SwitchCaseDescription(
                                kind: .default,
                                body: [
                                    .expression(
                                        .try(
                                            .identifierPattern("throwUnexpectedResponseStatus")
                                                .call([
                                                    .init(
                                                        label: "expectedStatus",
                                                        expression: .literal(.string(responseKind.prettyName))
                                                    ), .init(label: "response", expression: .identifierPattern("self")),
                                                ])
                                        )
                                    )
                                ]
                            ),
                        ]
                    )
                )
            ],
            getterEffects: [.throws]
        )
        let throwingGetterComment = Comment.doc(
            """
            The associated value of the enum case if `self` is `.\(enumCaseName)`.

            - Throws: An error if `self` is not `.\(enumCaseName)`.
            - SeeAlso: `.\(enumCaseName)`.
            """
        )
        let throwingGetterDecl = Declaration.commentable(throwingGetterComment, .variable(throwingGetterDesc))

        return (responseStructDecl, enumCaseDecl, staticMemberDecl, throwingGetterDecl)
    }
}

extension ClientFileTranslator {

    /// Returns a switch case expression that matches the HTTP status code
    /// of the specified response.
    /// - Parameters:
    ///   - outcome: The OpenAPI response.
    ///   - operation: The OpenAPI operation.
    /// - Returns: A switch case expression.
    /// - Throws: An error if there's an issue generating the switch case
    ///           expression, such as encountering unsupported response types or
    ///           invalid definitions.
    func translateResponseOutcomeInClient(outcome: OpenAPI.Operation.ResponseOutcome, operation: OperationDescription)
        throws -> SwitchCaseDescription
    {

        let typedResponse = try typedResponse(from: outcome, operation: operation)
        let responseStructTypeName = typedResponse.typeUsage.typeName
        let responseKind = outcome.status.value.asKind

        let caseKind: SwitchCaseKind
        switch responseKind {
        case let .code(code): caseKind = .`case`(.literal(code))
        case let .range(range):
            caseKind = .`case`(
                .binaryOperation(
                    left: .literal(range.lowerBound),
                    operation: .rangeInclusive,
                    right: .literal(range.upperBound)
                )
            )
        case .`default`: caseKind = .`default`
        }

        var codeBlocks: [CodeBlock] = []

        let headersTypeName = responseStructTypeName.appending(
            swiftComponent: Constants.Operation.Output.Payload.Headers.typeName
        )
        let bodyTypeName = responseStructTypeName.appending(swiftComponent: Constants.Operation.Body.typeName)

        let headers = try typedResponseHeaders(from: typedResponse.response, inParent: headersTypeName)
        let headersVarExpr: Expression?
        if !headers.isEmpty {
            let headerInitArgs: [FunctionArgumentDescription] = try headers.map { header in
                try translateResponseHeaderInClient(header, responseVariableName: "response")
            }
            let headersInitExpr: Expression = .dot("init").call(headerInitArgs)
            let headersVarDecl: Declaration = .variable(
                kind: .let,
                left: "headers",
                type: .init(headersTypeName),
                right: headersInitExpr
            )
            codeBlocks.append(.declaration(headersVarDecl))
            headersVarExpr = .identifierPattern("headers")
        } else {
            headersVarExpr = nil
        }

        let typedContents = try supportedTypedContents(
            typedResponse.response.content,
            isRequired: true,
            inParent: bodyTypeName
        )
        let bodyVarExpr: Expression?
        if !typedContents.isEmpty {

            let contentTypeDecl: Declaration = .variable(
                kind: .let,
                left: "contentType",
                right: .identifierPattern("converter").dot("extractContentTypeIfPresent")
                    .call([.init(label: "in", expression: .identifierPattern("response").dot("headerFields"))])
            )
            codeBlocks.append(.declaration(contentTypeDecl))

            let bodyDecl: Declaration = .variable(kind: .let, left: "body", type: .init(bodyTypeName))
            codeBlocks.append(.declaration(bodyDecl))

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
                            .init(
                                label: "options",
                                expression: .literal(.array(contentTypeOptions.map { .literal($0) }))
                            ),
                        ])
                )
            )
            codeBlocks.append(.declaration(chosenContentTypeDecl))

            func makeCase(typedContent: TypedSchemaContent) throws -> SwitchCaseDescription {
                let contentTypeUsage = typedContent.resolvedTypeUsage
                let transformExpr: Expression = .closureInvocation(
                    argumentNames: ["value"],
                    body: [
                        .expression(
                            .dot(context.safeNameGenerator.swiftContentTypeName(for: typedContent.content.contentType))
                                .call([.init(label: nil, expression: .identifierPattern("value"))])
                        )
                    ]
                )
                let codingStrategy = typedContent.content.contentType.codingStrategy
                let extraBodyAssignArgs: [FunctionArgumentDescription]
                if typedContent.content.contentType.isMultipart {
                    extraBodyAssignArgs = try translateMultipartDeserializerExtraArgumentsInClient(typedContent)
                } else {
                    extraBodyAssignArgs = []
                }

                let converterExpr: Expression = .identifierPattern("converter")
                    .dot("getResponseBodyAs\(codingStrategy.runtimeName)")
                    .call(
                        [
                            .init(label: nil, expression: .identifierType(contentTypeUsage).dot("self")),
                            .init(label: "from", expression: .identifierPattern("responseBody")),
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
            bodyVarExpr = .identifierPattern("body")
        } else {
            bodyVarExpr = nil
        }

        let initExpr: Expression = .dot("init")
            .call(
                [
                    headersVarExpr.map { headersVarExpr in
                        .init(
                            label: Constants.Operation.Output.Payload.Headers.variableName,
                            expression: headersVarExpr
                        )
                    },
                    bodyVarExpr.map { bodyVarExpr in
                        .init(label: Constants.Operation.Body.variableName, expression: bodyVarExpr)
                    },
                ]
                .compactMap { $0 }
            )

        let optionalStatusCode: [FunctionArgumentDescription]
        if responseKind.wantsStatusCode {
            optionalStatusCode = [
                .init(label: "statusCode", expression: .identifierPattern("response").dot("status").dot("code"))
            ]
        } else {
            optionalStatusCode = []
        }

        let returnExpr: Expression = .return(
            .dot(responseKind.identifier).call(optionalStatusCode + [.init(label: nil, expression: initExpr)])
        )

        codeBlocks.append(.expression(returnExpr))

        return .init(kind: caseKind, body: codeBlocks)
    }
}

extension ServerFileTranslator {

    /// Returns a switch case expression that matches the Output case of
    /// the response in the Output type.
    /// - Parameters:
    ///   - outcome: The OpenAPI response.
    ///   - operation: The OpenAPI operation.
    /// - Returns: A switch case expression.
    /// - Throws: An error if there's an issue generating the switch case
    ///           expression, such as encountering unsupported response types
    ///           or invalid definitions.
    func translateResponseOutcomeInServer(outcome: OpenAPI.Operation.ResponseOutcome, operation: OperationDescription)
        throws -> SwitchCaseDescription
    {

        let typedResponse = try typedResponse(from: outcome, operation: operation)
        let responseStructTypeName = typedResponse.typeUsage.typeName
        let responseKind = outcome.status.value.asKind

        var codeBlocks: [CodeBlock] = []

        let statusCodeExpr: Expression
        if let code = responseKind.code {
            statusCodeExpr = .literal(code)
        } else {
            statusCodeExpr = .identifierPattern("statusCode")
        }

        let responseVarDecl: Declaration = .variable(
            kind: .var,
            left: "response",
            right: .identifierType(TypeName.response)
                .call([.init(label: "soar_statusCode", expression: statusCodeExpr)])
        )
        codeBlocks.append(contentsOf: [
            .declaration(responseVarDecl), .expression(responseVarDecl.suppressMutabilityWarningExpr),
        ])

        let bodyTypeName = responseStructTypeName.appending(swiftComponent: Constants.Operation.Body.typeName)
        let headersTypeName = responseStructTypeName.appending(
            swiftComponent: Constants.Operation.Output.Payload.Headers.typeName
        )

        let headers = try typedResponseHeaders(from: typedResponse.response, inParent: headersTypeName)
        let headerExprs: [Expression] = try headers.map { header in
            try translateResponseHeaderInServer(header, responseVariableName: "response")
        }
        codeBlocks.append(contentsOf: headerExprs.map { .expression($0) })

        let bodyReturnExpr: Expression
        let typedContents = try supportedTypedContents(
            typedResponse.response.content,
            isRequired: true,
            inParent: bodyTypeName
        )
        if !typedContents.isEmpty {
            codeBlocks.append(.declaration(.variable(kind: .let, left: "body", type: .init(TypeName.body))))
            let switchContentCases: [SwitchCaseDescription] = try typedContents.map { typedContent in

                var caseCodeBlocks: [CodeBlock] = []

                let contentTypeHeaderValue = typedContent.content.contentType.headerValueForValidation
                let validateAcceptHeader: Expression = .try(
                    .identifierPattern("converter").dot("validateAcceptIfPresent")
                        .call([
                            .init(label: nil, expression: .literal(contentTypeHeaderValue)),
                            .init(label: "in", expression: .identifierPattern("request").dot("headerFields")),
                        ])
                )
                caseCodeBlocks.append(.expression(validateAcceptHeader))

                let contentType = typedContent.content.contentType
                let extraBodyAssignArgs: [FunctionArgumentDescription]
                if contentType.isMultipart {
                    extraBodyAssignArgs = try translateMultipartSerializerExtraArgumentsInServer(typedContent)
                } else {
                    extraBodyAssignArgs = []
                }
                let assignBodyExpr: Expression = .assignment(
                    left: .identifierPattern("body"),
                    right: .try(
                        .identifierPattern("converter")
                            .dot("setResponseBodyAs\(contentType.codingStrategy.runtimeName)")
                            .call(
                                [
                                    .init(label: nil, expression: .identifierPattern("value")),
                                    .init(
                                        label: "headerFields",
                                        expression: .inOut(.identifierPattern("response").dot("headerFields"))
                                    ),
                                    .init(
                                        label: "contentType",
                                        expression: .literal(contentType.headerValueForSending)
                                    ),
                                ] + extraBodyAssignArgs
                            )
                    )
                )
                caseCodeBlocks.append(.expression(assignBodyExpr))

                return .init(
                    kind: .case(.dot(context.safeNameGenerator.swiftContentTypeName(for: contentType)), ["value"]),
                    body: caseCodeBlocks
                )
            }

            codeBlocks.append(
                .expression(
                    .switch(switchedExpression: .identifierPattern("value").dot("body"), cases: switchContentCases)
                )
            )

            bodyReturnExpr = .identifierPattern("body")
        } else {
            bodyReturnExpr = .literal(nil)
        }

        let returnExpr: Expression = .return(.tuple([.identifierPattern("response"), bodyReturnExpr]))
        codeBlocks.append(.expression(returnExpr))

        let caseKind: SwitchCaseKind
        let optionalStatusCode: [String]
        if responseKind.wantsStatusCode { optionalStatusCode = ["statusCode"] } else { optionalStatusCode = [] }
        caseKind = .`case`(.dot(responseKind.identifier), optionalStatusCode + ["value"])
        codeBlocks = [.expression(.suppressUnusedWarning(for: "value"))] + codeBlocks

        return .init(kind: caseKind, body: codeBlocks)
    }
}
