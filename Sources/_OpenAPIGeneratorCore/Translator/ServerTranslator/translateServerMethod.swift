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

extension ServerFileTranslator {

    /// Returns an expression that converts a request into an Input type for
    /// a specified OpenAPI operation.
    /// - Parameter description: The OpenAPI operation.
    func translateServerDeserializer(
        _ operation: OperationDescription
    ) throws -> Expression {
        var closureBody: [CodeBlock] = []

        let typedRequestBody = try typedRequestBody(in: operation)

        if let headerValueForValidation = typedRequestBody?
            .content
            .content
            .contentType
            .headerValueForValidation
        {
            let validateContentTypeExpr: Expression = .try(
                .identifier("converter").dot("validateContentTypeIfPresent")
                    .call([
                        .init(label: "in", expression: .identifier("request").dot("headerFields")),
                        .init(
                            label: "substring",
                            expression: .literal(headerValueForValidation)
                        ),
                    ])
            )
            closureBody.append(.expression(validateContentTypeExpr))
        }

        let inputTypeName = operation.inputTypeName

        func locationSpecificInputDecl(
            locatedIn location: OpenAPI.Parameter.Context.Location,
            fromParameters parameters: [UnresolvedParameter]
        ) throws -> Declaration {
            let variableName = location.shortVariableName
            let type = location.typeName(in: inputTypeName)
            return .variable(
                kind: .let,
                left: variableName,
                type: type.fullyQualifiedSwiftName,
                right: .dot("init")
                    .call(
                        try parameters.compactMap {
                            try parseAsTypedParameter(
                                from: $0,
                                inParent: operation.inputTypeName
                            )
                        }
                        .compactMap(translateParameterInServer(_:))
                    )
            )
        }

        var inputMemberDecls = try [
            (
                .path,
                operation.allPathParameters
            ),
            (
                .query,
                operation.allQueryParameters
            ),
            (
                .header,
                operation.allHeaderParameters
            ),
            (
                .cookie,
                operation.allCookieParameters
            ),
        ]
        .map(locationSpecificInputDecl(locatedIn:fromParameters:))

        let bodyDecl = try translateRequestBodyInServer(
            typedRequestBody,
            requestVariableName: "request",
            bodyVariableName: "body",
            inputTypeName: inputTypeName
        )
        inputMemberDecls.append(bodyDecl)

        func functionArgumentForLocation(
            _ location: OpenAPI.Parameter.Context.Location
        ) -> FunctionArgumentDescription {
            .init(
                label: location.shortVariableName,
                expression: .identifier(location.shortVariableName)
            )
        }

        let returnExpr: Expression = .return(
            .identifier(inputTypeName.fullyQualifiedSwiftName)
                .call([
                    functionArgumentForLocation(.path),
                    functionArgumentForLocation(.query),
                    functionArgumentForLocation(.header),
                    functionArgumentForLocation(.cookie),
                    .init(label: "body", expression: .identifier("body")),
                ])
        )

        closureBody.append(
            contentsOf: inputMemberDecls.map(CodeBlock.declaration) + [.expression(returnExpr)]
        )

        return .closureInvocation(
            argumentNames: ["request", "metadata"],
            body: closureBody
        )
    }

    /// Returns an expression that converts an Output type into a response
    /// for a specified OpenAPI operation.
    /// - Parameter description: The OpenAPI operation.
    func translateServerSerializer(_ description: OperationDescription) throws -> Expression {
        var cases: [SwitchCaseDescription] =
            try description
            .operation
            .responseOutcomes
            .map { outcome in
                try translateResponseOutcomeInServer(
                    outcome: outcome,
                    operation: description
                )
            }
        if !description.containsDefaultResponse {
            let undocumentedExpr: Expression = .return(
                .dot("init")
                    .call([
                        .init(label: "statusCode", expression: .identifier("statusCode"))
                    ])
            )
            cases.append(
                .init(
                    kind: .case(
                        .dot(Constants.Operation.Output.undocumentedCaseName),
                        [
                            "statusCode",
                            "_",
                        ]
                    ),
                    body: [
                        .expression(undocumentedExpr)
                    ]
                )
            )
        }
        let switchStatusCodeExpr: Expression = .switch(
            switchedExpression: .identifier("output"),
            cases: cases
        )
        return .closureInvocation(
            argumentNames: ["output", "request"],
            body: [
                .expression(switchStatusCodeExpr)
            ]
        )
    }

