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
import Algorithms
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

        let maxDeclarationsPerFile = config.maxDeclarationsPerFile
        if let maxDeclarationsPerFile, maxDeclarationsPerFile <= 0 {
            throw GenericError(message: "Expected output.maxDeclarationsPerFile to be greater than zero.")
        }

        let topComment = self.topComment

        let imports = importDescriptions(adding: Constants.File.imports)

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
        if maxDeclarationsPerFile == nil {
            let rootCodeBlocks: [CodeBlock] = [
                .declaration(apiProtocol), .declaration(apiProtocolExtension), .declaration(serversDecl),
            ]
            let componentNamespaceFiles: [NamedFileDescription] = componentNamespaces.map { namespace in
                .init(
                    name: namespace.outputFile.rawValue,
                    contents: .init(
                        topComment: topComment,
                        imports: imports,
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
                        name: OutputFileName.types.rawValue,
                        contents: .init(topComment: topComment, imports: imports, codeBlocks: rootCodeBlocks)
                    ),
                    .init(
                        name: OutputFileName.typesComponents.rawValue,
                        contents: .init(topComment: topComment, imports: imports, codeBlocks: [componentsRoot])
                    ),
                    .init(
                        name: OutputFileName.typesOperations.rawValue,
                        contents: .init(topComment: topComment, imports: imports, codeBlocks: [operations])
                    ),
                ] + componentNamespaceFiles
            )
        }

        typealias Namespace = (path: [String], baseFileName: String, comment: Comment?, declarations: [Declaration])
        let namespaces: [Namespace] =
            [
                (
                    path: [Constants.Operations.namespace], baseFileName: OutputFileName.typesOperations.rawValue,
                    comment: operations.comment, declarations: operations.namespaceDeclarations
                )
            ]
            + componentNamespaces.map { namespace in
                let contents = namespace.declaration.namespaceContents
                return (
                    path: [Constants.Components.namespace, contents.name], baseFileName: namespace.outputFile.rawValue,
                    comment: contents.comment, declarations: contents.declarations
                )
            }

        func namespaceRoot(for namespace: Namespace) -> Declaration {
            (.commentable(
                namespace.comment,
                .enum(.init(accessModifier: config.access, name: namespace.path.last!, members: []))
            ))
        }

        let typesRoot: [CodeBlock] =
            [.declaration(apiProtocol), .declaration(apiProtocolExtension), .declaration(serversDecl), componentsRoot]
            + namespaces.filter { $0.path.count == 1 }.map { .declaration(namespaceRoot(for: $0)) }
        let componentNamespacesRoot = CodeBlock.declaration(
            .extension(
                accessModifier: nil,
                onType: Constants.Components.namespace,
                declarations: namespaces.filter { $0.path.dropLast() == [Constants.Components.namespace] }
                    .map(namespaceRoot)
            )
        )
        let namespaceFiles = namespaces.flatMap { namespace in
            splitFiles(
                for: namespace.declarations,
                extending: namespace.path.joined(separator: "."),
                baseFileName: namespace.baseFileName
            )
        }

        func splitFiles(for declarations: [Declaration], extending namespace: String, baseFileName: String)
            -> [NamedFileDescription]
        {
            let declarationChunks =
                maxDeclarationsPerFile.map { declarations.chunks(ofCount: $0).map(Array.init) } ?? [declarations]
            // Preserve the unsuffixed namespace file even when there are no declarations.
            return (declarationChunks.isEmpty ? [declarations] : declarationChunks).enumerated()
                .map { splitIndex, declarations in
                    NamedFileDescription(
                        name: splitIndex == 0 ? baseFileName : baseFileName.appendingFileNameSuffix(String(splitIndex)),
                        contents: .init(
                            topComment: topComment,
                            imports: imports,
                            codeBlocks: [
                                .declaration(
                                    .extension(accessModifier: nil, onType: namespace, declarations: declarations)
                                )
                            ]
                        )
                    )
                }
        }

        return StructuredSwiftRepresentation(
            files: [
                .init(
                    name: OutputFileName.types.rawValue,
                    contents: .init(topComment: topComment, imports: imports, codeBlocks: typesRoot)
                ),
                .init(
                    name: OutputFileName.typesComponents.rawValue,
                    contents: .init(topComment: topComment, imports: imports, codeBlocks: [componentNamespacesRoot])
                ),
            ] + namespaceFiles
        )
    }
}

extension String {
    /// Returns a Swift file name with the provided suffix appended before the extension.
    fileprivate func appendingFileNameSuffix(_ suffix: String) -> String {
        hasSuffix(".swift") ? "\(dropLast(".swift".count))+\(suffix).swift" : "\(self)+\(suffix).swift"
    }
}

extension Declaration {
    /// Returns a component namespace's comment and the declarations to emit in extension files.
    fileprivate var namespaceContents: (name: String, comment: Comment?, declarations: [Declaration]) {
        guard case .commentable(let comment, .enum(let description)) = self else {
            preconditionFailure("Expected a commented enum namespace declaration.")
        }
        return (description.name, comment, description.members)
    }
}

extension CodeBlock {
    /// Returns the operation declarations to emit in extension files.
    fileprivate var namespaceDeclarations: [Declaration] {
        guard case .declaration(.enum(let description)) = item else {
            preconditionFailure("Expected an enum namespace declaration code block.")
        }
        return description.members
    }
}
