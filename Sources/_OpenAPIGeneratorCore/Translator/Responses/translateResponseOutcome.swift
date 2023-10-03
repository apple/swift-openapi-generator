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
    /// - Returns: A declaration of the enum case and a declaration of the
    /// structure unique to the response that contains the response headers
    /// and a body payload.
    func translateResponseOutcomeInTypes(
        _ outcome: OpenAPI.Operation.ResponseOutcome,
        operation: OperationDescription,
        operationJSONPath: String
    ) throws -> (payloadStruct: Declaration?, enumCase: Declaration, throwingGetter: Declaration) {

        let typedResponse = try typedResponse(
            from: outcome,
            operation: operation
        )
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
            associatedValues.append(.init(label: "statusCode", type: TypeName.int.shortSwiftName))
        }
        associatedValues.append(.init(type: responseStructTypeName.fullyQualifiedSwiftName))

        let enumCaseDesc = EnumCaseDescription(
            name: enumCaseName,
            kind: .nameWithAssociatedValues(associatedValues)
        )
        let enumCaseDecl: Declaration = .commentable(
            responseKind.docComment(
                userDescription: typedResponse.response.description,
                jsonPath: operationJSONPath + "/responses/" + responseKind.jsonPathComponent
            ),
            .enumCase(enumCaseDesc)
        )

        let throwingGetterDesc = VariableDescription(
            accessModifier: config.access,
            kind: .var,
            left: enumCaseName,
            type: responseStructTypeName.fullyQualifiedSwiftName,
            getter: [
                .expression(
                    .switch(
                        switchedExpression: .identifier("self"),
                        cases: [
                            SwitchCaseDescription(
                                kind: .case(
                                    .identifier(".\(responseKind.identifier)"),
                                    responseKind.wantsStatusCode ? ["_", "response"] : ["response"]
                                ),
                                body: [.expression(.return(.identifier("response")))]
                            ),
                            SwitchCaseDescription(
                                kind: .default,
                                body: [
                                    .expression(
                                        .try(
                                            .identifier("throwUnexpectedResponseStatus")
                                                .call([
                                                    .init(
                                                        label: "expectedStatus",
                                                        expression: .literal(.string(responseKind.prettyName))
                                                    ),
                                                    .init(label: "response", expression: .identifier("self")),
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
        let throwingGetterDecl = Declaration.commentable(
            throwingGetterComment,
            .variable(throwingGetterDesc)
        )

        return (responseStructDecl, enumCaseDecl, throwingGetterDecl)
    }
}

extension ClientFileTranslator {

    /// Returns a switch case expression that matches the HTTP status code
    /// of the specified response.
    /// - Parameters:
    ///   - outcome: The OpenAPI response.
    ///   - operation: The OpenAPI operation.
    /// - Returns: A switch case expression.
    func translateResponseOutcomeInClient(
        outcome: OpenAPI.Operation.ResponseOutcome,
        operation: OperationDescription
    ) throws -> SwitchCaseDescription {

        let typedResponse = try typedResponse(
            from: outcome,
            operation: operation
        )
        let responseStructTypeName = typedResponse.typeUsage.typeName
        let responseKind = outcome.status.value.asKind

        let caseKind: SwitchCaseKind
        switch responseKind {
        case let .code(code):
            caseKind = .`case`(.literal(code))
        case let .range(range):
            caseKind = .`case`(
                .binaryOperation(
                    left: .literal(range.lowerBound),
                    operation: .rangeInclusive,
                    right: .literal(range.upperBound)
                )
            )
        case .`default`:
            caseKind = .`default`
        }

        var codeBlocks: [CodeBlock] = []

        let headersTypeName = responseStructTypeName.appending(
            swiftComponent: Constants.Operation.Output.Payload.Headers.typeName
        )
        let bodyTypeName = responseStructTypeName.appending(
            swiftComponent: Constants.Operation.Body.typeName
        )

        let headers = try typedResponseHeaders(
            from: typedResponse.response,
            inParent: headersTypeName
        )
        let headersVarExpr: Expression?
        if !headers.isEmpty {
            let headerInitArgs: [FunctionArgumentDescription] = try headers.map { header in
                try translateResponseHeaderInClient(
                    header,
                    responseVariableName: "response"
                )
            }
            let headersInitExpr: Expression = .dot("init").call(headerInitArgs)
            let headersVarDecl: Declaration = .variable(
                kind: .let,
                left: "headers",
                type: headersTypeName.fullyQualifiedSwiftName,
                right: headersInitExpr
            )
            codeBlocks.append(.declaration(headersVarDecl))
            headersVarExpr = .identifier("headers")
        } else {
            headersVarExpr = nil
        }

        let typedContents = try supportedTypedContents(
            typedResponse.response.content,
            inParent: bodyTypeName
        )
        let bodyVarExpr: Expression?
        if !typedContents.isEmpty {

            let contentTypeDecl: Declaration = .variable(
                kind: .let,
                left: "contentType",
                right: .identifier("converter")
                    .dot("extractContentTypeIfPresent")
                    .call([
                        .init(
                            label: "in",
                            expression: .identifier("response")
                                .dot("headerFields")
                        )
                    ])
            )
            codeBlocks.append(.declaration(contentTypeDecl))

            let bodyDecl: Declaration = .variable(
                kind: .let,
                left: "body",
                type: bodyTypeName.fullyQualifiedSwiftName
            )
            codeBlocks.append(.declaration(bodyDecl))

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
                let codingStrategy = typedContent.content.contentType.codingStrategy
                let converterExpr: Expression = .identifier("converter")
                    .dot("getResponseBodyAs\(codingStrategy.runtimeName)")
                    .call([
                        .init(
                            label: nil,
                            expression: .identifier(contentTypeUsage.fullyQualifiedSwiftName).dot("self")
                        ),
                        .init(label: "from", expression: .identifier("responseBody")),
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

            bodyVarExpr = .identifier("body")
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
                        .init(
                            label: Constants.Operation.Body.variableName,
                            expression: bodyVarExpr
                        )
                    },
                ]
                .compactMap { $0 }
            )

        let optionalStatusCode: [FunctionArgumentDescription]
        if responseKind.wantsStatusCode {
            optionalStatusCode = [
                .init(
                    label: "statusCode",
                    expression: .identifier("response").dot("status").dot("code")
                )
            ]
        } else {
            optionalStatusCode = []
        }

        let returnExpr: Expression = .return(
            .dot(responseKind.identifier)
                .call(
                    optionalStatusCode + [
                        .init(label: nil, expression: initExpr)
                    ]
                )
        )

        codeBlocks.append(.expression(returnExpr))

        return .init(
            kind: caseKind,
            body: codeBlocks
        )
    }
}

extension ServerFileTranslator {

    /// Returns a switch case expression that matches the Output case of
    /// the response in the Output type.
    /// - Parameters:
    ///   - outcome: The OpenAPI response.
    ///   - operation: The OpenAPI operation.
    /// - Returns: A switch case expression.
    func translateResponseOutcomeInServer(
        outcome: OpenAPI.Operation.ResponseOutcome,
        operation: OperationDescription
    ) throws -> SwitchCaseDescription {

        let typedResponse = try typedResponse(
            from: outcome,
            operation: operation
        )
        let responseStructTypeName = typedResponse.typeUsage.typeName
        let responseKind = outcome.status.value.asKind

        var codeBlocks: [CodeBlock] = []

        let statusCodeExpr: Expression
        if let code = responseKind.code {
            statusCodeExpr = .literal(code)
        } else {
            statusCodeExpr = .identifier("statusCode")
        }

        let responseVarDecl: Declaration = .variable(
            kind: .var,
            left: "response",
            right: .identifier("HTTPResponse")
                .call([
                    .init(label: "soar_statusCode", expression: statusCodeExpr)
                ])
        )
        codeBlocks.append(contentsOf: [
            .declaration(responseVarDecl),
            .expression(responseVarDecl.suppressMutabilityWarningExpr),
        ])

        let bodyTypeName = responseStructTypeName.appending(
            swiftComponent: Constants.Operation.Body.typeName
        )
        let headersTypeName = responseStructTypeName.appending(
            swiftComponent: Constants.Operation.Output.Payload.Headers.typeName
        )

        let headers = try typedResponseHeaders(
            from: typedResponse.response,
            inParent: headersTypeName
        )
        let headerExprs: [Expression] = try headers.map { header in
            try translateResponseHeaderInServer(
                header,
                responseVariableName: "response"
            )
        }
        codeBlocks.append(contentsOf: headerExprs.map { .expression($0) })

        let bodyReturnExpr: Expression
        let typedContents = try supportedTypedContents(
            typedResponse.response.content,
            inParent: bodyTypeName
        )
        if !typedContents.isEmpty {
            codeBlocks.append(
                .declaration(
                    .variable(
                        kind: .let,
                        left: "body",
                        type: "HTTPBody"
                    )
                )
            )
            let switchContentCases: [SwitchCaseDescription] = typedContents.map { typedContent in

                var caseCodeBlocks: [CodeBlock] = []

                let contentTypeHeaderValue = typedContent.content.contentType.headerValueForValidation
                let validateAcceptHeader: Expression = .try(
                    .identifier("converter").dot("validateAcceptIfPresent")
                        .call([
                            .init(label: nil, expression: .literal(contentTypeHeaderValue)),
                            .init(label: "in", expression: .identifier("request").dot("headerFields")),
                        ])
                )
                caseCodeBlocks.append(.expression(validateAcceptHeader))

                let contentType = typedContent.content.contentType
                let assignBodyExpr: Expression = .assignment(
                    left: .identifier("body"),
                    right: .try(
                        .identifier("converter")
                            .dot("setResponseBodyAs\(contentType.codingStrategy.runtimeName)")
                            .call([
                                .init(label: nil, expression: .identifier("value")),
                                .init(
                                    label: "headerFields",
                                    expression: .inOut(
                                        .identifier("response").dot("headerFields")
                                    )
                                ),
                                .init(
                                    label: "contentType",
                                    expression: .literal(contentType.headerValueForSending)
                                ),
                            ])
                    )
                )
                caseCodeBlocks.append(.expression(assignBodyExpr))

                return .init(
                    kind: .case(.dot(contentSwiftName(contentType)), ["value"]),
                    body: caseCodeBlocks
                )
            }

            codeBlocks.append(
                .expression(
                    .switch(
                        switchedExpression: .identifier("value").dot("body"),
                        cases: switchContentCases
                    )
                )
            )

            bodyReturnExpr = .identifier("body")
        } else {
            bodyReturnExpr = nil
        }

        let returnExpr: Expression = .return(
            .tuple([
                .identifier("response"),
                bodyReturnExpr,
            ])
        )
        codeBlocks.append(.expression(returnExpr))

        let caseKind: SwitchCaseKind
        let optionalStatusCode: [String]
        if responseKind.wantsStatusCode {
            optionalStatusCode = ["statusCode"]
        } else {
            optionalStatusCode = []
        }
        caseKind = .`case`(
            .dot(responseKind.identifier),
            optionalStatusCode + ["value"]
        )
        codeBlocks =
            [
                .expression(
                    .suppressUnusedWarning(
                        for: "value"
                    )
                )
            ] + codeBlocks

        return .init(
            kind: caseKind,
            body: codeBlocks
        )
    }
}
