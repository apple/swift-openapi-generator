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
    func translateServer(
        index: Int,
        server: OpenAPI.Server
    ) -> Declaration {
        let methodName = "\(Constants.ServerURL.propertyPrefix)\(index+1)"
        let methodDecl = Declaration.commentable(
            server.description.flatMap { .doc($0) },
            .function(
                accessModifier: config.access,
                kind: .function(name: methodName, isStatic: true),
                parameters: [],
                keywords: [
                    .throws
                ],
                returnType: Constants.ServerURL.underlyingType,
                body: [
                    .expression(
                        .try(
                            .identifier(Constants.ServerURL.underlyingType)
                                .call([
                                    .init(
                                        label: "validatingOpenAPIServerURL",
                                        expression: .literal(
                                            .string(
                                                server.urlTemplate.absoluteString
                                            )
                                        )
                                    )
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
            .enum(
                accessModifier: config.access,
                name: Constants.ServerURL.namespace,
                members: serverDecls
            )
        )
    }
}
