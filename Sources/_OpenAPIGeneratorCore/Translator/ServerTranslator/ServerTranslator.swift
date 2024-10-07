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

    func translateFile(parsedOpenAPI: ParsedOpenAPIRepresentation) throws -> StructuredSwiftRepresentation {

        let doc = parsedOpenAPI

        let topComment: Comment = .inline(Constants.File.topComment)

        let imports =
            Constants.File.clientServerImports + config.additionalImports.map { ImportDescription(moduleName: $0) }

        let allOperations = try OperationDescription.all(from: doc.paths, in: components, context: context)

        let (registerHandlersDecl, serverMethodDecls) = try translateRegisterHandlers(allOperations)

        let protocolExtensionDecl: Declaration = .extension(
            accessModifier: nil,
            onType: Constants.APIProtocol.typeName,
            declarations: [registerHandlersDecl]
        )

        let serverExtensionDecl: Declaration = .extension(
            accessModifier: .fileprivate,
            onType: Constants.Server.Universal.typeName,
            whereClause: .init(requirements: [
                .conformance(Constants.Server.Universal.apiHandlerName, Constants.APIProtocol.typeName)
            ]),
            declarations: serverMethodDecls
        )

        return StructuredSwiftRepresentation(
            file: .init(
                name: GeneratorMode.server.outputFileName,
                contents: .init(
                    topComment: topComment,
                    imports: imports,
                    codeBlocks: [.declaration(protocolExtensionDecl), .declaration(serverExtensionDecl)]
                )
            )
        )
    }

    /// Returns a declaration of the registerHandlers method and
    /// the declarations of the individual operation methods.
    /// - Parameter operations: The operations found in the OpenAPI document.
    /// - Returns: A tuple containing the declaration of the `registerHandlers` method and
    ///            an array of operation method declarations.
    /// - Throws: An error if there is an issue while generating the registration code.
    func translateRegisterHandlers(_ operations: [OperationDescription]) throws -> (Declaration, [Declaration]) {
        var registerHandlersDeclBody: [CodeBlock] = []
        let serverMethodDeclPairs = try operations.map { operation in
            try translateServerMethod(operation, serverUrlVariableName: "server")
        }
        let serverMethodDecls = serverMethodDeclPairs.map(\.functionDecl)

        // To avoid an unused variable warning, we add the server variable declaration
        // and server method register calls to the body of the register handler declaration
        // only when there is at least one registration call.
        if !serverMethodDeclPairs.isEmpty {
            let serverMethodRegisterCalls = serverMethodDeclPairs.map(\.registerCall)
            let registerHandlerServerVarDecl: Declaration = .variable(
                kind: .let,
                left: "server",
                right: .identifierType(.member(Constants.Server.Universal.typeName))
                    .call([
                        .init(label: "serverURL", expression: .identifierPattern("serverURL")),
                        .init(label: "handler", expression: .identifierPattern("self")),
                        .init(label: "configuration", expression: .identifierPattern("configuration")),
                        .init(label: "middlewares", expression: .identifierPattern("middlewares")),
                    ])
            )

            registerHandlersDeclBody.append(.declaration(registerHandlerServerVarDecl))
            registerHandlersDeclBody.append(contentsOf: serverMethodRegisterCalls.map { .expression($0) })
        }

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
                    .init(label: "on", name: "transport", type: .member(Constants.Server.Transport.typeName)),
                    .init(label: "serverURL", type: .init(TypeName.url), defaultValue: .dot("defaultOpenAPIServerURL")),
                    .init(
                        label: "configuration",
                        type: .member(Constants.Configuration.typeName),
                        defaultValue: .dot("init").call([])
                    ),
                    .init(
                        label: "middlewares",
                        type: .array(.member(Constants.Server.Middleware.typeName)),
                        defaultValue: .literal(.array([]))
                    ),
                ],
                keywords: [.throws],
                body: registerHandlersDeclBody
            )
        )
        return (registerHandlersDecl, serverMethodDecls)
    }
}
