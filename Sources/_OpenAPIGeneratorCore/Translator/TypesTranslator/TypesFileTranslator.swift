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

        let maxDeclarationsPerFile = config.maxDeclarationsPerFile
        if let maxDeclarationsPerFile, maxDeclarationsPerFile <= 0 {
            throw GenericError(message: "Expected output.maxDeclarationsPerFile to be greater than zero.")
        }
        let dependencyLayerCount = config.dependencyLayerCount
        if let dependencyLayerCount, dependencyLayerCount <= 0 {
            throw GenericError(message: "Expected output.dependencyLayerCount to be greater than zero.")
        }

        let topComment = self.topComment

        let imports = importDescriptions(adding: Constants.File.imports)

        let apiProtocol = try translateAPIProtocol(doc.paths)

        let apiProtocolExtension = try translateAPIProtocolExtension(doc.paths)

        let serversDecl = translateServers(doc.servers)

        let multipartSchemaNames = try parseSchemaNamesUsedInMultipart(paths: doc.paths, components: doc.components)
        let operationDescriptions = try OperationDescription.all(from: doc.paths, in: doc.components, context: context)
        if let dependencyLayerCount {
            return try translateDependencyLayeredFile(
                doc: doc,
                topComment: topComment,
                imports: imports,
                apiProtocol: apiProtocol,
                apiProtocolExtension: apiProtocolExtension,
                serversDecl: serversDecl,
                multipartSchemaNames: multipartSchemaNames,
                operationDescriptions: operationDescriptions,
                requestedLayerCount: dependencyLayerCount
            )
        }

        let componentNamespaces = try translateComponentNamespaceDescriptions(
            doc.components,
            multipartSchemaNames: multipartSchemaNames
        )
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
            makeSplitFiles(
                for: namespace.declarations.map { [$0] },
                extending: namespace.path.joined(separator: "."),
                baseFileName: namespace.baseFileName,
                role: namespace.path.joined(separator: "."),
                dependencyLayer: nil,
                preserveEmptyFile: true,
                topComment: topComment,
                imports: imports,
                maxDeclarationsPerFile: maxDeclarationsPerFile
            )
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

    private func translateDependencyLayeredFile(
        doc: ParsedOpenAPIRepresentation,
        topComment: Comment,
        imports: [ImportDescription],
        apiProtocol: Declaration,
        apiProtocolExtension: Declaration,
        serversDecl: Declaration,
        multipartSchemaNames: Set<OpenAPI.ComponentKey>,
        operationDescriptions: [OperationDescription],
        requestedLayerCount: Int
    ) throws -> StructuredSwiftRepresentation {
        let graph = SchemaDependencyGraph.build(from: doc.components.schemas)
        let layerBySchema = graph.mappedLayers(requestedLayerCount: requestedLayerCount)

        let schemaGroups = try translateSchemaDeclarationGroups(
            doc.components.schemas,
            multipartSchemaNames: multipartSchemaNames
        )
        let schemaGroupsByOwner = Dictionary(uniqueKeysWithValues: schemaGroups.map { ($0.owner, $0.declarations) })
        let generatedSchemaOwners = Set(schemaGroups.filter { !$0.declarations.isEmpty }.map(\.owner))
        func generatedSchemaReferences(_ references: Set<String>) -> Set<String> {
            references.intersection(generatedSchemaOwners)
        }
        let schemaLayerGroups: [Int: [PlannedDeclarationGroup]] = Dictionary(
            grouping: graph.stronglyConnectedComponents
        ) { component in component.compactMap { layerBySchema[$0] }.max() ?? 0 }
        .mapValues { components in
            components.map { component in
                let owners = component.filter { generatedSchemaOwners.contains($0) }.sorted()
                return PlannedDeclarationGroup(
                    declarations: owners.flatMap { schemaGroupsByOwner[$0] ?? [] },
                    owners: owners,
                    schemaDependencies: generatedSchemaReferences(
                        Set(
                            owners.flatMap { owner in
                                config.typeOverrides.schemas[owner] == nil ? graph.edges[owner] ?? [] : []
                            }
                        )
                    ),
                    componentDependencies: []
                )
            }
        }

        let resolvedParameters = try doc.components.parameters.mapValues { try doc.components.assumeLookupOnce($0) }
        let resolvedRequestBodies = try doc.components.requestBodies.mapValues {
            try doc.components.assumeLookupOnce($0)
        }
        let resolvedResponses = try doc.components.responses.mapValues { try doc.components.assumeLookupOnce($0) }
        let resolvedHeaders = try doc.components.headers.mapValues {
            (header: Either<OpenAPI.Reference<OpenAPI.Header>, OpenAPI.Header>) in
            try doc.components.assumeLookupOnce(header)
        }

        func highestLayer(for references: Set<String>) -> Int { references.compactMap { layerBySchema[$0] }.max() ?? 0 }

        var generatedReusableComponentOwners: Set<String> = []
        func groupsByLayer<Component>(
            _ groups: [OwnedDeclarations],
            components: OpenAPI.ComponentDictionary<Component>,
            references: (Component) -> Set<String>,
            componentKind: String,
            componentReferences: (Component) -> Set<String> = { _ in [] }
        ) -> [Int: [PlannedDeclarationGroup]] {
            var result: [Int: [PlannedDeclarationGroup]] = [:]
            for group in groups {
                guard !group.declarations.isEmpty else { continue }
                guard let key = OpenAPI.ComponentKey(rawValue: group.owner), let component = components[key] else {
                    continue
                }
                let schemaReferences = references(component)
                result[highestLayer(for: schemaReferences), default: []]
                    .append(
                        .init(
                            declarations: group.declarations,
                            owners: ["\(componentKind):\(group.owner)"],
                            schemaDependencies: generatedSchemaReferences(schemaReferences),
                            componentDependencies: componentReferences(component)
                                .intersection(generatedReusableComponentOwners)
                        )
                    )
            }
            return result
        }

        let parameterGroups = try translateComponentParameterDeclarationGroups(resolvedParameters)
        let requestBodyGroups = try translateComponentRequestBodyDeclarationGroups(resolvedRequestBodies)
        let responseGroups = try translateComponentResponseDeclarationGroups(resolvedResponses)
        let headerGroups = try translateComponentHeaderDeclarationGroups(resolvedHeaders)
        generatedReusableComponentOwners = Set(
            [
                ("parameter", parameterGroups), ("requestBody", requestBodyGroups), ("response", responseGroups),
                ("header", headerGroups),
            ]
            .flatMap { kind, groups in groups.filter { !$0.declarations.isEmpty }.map { "\(kind):\($0.owner)" } }
        )

        var operationGroupsByLayer: [Int: [PlannedDeclarationGroup]] = [:]
        for description in operationDescriptions {
            let schemaReferences = SchemaDependencyGraph.schemaReferences(in: description)
            let layer = highestLayer(for: schemaReferences)
            operationGroupsByLayer[layer, default: []]
                .append(
                    .init(
                        declarations: [try translateOperation(description)],
                        owners: [description.operationID],
                        schemaDependencies: generatedSchemaReferences(schemaReferences),
                        componentDependencies: SchemaDependencyGraph.componentReferences(in: description)
                            .intersection(generatedReusableComponentOwners)
                    )
                )
        }

        let componentsRoot = CodeBlock.declaration(
            .commentable(
                .doc("Types generated from the components section of the OpenAPI document."),
                .enum(.init(accessModifier: config.access, name: Constants.Components.namespace, members: []))
            )
        )
        let namespaces: [(name: String, comment: Comment?)] = [
            (Constants.Components.Schemas.namespace, JSONSchema.sectionComment()),
            (Constants.Components.Parameters.namespace, OpenAPI.Parameter.sectionComment()),
            (Constants.Components.RequestBodies.namespace, OpenAPI.Request.sectionComment()),
            (Constants.Components.Responses.namespace, OpenAPI.Response.sectionComment()),
            (Constants.Components.Headers.namespace, OpenAPI.Header.sectionComment()),
        ]
        let componentNamespacesRoot = CodeBlock.declaration(
            .extension(
                accessModifier: nil,
                onType: Constants.Components.namespace,
                declarations: namespaces.map { namespace in
                    .commentable(
                        namespace.comment,
                        .enum(.init(accessModifier: config.access, name: namespace.name, members: []))
                    )
                }
            )
        )
        let operationsRoot = CodeBlock.declaration(
            .commentable(
                .operationsNamespace(),
                .enum(.init(accessModifier: config.access, name: Constants.Operations.namespace, members: []))
            )
        )

        var files: [NamedFileDescription] = [
            .init(
                name: OutputFileName.types.rawValue,
                contents: .init(
                    topComment: topComment,
                    imports: imports,
                    codeBlocks: [
                        .declaration(apiProtocol), .declaration(apiProtocolExtension), .declaration(serversDecl),
                        componentsRoot, operationsRoot,
                    ]
                ),
                metadata: .init(
                    role: "typesRoot",
                    dependencyLayer: nil,
                    declarationChunk: nil,
                    declarations: ["APIProtocol", "Servers", "Components", "Operations"]
                )
            ),
            .init(
                name: OutputFileName.typesComponents.rawValue,
                contents: .init(topComment: topComment, imports: imports, codeBlocks: [componentNamespacesRoot]),
                metadata: .init(
                    role: "componentsRoot",
                    dependencyLayer: nil,
                    declarationChunk: nil,
                    namespace: "Components",
                    declarations: [
                        "Components.Schemas", "Components.Parameters", "Components.RequestBodies",
                        "Components.Responses", "Components.Headers",
                    ]
                )
            ),
        ]

        func appendLayerFiles(
            groupsByLayer: [Int: [PlannedDeclarationGroup]],
            namespace: String,
            baseFileName: String,
            role: String
        ) {
            for layer in groupsByLayer.keys.sorted() where !(groupsByLayer[layer] ?? []).flatMap(\.declarations).isEmpty
            {
                files += makePlannedSplitFiles(
                    for: groupsByLayer[layer] ?? [],
                    extending: namespace,
                    baseFileName: baseFileName.appendingFileNameSuffix("Layer\(layer)"),
                    role: role,
                    dependencyLayer: layer,
                    preserveEmptyFile: false,
                    topComment: topComment,
                    imports: imports,
                    maxDeclarationsPerFile: config.maxDeclarationsPerFile
                )
            }
        }

        appendLayerFiles(
            groupsByLayer: schemaLayerGroups,
            namespace: "Components.Schemas",
            baseFileName: OutputFileName.typesComponentsSchemas.rawValue,
            role: "schema"
        )
        appendLayerFiles(
            groupsByLayer: groupsByLayer(
                parameterGroups,
                components: resolvedParameters,
                references: { SchemaDependencyGraph.schemaReferences(in: $0, components: doc.components) },
                componentKind: "parameter"
            ),
            namespace: "Components.Parameters",
            baseFileName: OutputFileName.typesComponentsParameters.rawValue,
            role: "reusableComponent"
        )
        appendLayerFiles(
            groupsByLayer: groupsByLayer(
                requestBodyGroups,
                components: resolvedRequestBodies,
                references: { SchemaDependencyGraph.schemaReferences(in: $0, components: doc.components) },
                componentKind: "requestBody"
            ),
            namespace: "Components.RequestBodies",
            baseFileName: OutputFileName.typesComponentsRequestBodies.rawValue,
            role: "reusableComponent"
        )
        appendLayerFiles(
            groupsByLayer: groupsByLayer(
                responseGroups,
                components: resolvedResponses,
                references: { SchemaDependencyGraph.schemaReferences(in: $0, components: doc.components) },
                componentKind: "response",
                componentReferences: { SchemaDependencyGraph.componentReferences(in: $0) }
            ),
            namespace: "Components.Responses",
            baseFileName: OutputFileName.typesComponentsResponses.rawValue,
            role: "reusableComponent"
        )
        appendLayerFiles(
            groupsByLayer: groupsByLayer(
                headerGroups,
                components: resolvedHeaders,
                references: { SchemaDependencyGraph.schemaReferences(in: $0, components: doc.components) },
                componentKind: "header"
            ),
            namespace: "Components.Headers",
            baseFileName: OutputFileName.typesComponentsHeaders.rawValue,
            role: "reusableComponent"
        )
        appendLayerFiles(
            groupsByLayer: operationGroupsByLayer,
            namespace: Constants.Operations.namespace,
            baseFileName: OutputFileName.typesOperations.rawValue,
            role: "operation"
        )
        return .init(files: files)
    }

    private struct PlannedDeclarationGroup {
        var declarations: [Declaration]
        var owners: [String]
        var schemaDependencies: Set<String>
        var componentDependencies: Set<String>
    }

    private func makePlannedSplitFiles(
        for declarationGroups: [PlannedDeclarationGroup],
        extending namespace: String,
        baseFileName: String,
        role: String,
        dependencyLayer: Int?,
        preserveEmptyFile: Bool,
        topComment: Comment,
        imports: [ImportDescription],
        maxDeclarationsPerFile: Int?
    ) -> [NamedFileDescription] {
        let chunks: [[PlannedDeclarationGroup]]
        if let maxDeclarationsPerFile {
            var result: [[PlannedDeclarationGroup]] = []
            for group in declarationGroups {
                let declarationCount = group.declarations.count
                if let last = result.indices.last, !result[last].isEmpty,
                    result[last].reduce(0, { $0 + $1.declarations.count }) + declarationCount <= maxDeclarationsPerFile
                {
                    result[last].append(group)
                } else {
                    result.append([group])
                }
            }
            chunks = result
        } else {
            chunks = declarationGroups.isEmpty ? [] : [declarationGroups]
        }
        let emittedChunks = chunks.isEmpty && preserveEmptyFile ? [[]] : chunks
        return emittedChunks.enumerated()
            .map { splitIndex, groups in
                let declarations = groups.flatMap(\.declarations)
                return NamedFileDescription(
                    name: splitIndex == 0 ? baseFileName : baseFileName.appendingFileNameSuffix(String(splitIndex)),
                    contents: .init(
                        topComment: topComment,
                        imports: imports,
                        codeBlocks: [
                            .declaration(.extension(accessModifier: nil, onType: namespace, declarations: declarations))
                        ]
                    ),
                    metadata: .init(
                        role: role,
                        dependencyLayer: dependencyLayer,
                        declarationChunk: splitIndex,
                        namespace: namespace,
                        declarations: groups.flatMap(\.owners).sorted(),
                        schemaDependencies: Set(groups.flatMap(\.schemaDependencies)).sorted(),
                        componentDependencies: Set(groups.flatMap(\.componentDependencies)).sorted()
                    )
                )
            }
    }

    private func makeSplitFiles(
        for declarationGroups: [[Declaration]],
        extending namespace: String,
        baseFileName: String,
        role: String,
        dependencyLayer: Int?,
        preserveEmptyFile: Bool,
        topComment: Comment,
        imports: [ImportDescription],
        maxDeclarationsPerFile: Int?
    ) -> [NamedFileDescription] {
        let declarationChunks: [[Declaration]]
        if let maxDeclarationsPerFile {
            var chunks: [[Declaration]] = []
            for group in declarationGroups {
                if let last = chunks.indices.last, !chunks[last].isEmpty,
                    chunks[last].count + group.count <= maxDeclarationsPerFile
                {
                    chunks[last].append(contentsOf: group)
                } else {
                    chunks.append(group)
                }
            }
            declarationChunks = chunks
        } else {
            declarationChunks = declarationGroups.isEmpty ? [] : [declarationGroups.flatMap { $0 }]
        }
        let chunks = declarationChunks.isEmpty && preserveEmptyFile ? [[]] : declarationChunks
        return chunks.enumerated()
            .map { splitIndex, declarations in
                NamedFileDescription(
                    name: splitIndex == 0 ? baseFileName : baseFileName.appendingFileNameSuffix(String(splitIndex)),
                    contents: .init(
                        topComment: topComment,
                        imports: imports,
                        codeBlocks: [
                            .declaration(.extension(accessModifier: nil, onType: namespace, declarations: declarations))
                        ]
                    ),
                    metadata: .init(role: role, dependencyLayer: dependencyLayer, declarationChunk: splitIndex)
                )
            }
    }
}

extension String {
    /// Returns a Swift file name with the provided suffix appended before the extension.
    func appendingFileNameSuffix(_ suffix: String) -> String {
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
