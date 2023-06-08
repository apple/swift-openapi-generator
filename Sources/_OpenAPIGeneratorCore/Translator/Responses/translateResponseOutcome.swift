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
    ) throws -> (payloadStruct: Declaration?, enumCase: Declaration) {

        let typedResponse = try typedResponse(
            from: outcome,
            operation: operation
        )
        let responseStructTypeName = typedResponse.typeUsage.typeName
        let responseKind = outcome.status.value.asKind

        let responseStructDecl: Declaration?
        if typedResponse.isInlined {
            responseStructDecl = try translateResponseInTypes(
                typeName: typedResponse.typeUsage.typeName,
                response: typedResponse
            )
        } else {
            responseStructDecl = nil
        }

        let optionalStatusCode: [EnumCaseAssociatedValueDescription]
        if responseKind.wantsStatusCode {
            optionalStatusCode = [
                .init(label: "statusCode", type: TypeName.int.shortSwiftName)
            ]
        } else {
            optionalStatusCode = []
        }

        let enumCaseDesc = EnumCaseDescription(
            name: responseKind.identifier,
            kind: .nameWithAssociatedValues(
                optionalStatusCode + [
                    .init(type: responseStructTypeName.fullyQualifiedSwiftName)
                ]
            )
        )
        let enumCaseDecl: Declaration = .commentable(
            responseKind.docComment(
                userDescription: typedResponse.response.description,
                jsonPath: operationJSONPath + "/responses/" + responseKind.jsonPathComponent
            ),
            .enumCase(enumCaseDesc)
        )
        return (responseStructDecl, enumCaseDecl)
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
        let headersVarExpr: Expression = .identifier("headers")

        let bodyVarExpr: Expression
        if let typedContent = try bestSingleTypedContent(
            typedResponse.response.content,
            inParent: bodyTypeName
        ) {
            let validateContentTypeExpr: Expression = .try(
                .identifier("converter").dot("validateContentTypeIfPresent")
                    .call([
                        .init(label: "in", expression: .identifier("response").dot("headerFields")),
                        .init(
                            label: "substring",
                            expression: .literal(
                                typedContent
                                    .content
                                    .contentType
                                    .headerValueForValidation
                            )
                        ),
                    ])
            )
            codeBlocks.append(.expression(validateContentTypeExpr))

            let contentTypeUsage = typedContent.resolvedTypeUsage
            let transformExpr: Expression = .closureInvocation(
                argumentNames: ["value"],
                body: [
                    .expression(
                        .dot(typedContent.content.contentType.identifier)
                            .call([
                                .init(label: nil, expression: .identifier("value"))
                            ])
                    )
                ]
            )
            let bodyDecl: Declaration = .variable(
                kind: .let,
                left: "body",
                type: bodyTypeName.fullyQualifiedSwiftName,
                right: .try(
                    .identifier("converter")
                        .dot("getResponseBodyAs\(typedContent.content.contentType.codingStrategy.runtimeName)")
                        .call([
                            .init(
                                label: nil,
                                expression: .identifier(contentTypeUsage.fullyQualifiedSwiftName).dot("self")
                            ),
                            .init(label: "from", expression: .identifier("response").dot("body")),
                            .init(
                                label: "transforming",
                                expression: transformExpr
                            ),
                        ])
                )
            )
            codeBlocks.append(.declaration(bodyDecl))
            bodyVarExpr = .identifier("body")
        } else {
            bodyVarExpr = .literal(.nil)
        }

        let initExpr: Expression = .dot("init")
            .call([
                .init(
                    label: Constants.Operation.Output.Payload.Headers.variableName,
                    expression: headersVarExpr
                ),
                .init(
                    label: Constants.Operation.Body.variableName,
                    expression: bodyVarExpr
                ),
            ])

        let optionalStatusCode: [FunctionArgumentDescription]
        if responseKind.wantsStatusCode {
            optionalStatusCode = [
                .init(
                    label: "statusCode",
                    expression: .identifier("response").dot("statusCode")
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
            type: "Response",
            right: .dot("init")
                .call([
                    .init(label: "statusCode", expression: statusCodeExpr)
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

        if let typedContent = try bestSingleTypedContent(
            typedResponse.response.content,
            inParent: bodyTypeName
        ) {
            let contentTypeHeaderValue = typedContent.content.contentType.headerValueForValidation
            let validateAcceptHeader: Expression = .try(
                .identifier("converter").dot("validateAcceptIfPresent")
                    .call([
                        .init(label: nil, expression: .literal(contentTypeHeaderValue)),
                        .init(label: "in", expression: .identifier("request").dot("headerFields")),
                    ])
            )
            codeBlocks.append(.expression(validateAcceptHeader))

            let contentType = typedContent.content.contentType
            let switchContentCases: [SwitchCaseDescription] = [
                .init(
                    kind: .case(.dot(contentType.identifier), ["value"]),
                    body: [
                        .expression(
                            .return(
                                .dot("init")
                                    .call([
                                        .init(
                                            label: "value",
                                            expression: .identifier("value")
                                        ),
                                        .init(
                                            label: "contentType",
                                            expression: .literal(contentType.headerValueForSending)
                                        ),
                                    ])
                            )
                        )
                    ]
                )
            ]

            let transformExpr: Expression = .closureInvocation(
                argumentNames: ["wrapped"],
                body: [
                    .expression(
                        .switch(
                            switchedExpression: .identifier("wrapped"),
                            cases: switchContentCases
                        )
                    )
                ]
            )
            let assignBodyExpr: Expression = .assignment(
                left: .identifier("response").dot("body"),
                right: .try(
                    .identifier("converter")
                        .dot("setResponseBodyAs\(contentType.codingStrategy.runtimeName)")
                        .call([
                            .init(label: nil, expression: .identifier("value").dot("body")),
                            .init(
                                label: "headerFields",
                                expression: .inOut(
                                    .identifier("response").dot("headerFields")
                                )
                            ),
                            .init(label: "transforming", expression: transformExpr),
                        ])
                )
            )
            codeBlocks.append(.expression(assignBodyExpr))
        }

        let returnExpr: Expression = .return(
            .identifier("response")
        )
        codeBlocks.append(.expression(returnExpr))

        let caseKind: SwitchCaseKind
        switch responseKind {
        case .code, .`default`:
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
        case let .range(range):
            caseKind = .`case`(
                .binaryOperation(
                    left: .literal(range.lowerBound),
                    operation: .rangeInclusive,
                    right: .literal(range.upperBound)
                )
            )
        }

        return .init(
            kind: caseKind,
            body: codeBlocks
        )
    }
}
