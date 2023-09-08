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

/// A wrapper of an OpenAPI operation that includes the information
/// about the parent containers of the operation, such as its path
/// item.
struct OperationDescription {

    /// The OpenAPI path of the operation.
    var path: OpenAPI.Path

    /// The OpenAPI endpoint of the operation.
    var endpoint: OpenAPI.PathItem.Endpoint

    /// The path parameters at the operation level.
    var pathParameters: OpenAPI.Parameter.Array

    /// The OpenAPI components, used to resolve JSON references.
    var components: OpenAPI.Components

    /// A converted function from user-provided strings to strings
    /// safe to be used as a Swift identifier.
    var asSwiftSafeName: (String) -> String

    /// The OpenAPI operation object.
    var operation: OpenAPI.Operation {
        endpoint.operation
    }

    /// The HTTP method of the operation.
    var httpMethod: OpenAPI.HttpMethod {
        endpoint.method
    }

    /// Returns a lowercased string for the HTTP method.
    var httpMethodLowercased: String {
        httpMethod.rawValue.lowercased()
    }
}

extension OperationDescription {

    /// Returns operation descriptions for all the operations discovered
    /// in the specified paths dictionary.
    /// - Parameters:
    ///   - map: The paths from the OpenAPI document.
    ///   - components: The components from the OpenAPI document.
    ///   - asSwiftSafeName: A converted function from user-provided strings
    ///   to strings safe to be used as a Swift identifier.
    /// - Throws: if `map` contains any references; see discussion for details.
    ///
    /// This function will throw an error if `map` contains any references, because:
    /// 1. OpenAPI 3.0.3 only supports external path references (cf. 3.1, which supports internal references too)
    /// 2. Swift OpenAPI Generator currently only supports OpenAPI 3.0.x.
    /// 3. Swift OpenAPI Generator currently doesn't support external references.
    static func all(
        from map: OpenAPI.PathItem.Map,
        in components: OpenAPI.Components,
        asSwiftSafeName: @escaping (String) -> String
    ) throws -> [OperationDescription] {
        try map.flatMap { path, value in
            let value = try value.resolve(in: components)
            return value.endpoints.map { endpoint in
                OperationDescription(
                    path: path,
                    endpoint: endpoint,
                    pathParameters: value.parameters,
                    components: components,
                    asSwiftSafeName: asSwiftSafeName
                )
            }
        }
    }

    /// Returns a Swift-safe function name for the operation.
    ///
    /// Uses the `operationID` value in the OpenAPI operation, if one was
    /// specified. Otherwise, computes a unique name from the operation's
    /// path and HTTP method.
    var methodName: String {
        asSwiftSafeName(operationID)
    }

    /// Returns the identifier for the operation.
    ///
    /// If none was provided in the OpenAPI document, synthesizes one from
    /// the path and HTTP method.
    var operationID: String {
        if let operationID = operation.operationId {
            return operationID
        }
        return "\(httpMethod.rawValue.lowercased())\(path.rawValue)"
    }

    /// Returns a documentation comment for the method implementing
    /// the OpenAPI operation.
    var comment: Comment {
        .init(from: self)
    }

    /// Returns the type name of the namespace unique to the operation.
    var operationNamespace: TypeName {
        return .init(
            components: [
                .root,
                .init(swift: Constants.Operations.namespace, json: "paths"),
            ] + path.components.map { .init(swift: nil, json: $0) } + [
                .init(swift: methodName, json: httpMethod.rawValue)
            ]
        )
    }

    /// Returns the name of the Input type.
    var inputTypeName: TypeName {
        operationNamespace.appending(
            swiftComponent: Constants.Operation.Input.typeName,

            // intentionally nil, we'll append the specific params etc
            // with their valid JSON key path when nested inside Input
            jsonComponent: nil
        )
    }

    /// Returns the name of the Output type.
    var outputTypeName: TypeName {
        operationNamespace.appending(
            swiftComponent: Constants.Operation.Output.typeName,
            jsonComponent: "responses"
        )
    }

    /// Returns the name of the AcceptableContentType type.
    var acceptableContentTypeName: TypeName {
        operationNamespace.appending(
            swiftComponent: Constants.Operation.AcceptableContentType.typeName,

            // intentionally nil, we'll append the specific params etc
            // with their valid JSON key path if nested further
            jsonComponent: nil
        )
    }

    /// Returns the name of the array of wrapped AcceptableContentType type.
    var acceptableArrayName: TypeUsage {
        acceptableContentTypeName
            .asUsage
            .asWrapped(
                in: .runtime(
                    Constants.Operation.AcceptableContentType.headerTypeName
                )
            )
            .asArray
    }

