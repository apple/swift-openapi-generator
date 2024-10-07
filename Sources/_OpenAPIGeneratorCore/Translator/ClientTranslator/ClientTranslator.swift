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

/// A translator for the generated client.
///
/// Client.swift is the Swift file containing a Client struct
/// that implements APIProtocol by calling out to its ClientTransport to
/// perform HTTP operations.
///
/// Only includes the Client struct.
///
/// Depends on types defined in Types.swift.
struct ClientFileTranslator: FileTranslator {

    var config: Config
    var diagnostics: any DiagnosticCollector
    var components: OpenAPI.Components

    func translateFile(parsedOpenAPI: ParsedOpenAPIRepresentation) throws -> StructuredSwiftRepresentation {

        let doc = parsedOpenAPI

        let topComment: Comment = .inline(Constants.File.topComment)

        let imports =
            Constants.File.clientServerImports + config.additionalImports.map { ImportDescription(moduleName: $0) }

        let clientMethodDecls = try OperationDescription.all(from: doc.paths, in: components, context: context)
            .map(translateClientMethod(_:))

        let clientStructPropertyDecl: Declaration = .commentable(
            .doc("The underlying HTTP client."),
            .variable(
                accessModifier: .private,
                kind: .let,
                left: Constants.Client.Universal.propertyName,
                type: .member(Constants.Client.Universal.typeName)
            )
        )

        let clientStructInitDecl: Declaration = .commentable(
            .doc(
                #"""
                Creates a new client.
                - Parameters:
                  - serverURL: The server URL that the client connects to. Any server
                  URLs defined in the OpenAPI document are available as static methods
                  on the ``Servers`` type.
                  - configuration: A set of configuration values for the client.
                  - transport: A transport that performs HTTP operations.
                  - middlewares: A list of middlewares to call before the transport.
                """#
            ),
            .function(
                accessModifier: config.access,
                kind: .initializer,
                parameters: [
                    .init(label: "serverURL", type: .init(TypeName.url)),
                    .init(
                        label: "configuration",
                        type: .member(Constants.Configuration.typeName),
                        defaultValue: .dot("init").call([])
                    ), .init(label: "transport", type: .member(Constants.Client.Transport.typeName)),
                    .init(
                        label: "middlewares",
                        type: .array(.member(Constants.Client.Middleware.typeName)),
                        defaultValue: .literal(.array([]))
                    ),
                ],
                body: [
                    .expression(
                        .assignment(
                            left: .identifierPattern("self").dot(Constants.Client.Universal.propertyName),
                            right: .dot("init")
                                .call([
                                    .init(label: "serverURL", expression: .identifierPattern("serverURL")),
                                    .init(label: "configuration", expression: .identifierPattern("configuration")),
                                    .init(label: "transport", expression: .identifierPattern("transport")),
                                    .init(label: "middlewares", expression: .identifierPattern("middlewares")),
                                ])
                        )
                    )
                ]
            )
        )

        let clientStructConverterPropertyDecl: Declaration = .variable(
            accessModifier: .private,
            kind: .var,
            left: "converter",
            type: .member(Constants.Converter.typeName),
            getter: [.expression(.identifierPattern(Constants.Client.Universal.propertyName).dot("converter"))]
        )

        let clientStructDecl: Declaration = .commentable(
            parsedOpenAPI.info.description.flatMap { .doc($0) },
            .struct(
                .init(
                    accessModifier: config.access,
                    name: Constants.Client.typeName,
                    conformances: [Constants.APIProtocol.typeName],
                    members: [clientStructPropertyDecl, clientStructInitDecl, clientStructConverterPropertyDecl]
                        + clientMethodDecls
                )
            )
        )

        return StructuredSwiftRepresentation(
            file: .init(
                name: GeneratorMode.client.outputFileName,
                contents: .init(topComment: topComment, imports: imports, codeBlocks: [.declaration(clientStructDecl)])
            )
        )
    }
}