    /// Returns a declaration of a server method that handles a specified
    /// OpenAPI operation.
    /// - Parameters:
    ///   - description: The OpenAPI operation.
    ///   - serverUrlVariableName: The name of the server URL variable.
    /// - Returns: A declaration of a function, and an expression that registers
    /// the function with the router.
    func translateServerMethod(
        _ description: OperationDescription,
        serverUrlVariableName: String
    ) throws -> (registerCall: Expression, functionDecl: Declaration) {

        let operationTypeExpr =
            Expression
            .identifier(Constants.Operations.namespace)
            .dot(description.methodName)

        let operationArg: FunctionArgumentDescription = .init(
            label: "forOperation",
            expression: operationTypeExpr.dot("id")
        )
        let requestArg: FunctionArgumentDescription = .init(
            label: "request",
            expression: .identifier("request")
        )
        let metadataArg: FunctionArgumentDescription = .init(
            label: "with",
            expression: .identifier("metadata")
        )
        let methodArg: FunctionArgumentDescription = .init(
            label: "using",
            expression: .closureInvocation(
                body: [
                    .expression(
                        .identifier(Constants.Server.Universal.apiHandlerName)
                            .dot(description.methodName)
                            .call([
                                .init(label: nil, expression: .identifier("$0"))
                            ])
                    )
                ]
            )
        )
        let deserializerArg: FunctionArgumentDescription = .init(
            label: "deserializer",
            expression: try translateServerDeserializer(description)
        )
        let serializerArg: FunctionArgumentDescription = .init(
            label: "serializer",
            expression: try translateServerSerializer(description)
        )

        let wrapperClosureExpr: Expression = .closureInvocation(
            body: [
                .expression(
                    .try(
                        .await(
                            .identifier(serverUrlVariableName)
                                .dot(description.methodName)
                                .call([
                                    .init(label: "request", expression: .identifier("$0")),
                                    .init(label: "metadata", expression: .identifier("$1")),
                                ])
                        )
                    )
                )
            ]
        )
        let registerCall: Expression = .try(
            .identifier("transport").dot("register")
                .call([
                    .init(label: nil, expression: wrapperClosureExpr),
                    .init(label: "method", expression: .dot(description.httpMethodLowercased)),
                    .init(
                        label: "path",
                        expression: .identifier(serverUrlVariableName)
                            .dot("apiPathComponentsWithServerPrefix")
                            .call([
                                .init(
                                    label: nil,
                                    expression: .literal(
                                        .array(description.templatedPathForServer.map { .literal($0) })
                                    )
                                )
                            ])
                    ),
                    .init(
                        label: "queryItemNames",
                        expression: .literal(
                            .array(
                                try description.queryParameterNames.map { .literal($0) }
                            )
                        )
                    ),
                ])
        )

        let handleExpr: Expression = .try(
            .await(
                .identifier("handle")
                    .call([
                        requestArg,
                        metadataArg,
                        operationArg,
                        methodArg,
                        deserializerArg,
                        serializerArg,
                    ])
            )
        )

        let functionDecl: Declaration = .commentable(
            description.comment,
            .function(
                signature: description.serverImplSignatureDescription,
                body: [
                    .expression(handleExpr)
                ]
            )
            .deprecate(if: description.operation.deprecated)
        )

        return (registerCall, functionDecl)
    }
}
