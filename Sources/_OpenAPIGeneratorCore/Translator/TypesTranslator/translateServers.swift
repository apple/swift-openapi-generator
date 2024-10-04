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

    /// Returns a declaration of a server URL static method defined in
    /// the OpenAPI document.
    /// - Parameters:
    ///   - index: The index of the server in the list of servers defined
    ///   in the OpenAPI document.
    ///   - server: The server URL information.
    /// - Returns: A static method declaration, and a name for the variable to
    /// declare the method under.
    func translateServer(index: Int, server: OpenAPI.Server) -> Declaration {
        let methodName = "\(Constants.ServerURL.propertyPrefix)\(index+1)"
        let safeVariables = server.variables.map { (key, value) in
            (originalKey: key, swiftSafeKey: context.asSwiftSafeName(key), value: value)
        }
        let parameters: [ParameterDescription] = safeVariables.map { (originalKey, swiftSafeKey, value) in
            .init(label: swiftSafeKey, type: .init(TypeName.string), defaultValue: .literal(value.default))
        }
        let variableInitializers: [Expression] = safeVariables.map { (originalKey, swiftSafeKey, value) in
            let allowedValuesArg: FunctionArgumentDescription?
            if let allowedValues = value.enum {
                allowedValuesArg = .init(
                    label: "allowedValues",
                    expression: .literal(.array(allowedValues.map { .literal($0) }))
                )
            } else {
                allowedValuesArg = nil
            }
            return .dot("init")
                .call(
                    [
                        .init(label: "name", expression: .literal(originalKey)),
                        .init(label: "value", expression: .identifierPattern(swiftSafeKey)),
                    ] + (allowedValuesArg.flatMap { [$0] } ?? [])
                )
        }
        let methodDecl = Declaration.commentable(
            .functionComment(abstract: server.description, parameters: safeVariables.map { ($1, $2.description) }),
            .function(
                accessModifier: config.access,
                kind: .function(name: methodName, isStatic: true),
                parameters: parameters,
                keywords: [.throws],
                returnType: .identifierType(TypeName.url),
                body: [
                    .expression(
                        .try(
                            .identifierType(TypeName.url)
                                .call([
                                    .init(
                                        label: "validatingOpenAPIServerURL",
                                        expression: .literal(.string(server.urlTemplate.absoluteString))
                                    ), .init(label: "variables", expression: .literal(.array(variableInitializers))),
                                ])
                        )
                    )
                ]
            )
        )
        return methodDecl
    }

    /// Returns a declaration of a namespace (enum) called "Servers" that
    /// defines one static method for each server URL defined in the OpenAPI
    /// document.
    /// - Parameter servers: The servers to include in the extension.
    /// - Returns: A declaration of an enum namespace of the server URLs type.
    func translateServers(_ servers: [OpenAPI.Server]) -> Declaration {
        let serverDecls = servers.enumerated().map(translateServer)
        return .commentable(
            .doc("Server URLs defined in the OpenAPI document."),
            .enum(accessModifier: config.access, name: Constants.ServerURL.namespace, members: serverDecls)
        )
    }
}
