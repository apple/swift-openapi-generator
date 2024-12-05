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

extension ClientFileTranslator {

    /// Returns an expression that converts an Input type into a request for
    /// a specified OpenAPI operation.
    /// - Parameter description: The OpenAPI operation.
    /// - Returns: An expression representing the converted request.
    /// - Throws: An error if there is an issue during translation.
    func translateClientSerializer(_ description: OperationDescription) throws -> Expression {

        let (pathTemplate, pathParamsArrayExpr) = try translatePathParameterInClient(description: description)
        let pathDecl: Declaration = .variable(
            kind: .let,
            left: "path",
            right: .try(
                .identifierPattern("converter").dot("renderedPath")
                    .call([
                        .init(label: "template", expression: .literal(pathTemplate)),
                        .init(label: "parameters", expression: pathParamsArrayExpr),
                    ])
            )
        )
        let requestDecl: Declaration = .variable(
            kind: .var,
            left: "request",
            type: .init(TypeName.request),
            right: .dot("init")
                .call([
                    .init(label: "soar_path", expression: .identifierPattern("path")),
                    .init(label: "method", expression: .dot(description.httpMethodLowercased)),
                ])
        )

        let typedParameters = try typedParameters(from: description)
        var requestBlocks: [CodeBlock] = []

        let nonPathParameters = typedParameters.filter { $0.location != .path }
        let nonPathParamExprs: [Expression] = try nonPathParameters.compactMap { parameter in
            try translateNonPathParameterInClient(parameter, requestVariableName: "request", inputVariableName: "input")
        }
        requestBlocks.append(contentsOf: nonPathParamExprs.map { .expression($0) })

        let acceptContent = try acceptHeaderContentTypes(for: description)
        if !acceptContent.isEmpty {
            let setAcceptHeaderExpr: Expression = .identifierPattern("converter").dot("setAcceptHeader")
                .call([
                    .init(label: "in", expression: .inOut(.identifierPattern("request").dot("headerFields"))),
                    .init(label: "contentTypes", expression: .identifierPattern("input").dot("headers").dot("accept")),
                ])
            requestBlocks.append(.expression(setAcceptHeaderExpr))
        }

        let requestBodyReturnExpr: Expression
        if let requestBody = try typedRequestBody(in: description) {
            let bodyVariableName = "body"
            requestBlocks.append(
                .declaration(
                    .variable(kind: .let, left: bodyVariableName, type: .init(TypeName.body.asUsage.asOptional))
                )
            )
            requestBodyReturnExpr = .identifierPattern(bodyVariableName)
            let requestBodyExpr = try translateRequestBodyInClient(
                requestBody,
                requestVariableName: "request",
                bodyVariableName: bodyVariableName,
                inputVariableName: "input"
            )
            requestBlocks.append(.expression(requestBodyExpr))
        } else {
            requestBodyReturnExpr = .literal(nil)
        }

        let returnRequestExpr: Expression = .return(.tuple([.identifierPattern("request"), requestBodyReturnExpr]))

        return .closureInvocation(
            argumentNames: ["input"],
            body: [
                .declaration(pathDecl), .declaration(requestDecl),
                .expression(requestDecl.suppressMutabilityWarningExpr),
            ] + requestBlocks + [.expression(returnRequestExpr)]
        )
    }

    /// Returns an expression that converts a Response into an Output for
    /// a specified OpenAPI operation.
    ///
    /// - Parameter description: The OpenAPI operation.
    /// - Throws: An error if there is an issue during translation.
    /// - Returns: An expression representing the translation of a Response to an Output.
    func translateClientDeserializer(_ description: OperationDescription) throws -> Expression {
        var cases: [SwitchCaseDescription] = try description.responseOutcomes.map { outcome in
            try translateResponseOutcomeInClient(outcome: outcome, operation: description)
        }
        if !description.containsDefaultResponse {
            let undocumentedExpr: Expression = .return(
                .dot(Constants.Operation.Output.undocumentedCaseName)
                    .call([
                        .init(
                            label: "statusCode",
                            expression: .identifierPattern("response").dot("status").dot("code")
                        ),
                        .init(
                            label: nil,
                            expression: .dot("init")
                                .call([
                                    .init(
                                        label: "headerFields",
                                        expression: .identifierPattern("response").dot("headerFields")
                                    ), .init(label: "body", expression: .identifierPattern("responseBody")),
                                ])
                        ),
                    ])
            )
            cases.append(.init(kind: .default, body: [.expression(undocumentedExpr)]))
        }
        let switchStatusCodeExpr: Expression = .switch(
            switchedExpression: .identifierPattern("response").dot("status").dot("code"),
            cases: cases
        )
        return .closureInvocation(
            argumentNames: ["response", "responseBody"],
            body: [.expression(switchStatusCodeExpr)]
        )
    }

    /// Returns a declaration of a client method that invokes a specified
    /// OpenAPI operation.
    /// - Parameter description: The OpenAPI operation.
    /// - Throws: An error if there is an issue during translation.
    /// - Returns: A declaration representing the translated client method.
    func translateClientMethod(_ description: OperationDescription) throws -> Declaration {

        let operationTypeExpr = Expression.identifierType(.member(Constants.Operations.namespace))
            .dot(description.operationTypeName)

        let operationArg = FunctionArgumentDescription(label: "forOperation", expression: operationTypeExpr.dot("id"))
        let inputArg = FunctionArgumentDescription(
            label: "input",
            expression: .identifierPattern(Constants.Operation.Input.variableName)
        )
        let serializerArg = FunctionArgumentDescription(
            label: "serializer",
            expression: try translateClientSerializer(description)
        )
        let deserializerArg = FunctionArgumentDescription(
            label: "deserializer",
            expression: try translateClientDeserializer(description)
        )

        let sendExpr: Expression = .try(
            .await(
                .functionCall(
                    calledExpression: .identifierPattern("client").dot("send"),
                    arguments: [inputArg, operationArg, serializerArg, deserializerArg]
                )
            )
        )
        return .commentable(
            description.comment,
            .function(
                signature: description.protocolSignatureDescription.withAccessModifier(config.access),
                body: [.expression(sendExpr)]
            )
            .deprecate(if: description.operation.deprecated)
        )
    }
}
