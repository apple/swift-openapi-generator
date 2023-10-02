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

extension ServerFileTranslator {

    /// Returns an expression that converts a request into an Input type for
    /// a specified OpenAPI operation.
    /// - Parameter description: The OpenAPI operation.
    func translateServerDeserializer(
        _ operation: OperationDescription
    ) throws -> Expression {
        var closureBody: [CodeBlock] = []

        let typedRequestBody = try typedRequestBody(in: operation)
        let inputTypeName = operation.inputTypeName

        func functionArgumentForLocation(
            _ location: OpenAPI.Parameter.Context.Location
        ) -> FunctionArgumentDescription {
            .init(
                label: location.shortVariableName,
                expression: .identifier(location.shortVariableName)
            )
        }

        func locationSpecificInputDecl(
            locatedIn location: OpenAPI.Parameter.Context.Location,
            fromParameters parameters: [UnresolvedParameter],
            extraArguments: [FunctionArgumentDescription]
        ) throws -> (Declaration, FunctionArgumentDescription)? {
            let variableName = location.shortVariableName
            let type = location.typeName(in: inputTypeName)
            let arguments =
                try parameters
                .compactMap {
                    try parseAsTypedParameter(
                        from: $0,
                        inParent: operation.inputTypeName
                    )
                }
                .compactMap(translateParameterInServer(_:))
                + extraArguments
            guard !arguments.isEmpty else {
                return nil
            }
            let decl: Declaration = .variable(
                kind: .let,
                left: variableName,
                type: type.fullyQualifiedSwiftName,
                right: .dot("init").call(arguments)
            )
            let argument = functionArgumentForLocation(location)
            return (decl, argument)
        }

        let extraHeaderArguments: [FunctionArgumentDescription]
        let acceptableContentTypes = try acceptHeaderContentTypes(for: operation)
        if acceptableContentTypes.isEmpty {
            extraHeaderArguments = []
        } else {
            extraHeaderArguments = [
                .init(
                    label: Constants.Operation.AcceptableContentType.variableName,
                    expression: .try(
                        .identifier("converter")
                            .dot("extractAcceptHeaderIfPresent")
                            .call([
                                .init(
                                    label: "in",
                                    expression: .identifier("request").dot("headerFields")
                                )
                            ])
                    )
                )
            ]
        }

        var inputMembers = try [
            (
                .path,
                operation.allPathParameters,
                []
            ),
            (
                .query,
                operation.allQueryParameters,
                []
            ),
            (
                .header,
                operation.allHeaderParameters,
                extraHeaderArguments
            ),
            (
                .cookie,
                operation.allCookieParameters,
                []
            ),
        ]
        .compactMap(locationSpecificInputDecl)
        .map { (codeBlocks: [CodeBlock.declaration($0)], argument: $1) }

        if let typedRequestBody {
            let bodyCodeBlocks = try translateRequestBodyInServer(
                typedRequestBody,
                requestVariableName: "request",
                bodyVariableName: "body",
                inputTypeName: inputTypeName
            )
            inputMembers.append(
                (
                    bodyCodeBlocks,
                    .init(
                        label: "body",
                        expression: .identifier("body")
                    )
                )
            )
        }

        let returnExpr: Expression = .return(
            .identifier(inputTypeName.fullyQualifiedSwiftName)
                .call(inputMembers.map(\.argument))
        )

        closureBody.append(
            contentsOf: inputMembers.flatMap(\.codeBlocks) + [.expression(returnExpr)]
        )
        return .closureInvocation(
            argumentNames: ["request", "requestBody", "metadata"],
            body: closureBody
        )
    }

    /// Returns an expression that converts an Output type into a response
    /// for a specified OpenAPI operation.
    /// - Parameter description: The OpenAPI operation.
    func translateServerSerializer(_ description: OperationDescription) throws -> Expression {
        var cases: [SwitchCaseDescription] =
            try description
            .responseOutcomes
            .map { outcome in
                try translateResponseOutcomeInServer(
                    outcome: outcome,
                    operation: description
                )
            }
        if !description.containsDefaultResponse {
            let undocumentedExpr: Expression = .return(
                .tuple([
                    .dot("init")
                        .call([
                            .init(label: "soar_statusCode", expression: .identifier("statusCode"))
                        ]),
                    nil,
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

        let operationArg = FunctionArgumentDescription(
            label: "forOperation",
            expression: operationTypeExpr.dot("id")
        )
        let requestArg = FunctionArgumentDescription(
            label: "request",
            expression: .identifier("request")
        )
        let requestBodyArg = FunctionArgumentDescription(
            label: "requestBody",
            expression: .identifier("body")
        )
        let metadataArg = FunctionArgumentDescription(
            label: "metadata",
            expression: .identifier("metadata")
        )
        let methodArg = FunctionArgumentDescription(
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
        let deserializerArg = FunctionArgumentDescription(
            label: "deserializer",
            expression: try translateServerDeserializer(description)
        )
        let serializerArg = FunctionArgumentDescription(
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
                                    .init(label: "body", expression: .identifier("$1")),
                                    .init(label: "metadata", expression: .identifier("$2")),
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
                                        .string(description.path.rawValue)
                                    )
                                )
                            ])
                    ),
                ])
        )

        let handleExpr: Expression = .try(
            .await(
                .identifier("handle")
                    .call([
                        requestArg,
                        requestBodyArg,
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