    /// Merged parameters from both the path item level and the operation level.
    /// If duplicate parameters exist, only the parameters from the operation level are preserved.
    ///
    /// - Returns: An array of merged path item and operation level parameters without duplicates.
    /// - Throws: When an invalid JSON reference is found.
    var allParameters: [UnresolvedParameter] {
        get throws {
            var mergedParameters: [UnresolvedParameter] = []
            var uniqueIdentifiers: Set<String> = []

            let allParameters = pathParameters + operation.parameters
            for parameter in allParameters.reversed() {
                let resolvedParameter = try parameter.resolve(in: components)
                let identifier = resolvedParameter.location.rawValue + ":" + resolvedParameter.name

                guard !uniqueIdentifiers.contains(identifier) else {
                    continue
                }

                mergedParameters.append(parameter)
                uniqueIdentifiers.insert(identifier)
            }

            return mergedParameters.reversed()
        }
    }

    /// Returns all parameters by resolving any parameter references first.
    ///
    /// - Throws: When an invalid JSON reference is found.
    var allResolvedParameters: [OpenAPI.Parameter] {
        get throws {
            try allParameters.map { try $0.resolve(in: components) }
        }
    }

    /// Returns the path parameters from both the path item level and the
    /// operation level.
    var allPathParameters: [UnresolvedParameter] {
        get throws {
            try allParameters.filter { (try $0.resolve(in: components).location) == .path }
        }
    }

    /// Returns the query parameters from both the path item level and the
    /// operation level.
    var allQueryParameters: [UnresolvedParameter] {
        get throws {
            try allParameters.filter { (try $0.resolve(in: components).location) == .query }
        }
    }

    /// Returns the header parameters from both the path item level and the
    /// operation level.
    var allHeaderParameters: [UnresolvedParameter] {
        get throws {
            try allParameters.filter { (try $0.resolve(in: components).location) == .header }
        }
    }

    /// Returns the cookie parameters from both the path item level and the
    /// operation level.
    var allCookieParameters: [UnresolvedParameter] {
        get throws {
            try allParameters.filter { (try $0.resolve(in: components).location) == .cookie }
        }
    }

    /// Returns a string representing the JSON path to the operation object.
    var jsonPathComponent: String {
        [
            "#",
            "paths",
            path.rawValue,
            endpoint.method.rawValue.lowercased() + (operation.operationId.flatMap { "(\($0))" } ?? ""),
        ]
        .joined(separator: "/")
    }

    /// Returns the type name of the response struct for the specified kind.
    func responseStructTypeName(for responseKind: ResponseKind) -> TypeName {
        responseKind.typeName(in: outputTypeName)
    }

    /// Returns the signature of the function representing the OpenAPI operation
    /// in the API protocol.
    var protocolSignatureDescription: FunctionSignatureDescription {
        .init(
            // Do not respect the access modifier here, as this is a protocol
            // declaration, so we don't put `public` on methods, only on the
            // protocol itself.
            accessModifier: nil,
            kind: .function(name: methodName),
            parameters: [
                .init(
                    name: Constants.Operation.Input.variableName,
                    type: inputTypeName.fullyQualifiedSwiftName
                )
            ],
            keywords: [.async, .throws],
            returnType: .identifier(outputTypeName.fullyQualifiedSwiftName)
        )
    }

    /// Returns the signature of the function representing the OpenAPI operation
    /// in the generated server stubs.
    var serverImplSignatureDescription: FunctionSignatureDescription {
        .init(
            accessModifier: nil,
            kind: .function(name: methodName),
            parameters: [
                .init(label: "request", type: "HTTPRequest"),
                .init(label: "body", type: "HTTPBody?"),
                .init(label: "metadata", type: "ServerRequestMetadata"),
            ],
            keywords: [.async, .throws],
            returnType: .tuple([.identifier("HTTPResponse"), .identifier("HTTPBody?")])
        )
    }

    /// Returns a string that contains the template to be generated for
    /// the client that fills in path parameters, and an array expression
    /// with the parameter values.
    ///
    /// For example, `/cats/{}` and `[input.catId]`.
    var templatedPathForClient: (String, Expression) {
        get throws {
            let path = self.path.rawValue
            let pathParameters = try allResolvedParameters.filter { $0.location == .path }
            // replace "{foo}" with "{}" for each parameter
            let template = pathParameters.reduce(into: path) { partialResult, parameter in
                partialResult = partialResult.replacingOccurrences(
                    of: "{\(parameter.name)}",
                    with: "{}"
                )
            }
            let names: [Expression] =
                pathParameters
                .map { param in
                    .identifier("input.path.\(asSwiftSafeName(param.name))")
                }
            let arrayExpr: Expression = .literal(.array(names))
            return (template, arrayExpr)
        }
    }

    /// A Boolean value that indicates whether the operation defines
    /// a default response.
    var containsDefaultResponse: Bool {
        operation.responses.contains(key: .default)
    }

    /// Returns the operation.responseOutcomes while ensuring if a `.default`
    /// responseOutcome is present, then it is the last element in the returned array
    var responseOutcomes: [OpenAPI.Operation.ResponseOutcome] {
        var outcomes = operation.responseOutcomes
        // if .default is present and not already last
        if let index = outcomes.firstIndex(where: { $0.status == .default }), index != (outcomes.count - 1) {
            //then we move it to be last
            let defaultResp = outcomes.remove(at: index)
            outcomes.append(defaultResp)
        }
        return outcomes
    }
}
