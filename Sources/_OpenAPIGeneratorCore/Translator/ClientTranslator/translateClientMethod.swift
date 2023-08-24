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

extension ClientFileTranslator {

    /// Returns an expression that converts an Input type into a request for
    /// a specified OpenAPI operation.
    /// - Parameter description: The OpenAPI operation.
    func translateClientSerializer(
        _ description: OperationDescription
    ) throws -> Expression {

        let (pathTemplate, pathParamsArrayExpr) = try translatePathParameterInClient(
            description: description
        )
        let pathDecl: Declaration = .variable(
            kind: .let,
            left: "path",
            right: .try(
                .identifier("converter")
                    .dot("renderedRequestPath")
                    .call([
                        .init(label: "template", expression: .literal(pathTemplate)),
                        .init(label: "parameters", expression: pathParamsArrayExpr),
                    ])
            )
        )
        let requestDecl: Declaration = .variable(
            kind: .var,
            left: "request",
            type: TypeName.request.fullyQualifiedSwiftName,
            right: .dot("init")
                .call([
                    .init(label: "path", expression: .identifier("path")),
                    .init(label: "method", expression: .dot(description.httpMethodLowercased)),
                ])
        )

        let typedParameters = try typedParameters(
            from: description
        )
        var requestExprs: [Expression] = []

        let nonPathParameters =
            typedParameters
            .filter { $0.location != .path }
        let nonPathParamExprs: [Expression] =
            try nonPathParameters
            .compactMap { parameter in
                try translateNonPathParameterInClient(
                    parameter,
                    requestVariableName: "request",
                    inputVariableName: "input"
                )
            }
        requestExprs.append(contentsOf: nonPathParamExprs)

        let acceptContent = try acceptHeaderContentTypes(
            for: description
        )
        if !acceptContent.isEmpty {
            let setAcceptHeaderExpr: Expression =
                .identifier("converter")
                .dot("setAcceptHeader")
                .call([
                    .init(
                        label: "in",
                        expression: .inOut(.identifier("request").dot("headerFields"))
                    ),
                    .init(
                        label: "contentTypes",
                        expression: .identifier("input").dot("headers").dot("accept")
                    ),
                ])
            requestExprs.append(setAcceptHeaderExpr)
        }

        if let requestBody = try typedRequestBody(in: description) {
            let requestBodyExpr = try translateRequestBodyInClient(
                requestBody,
                requestVariableName: "request",
                inputVariableName: "input"
            )
            requestExprs.append(requestBodyExpr)
        }

        let returnRequestExpr: Expression = .return(.identifier("request"))

        return .closureInvocation(
            argumentNames: [
                "input"
            ],
            body: [
                .declaration(pathDecl),
                .declaration(requestDecl),
                .expression(requestDecl.suppressMutabilityWarningExpr),
            ] + requestExprs.map { .expression($0) } + [
                .expression(returnRequestExpr)
            ]
        )
    }

    /// Returns an expression that converts a Response into an Output for
    /// a specified OpenAPI operation.
    /// - Parameter description: The OpenAPI operation.
    func translateClientDeserializer(
        _ description: OperationDescription
    ) throws -> Expression {
        var cases: [SwitchCaseDescription] =
            try description
            .responseOutcomes
            .map { outcome in
                try translateResponseOutcomeInClient(
                    outcome: outcome,
                    operation: description
                )
            }
        if !description.containsDefaultResponse {
            let undocumentedExpr: Expression = .return(
                .dot(Constants.Operation.Output.undocumentedCaseName)
                    .call([
                        .init(label: "statusCode", expression: .identifier("response").dot("statusCode")),
                        .init(label: nil, expression: .dot("init").call([])),
                    ])
            )
            cases.append(
                .init(
                    kind: .default,
                    body: [
                        .expression(undocumentedExpr)
                    ]
                )
            )
        }
        let switchStatusCodeExpr: Expression = .switch(
            switchedExpression: .identifier("response").dot("statusCode"),
            cases: cases
        )
        return .closureInvocation(
            argumentNames: ["response"],
            body: [
                .expression(switchStatusCodeExpr)
            ]
        )
    }

    /// Returns a declaration of a client method that invokes a specified
    /// OpenAPI operation.
    /// - Parameter description: The OpenAPI operation.
    func translateClientMethod(
        _ description: OperationDescription
    ) throws -> Declaration {

        let operationTypeExpr =
            Expression
            .identifier(Constants.Operations.namespace)
            .dot(description.methodName)

        let operationArg = FunctionArgumentDescription(
            label: "forOperation",
            expression: operationTypeExpr.dot("id")
        )
        let inputArg = FunctionArgumentDescription(
            label: "input",
            expression: .identifier(Constants.Operation.Input.variableName)
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
                    calledExpression: .identifier("client").dot("send"),
                    arguments: [
                        inputArg,
                        operationArg,
                        serializerArg,
                        deserializerArg,
                    ]
                )
            )
        )
        return .commentable(
            description.comment,
            .function(
                signature: description
                    .protocolSignatureDescription
                    .withAccessModifier(config.access),
                body: [
                    .expression(sendExpr)
                ]
            )
            .deprecate(if: description.operation.deprecated)
        )
    }
}
