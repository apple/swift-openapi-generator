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

/// A translator for the generated common types.
///
/// Types.swift is the Swift file containing all the reusable types from
/// the "Components" section in the OpenAPI document, as well as all of the
/// namespaces for each OpenAPI operation, including their Input and Output
/// types.
///
/// Types generated in this file are depended on by both Client.swift and
/// Server.swift.
struct TypesFileTranslator: FileTranslator {

    var config: Config
    var diagnostics: any DiagnosticCollector
    var components: OpenAPI.Components

    func translateFile(parsedOpenAPI: ParsedOpenAPIRepresentation) throws -> StructuredSwiftRepresentation {

        let doc = parsedOpenAPI

        let topComment = self.topComment

        let imports = importDescriptions(adding: Constants.File.imports)
        // Splitting can leave individual files with imports unused by that file, which Swift diagnoses for public imports.
        let splitFileImports = imports.map { importDescription in
            var importDescription = importDescription
            importDescription.accessModifier = nil
            return importDescription
        }

        let apiProtocol = try translateAPIProtocol(doc.paths)

        let apiProtocolExtension = try translateAPIProtocolExtension(doc.paths)

        let serversDecl = translateServers(doc.servers)

        let multipartSchemaNames = try parseSchemaNamesUsedInMultipart(paths: doc.paths, components: doc.components)
        let componentNamespaces = try translateComponentNamespaceDescriptions(
            doc.components,
            multipartSchemaNames: multipartSchemaNames
        )

        let operationDescriptions = try OperationDescription.all(from: doc.paths, in: doc.components, context: context)
        let operations = try translateOperations(operationDescriptions)

        let rootCodeBlocks: [CodeBlock] = [
            .declaration(apiProtocol), .declaration(apiProtocolExtension), .declaration(serversDecl),
        ]
        let fileNames = GeneratorMode.types.outputFileNames
        let componentsRoot = CodeBlock.declaration(
            .commentable(
                .doc(
                    """
                    Types generated from the components section of the OpenAPI document.
                    """
                ),
                .enum(.init(accessModifier: config.access, name: Constants.Components.namespace, members: []))
            )
        )
        let componentNamespaceFiles: [NamedFileDescription] = componentNamespaces.map { namespace in
            let fileName = GeneratorMode.outputFileName(
                GeneratorMode.types.outputFileName,
                Constants.Components.namespace,
                namespace.fileNameSuffix
            )
            return .init(
                name: fileName,
                contents: .init(
                    topComment: topComment,
                    imports: splitFileImports,
                    codeBlocks: [
                        .declaration(
                            .extension(
                                accessModifier: nil,
                                onType: Constants.Components.namespace,
                                declarations: [namespace.declaration]
                            )
                        )
                    ]
                )
            )
        }
        return StructuredSwiftRepresentation(
            files: [
                .init(
                    name: fileNames[0],
                    contents: .init(topComment: topComment, imports: splitFileImports, codeBlocks: rootCodeBlocks)
                ),
                .init(
                    name: fileNames[1],
                    contents: .init(topComment: topComment, imports: splitFileImports, codeBlocks: [componentsRoot])
                ),
                .init(
                    name: fileNames[2],
                    contents: .init(topComment: topComment, imports: splitFileImports, codeBlocks: [operations])
                ),
            ] + componentNamespaceFiles
        )
    }
}
