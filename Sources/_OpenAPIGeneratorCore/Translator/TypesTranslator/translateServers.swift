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
    /// Returns a declaration of a server URL static function defined in
    /// the OpenAPI document using the supplied name identifier and
    /// variable generators.
    ///
    /// If the `deprecated` parameter is supplied the static function
    /// will be generated with a name that matches the previous, now
    /// deprecated API.
    ///
    /// - Important: The variable generators provided should all
    /// be ``RawStringTranslatedServerVariable`` to ensure
    /// the generated function matches the previous implementation, this
    /// is **not** asserted by this translate function.
    ///
    /// If the `deprecated` parameter is `nil` then the function will
    /// be generated with the identifier `url` and must be a member
    /// of a namespace to avoid conflicts with other server URL static
    /// functions.
    ///
    /// - Parameters:
    ///   - index: The index of the server in the list of servers defined
    ///   in the OpenAPI document.
    ///   - server: The server URL information.
    ///   - deprecated: A deprecation `@available` annotation to attach
    ///   to this declaration, or `nil` if the declaration should not be deprecated.
    ///   - variables: The generators for variables the server has defined.
    /// - Returns: A static method declaration, and a name for the variable to
    /// declare the method under.
    private func translateServerStaticFunction(
        index: Int,
        server: OpenAPI.Server,
        deprecated: DeprecationDescription?,
        variableGenerators variables: [any ServerVariableGenerator]
    ) -> Declaration {
        let name =
            deprecated == nil ? Constants.ServerURL.urlStaticFunc : "\(Constants.ServerURL.propertyPrefix)\(index + 1)"
        return .commentable(
            .functionComment(abstract: server.description, parameters: variables.map(\.functionComment)),
            .function(
                accessModifier: config.access,
                kind: .function(name: name, isStatic: true),
                parameters: variables.map(\.parameter),
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
                                    ),
                                    .init(
                                        label: "variables",
                                        expression: .literal(.array(variables.map(\.initializer)))
                                    ),
                                ])
                        )
                    )
                ]
            )
            .deprecate(if: deprecated)
        )
    }

    /// Returns a declaration of a server URL static function defined in
    /// the OpenAPI document. The function is marked as deprecated
    /// with a message informing the adopter to use the new type-safe
    /// API.
    /// - Parameters:
    ///   - index: The index of the server in the list of servers defined
    ///   in the OpenAPI document.
    ///   - server: The server URL information.
    ///   - pathToReplacementSymbol: The Swift path of the symbol
    ///   which has resulted in the deprecation of this symbol.
    /// - Returns: A static function declaration.
    func translateServerAsDeprecated(index: Int, server: OpenAPI.Server, renamedTo pathToReplacementSymbol: String)
        -> Declaration
    {
        let serverVariables = translateServerVariables(index: index, server: server, generateAsEnum: false)
        return translateServerStaticFunction(
            index: index,
            server: server,
            deprecated: DeprecationDescription(renamed: pathToReplacementSymbol),
            variableGenerators: serverVariables
        )
    }

    /// Returns a namespace (enum) declaration for a server defined in
    /// the OpenAPI document. Within the namespace are enums to
    /// represent any variables that also have enum values defined in the
    /// OpenAPI document, and a single static function named 'url' which
    /// at runtime returns the resolved server URL.
    ///
    /// The server's namespace is named to identify the human-friendly
    /// index of the enum (e.g. Server1) and is present to ensure each
    /// server definition's variables do not conflict with one another.
    /// - Parameters:
    ///   - index: The index of the server in the list of servers defined
    ///   in the OpenAPI document.
    ///   - server: The server URL information.
    /// - Returns: A static function declaration.
    func translateServer(index: Int, server: OpenAPI.Server) -> (pathToStaticFunction: String, decl: Declaration) {
        let serverVariables = translateServerVariables(index: index, server: server, generateAsEnum: true)
        let methodDecl = translateServerStaticFunction(
            index: index,
            server: server,
            deprecated: nil,
            variableGenerators: serverVariables
        )
        let namespaceName = "\(Constants.ServerURL.serverNamespacePrefix)\(index + 1)"
        let typeName = TypeName(swiftKeyPath: [
            Constants.ServerURL.namespace, namespaceName, Constants.ServerURL.urlStaticFunc,
        ])
        let decl = Declaration.commentable(
            server.description.map(Comment.doc(_:)),
            .enum(
                accessModifier: config.access,
                name: namespaceName,
                members: serverVariables.compactMap(\.declaration) + CollectionOfOne(methodDecl)
            )
        )
        return (pathToStaticFunction: typeName.fullyQualifiedSwiftName, decl: decl)
    }

    /// Returns a declaration of a namespace (enum) called "Servers" that
    /// defines one static method for each server URL defined in the OpenAPI
    /// document.
    /// - Parameter servers: The servers to include in the extension.
    /// - Returns: A declaration of an enum namespace of the server URLs type.
    func translateServers(_ servers: [OpenAPI.Server]) -> Declaration {
        var serverDecls: [Declaration] = []
        for (index, server) in servers.enumerated() {
            let translatedServer = translateServer(index: index, server: server)
            serverDecls.append(contentsOf: [
                translatedServer.decl,
                translateServerAsDeprecated(
                    index: index,
                    server: server,
                    renamedTo: translatedServer.pathToStaticFunction
                ),
            ])
        }
        return .commentable(
            .doc("Server URLs defined in the OpenAPI document."),
            .enum(accessModifier: config.access, name: Constants.ServerURL.namespace, members: serverDecls)
        )
    }
}
