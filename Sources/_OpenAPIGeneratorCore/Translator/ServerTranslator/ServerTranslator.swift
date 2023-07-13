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

/// A translator for the generated server.
///
/// Server.swift is the Swift file containing an extension on the generated
/// APIProtocol that adds the generated server handler closures to
/// the provided ServerTransport.
///
/// Depends on types defined in Types.swift.
struct ServerFileTranslator: FileTranslator {

    var config: Config
    var diagnostics: any DiagnosticCollector
    var components: OpenAPI.Components

    func translateFile(
        parsedOpenAPI: ParsedOpenAPIRepresentation
    ) throws -> StructuredSwiftRepresentation {

        let doc = parsedOpenAPI

        let topComment: Comment = .inline(Constants.File.topComment)

        let imports =
            Constants.File.imports
            + config.additionalImports
            .map { ImportDescription(moduleName: $0) }

        let serverMethodDeclPairs =
            try OperationDescription
            .all(from: doc.paths, in: components)
            .map { operation in
                try translateServerMethod(operation, serverUrlVariableName: "server")
            }
        let serverMethodDecls = serverMethodDeclPairs.map(\.functionDecl)

        let serverMethodRegisterCalls = serverMethodDeclPairs.map(\.registerCall)

        let registerHandlerServerVarDecl: Declaration = .variable(
            kind: .let,
            left: "server",
            right: .identifier(Constants.Server.Universal.typeName)
                .call([
                    .init(label: "serverURL", expression: .identifier("serverURL")),
                    .init(label: "handler", expression: .identifier("self")),
                    .init(label: "configuration", expression: .identifier("configuration")),
                    .init(label: "middlewares", expression: .identifier("middlewares")),
                ])
        )
        let registerHandlersDecl: Declaration = .commentable(
            .doc(
                #"""
                Registers each operation handler with the provided transport.
                - Parameters:
                  - transport: A transport to which to register the operation handlers.
                  - serverURL: A URL used to determine the path prefix for registered
                  request handlers.
                  - configuration: A set of configuration values for the server.
                  - middlewares: A list of middlewares to call before the handler.
                """#
            ),
            .function(
                accessModifier: config.access,
                kind: .function(name: "registerHandlers"),
                parameters: [
                    .init(
                        label: "on",
                        name: "transport",
                        anyKeyword: true,
                        type: Constants.Server.Transport.typeName
                    ),
                    .init(
                        label: "serverURL",
                        type: "\(Constants.ServerURL.underlyingType)",
                        defaultValue: .dot("defaultOpenAPIServerURL")
                    ),
                    .init(
                        label: "configuration",
                        type: Constants.Configuration.typeName,
                        defaultValue: .dot("init").call([])
                    ),
                    .init(
                        label: "middlewares",
                        type: "[any \(Constants.Server.Middleware.typeName)]",
                        defaultValue: .literal(.array([]))
                    ),
                ],
                keywords: [
                    .throws
                ],
                body: [
                    .declaration(registerHandlerServerVarDecl)
                ] + serverMethodRegisterCalls.map { .expression($0) }
            )
        )

        let protocolExtensionDecl: Declaration = .extension(
            accessModifier: nil,
            onType: Constants.APIProtocol.typeName,
            declarations: [
                registerHandlersDecl
            ]
        )

        let serverExtensionDecl: Declaration = .extension(
            accessModifier: .fileprivate,
            onType: Constants.Server.Universal.typeName,
            whereClause: .init(requirements: [
                .conformance(
                    Constants.Server.Universal.apiHandlerName,
                    Constants.APIProtocol.typeName
                )
            ]),
            declarations: serverMethodDecls
        )

        return StructuredSwiftRepresentation(
            file: .init(
                name: GeneratorMode.server.outputFileName,
                contents: .init(
                    topComment: topComment,
                    imports: imports,
                    codeBlocks: [
                        .declaration(protocolExtensionDecl),
                        .declaration(serverExtensionDecl),
                    ]
                )
            )
        )
    }
}
