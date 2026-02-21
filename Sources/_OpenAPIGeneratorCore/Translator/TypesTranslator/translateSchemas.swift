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

private func typeLayerSuffix(layer: Int) -> String {
    "Types_L\(layer + 1)"
}

extension TypesFileTranslator {
    private func declarationNodeCount(_ declaration: Declaration) -> Int {
        switch declaration {
        case .commentable(_, let inner):
            return 1 + declarationNodeCount(inner)
        case .deprecated(_, let inner):
            return 1 + declarationNodeCount(inner)
        case .extension(let description):
            return 1 + description.declarations.map(declarationNodeCount).reduce(0, +)
        case .struct(let description):
            return 1 + description.members.map(declarationNodeCount).reduce(0, +)
        case .enum(let description):
            return 1 + description.members.map(declarationNodeCount).reduce(0, +)
        case .protocol(let description):
            return 1 + description.members.map(declarationNodeCount).reduce(0, +)
        case .variable,
             .typealias,
             .function,
             .enumCase:
            return 1
        }
    }

    private func declarationNodeCount(_ declarations: [Declaration]) -> Int {
        declarations.map(declarationNodeCount).reduce(0, +)
    }

    /// Returns a list of declarations for the provided schema, defined in the
    /// OpenAPI document under the specified component key.
    ///
    /// The last declaration is the type declaration for the schema.
    /// - Parameters:
    ///   - componentKey: The key for the schema, specified in the OpenAPI
    ///   document.
    ///   - schema: The schema to translate to a Swift type.
    ///   - isMultipartContent: A Boolean value indicating whether the schema defines multipart parts.
    /// - Returns: A list of declarations. Returns a single element in the list
    /// if only the type for the schema needs to be declared. Returns an empty
    /// list if the specified schema is unsupported. Returns multiple elements
    /// if the specified schema contains unnamed types that need to be declared
    /// inline.
    /// - Throws: An error if there is an issue during the matching process.
    func translateSchema(componentKey: OpenAPI.ComponentKey, schema: JSONSchema, isMultipartContent: Bool) throws
        -> [Declaration]
    {
        guard try validateSchemaIsSupported(schema, foundIn: "#/components/schemas/\(componentKey.rawValue)") else {
            return []
        }
        let typeName = typeAssigner.typeName(for: (componentKey, schema))
        return try translateSchema(
            typeName: typeName,
            schema: schema,
            overrides: .none,
            isMultipartContent: isMultipartContent
        )
    }

    /// Returns a declaration of the namespace that contains all the reusable
    /// schema definitions.
    /// - Parameters:
    ///   - schemas: The schemas from the OpenAPI document.
    ///   - multipartSchemaNames: The names of schemas used as root multipart content.
    /// - Returns: A declaration of the schemas namespace in the parent
    /// components namespace.
    /// - Throws: An error if there is an issue during schema translation.
    func translateSchemas(
        _ schemas: OpenAPI.ComponentDictionary<JSONSchema>,
        multipartSchemaNames: Set<OpenAPI.ComponentKey>
    ) throws -> Declaration {
        let decls: [Declaration] = try schemas.flatMap { key, value in
            try translateSchema(
                componentKey: key,
                schema: value,
                isMultipartContent: multipartSchemaNames.contains(key)
            )
        }
        let declsWithBoxingApplied = try boxRecursiveTypes(decls)
        let componentsSchemasEnum = Declaration.commentable(
            JSONSchema.sectionComment(),
            .enum(
                accessModifier: config.access,
                name: Constants.Components.Schemas.namespace,
                members: declsWithBoxingApplied
            )
        )
        return componentsSchemasEnum
    }

    struct ShardedFile {
        var layer: Int
        var shardIndex: Int
        var fileIndex: Int
        var fileName: String
        var declarations: [Declaration]
    }

    struct ShardedSchemaResult {
        var files: [ShardedFile]
        var graph: SchemaDependencyGraph
        var maxLayer: Int
    }

    struct ShardedOperationResult {
        var files: [ShardedFile]
    }

    private static let minDeclarationsPerFile = 12

    private static func splitDeclarationsIntoFiles(
        _ declarations: [Declaration],
        maxFiles: Int
    ) -> [[Declaration]] {
        if maxFiles <= 1 { return [declarations] }
        if declarations.isEmpty { return [[]] }
        let minPerFile = (declarations.count + maxFiles - 1) / maxFiles
        let perFile = max(minDeclarationsPerFile, minPerFile)
        return stride(from: 0, to: declarations.count, by: perFile).map { start in
            let end = min(start + perFile, declarations.count)
            return Array(declarations[start..<end])
        }
    }

    private static func emitPaddedFiles(
        declarations: [Declaration],
        maxFiles: Int,
        layer: Int,
        shardIndex: Int,
        fileName: (Int) -> String
    ) -> [ShardedFile] {
        let fileGroups = splitDeclarationsIntoFiles(declarations, maxFiles: maxFiles)
        let totalFiles = maxFiles
        return (0..<totalFiles).map { fileIndex in
            ShardedFile(
                layer: layer,
                shardIndex: shardIndex,
                fileIndex: fileIndex,
                fileName: fileName(fileIndex),
                declarations: fileIndex < fileGroups.count ? fileGroups[fileIndex] : []
            )
        }
    }

    enum ShardNamingStrategy {
        case `default`
        case prefixed(modulePrefix: String)

        func componentShardFileName(shard: Int, file: Int) -> String {
            switch self {
            case .default:
                return "Components_\(shard)_\(file).swift"
            case .prefixed(let modulePrefix):
                let compsBase = modulePrefix + "Components"
                return "\(compsBase)_openapi_components_\(shard)_\(file).swift"
            }
        }

        func typeLayerShardFileName(layer: Int, shard: Int, file: Int) -> String {
            switch self {
            case .default:
                return "Types_L\(layer + 1)_\(shard)_\(file).swift"
            case .prefixed(let modulePrefix):
                let suffix = typeLayerSuffix(layer: layer)
                let layerBase = modulePrefix + suffix
                return "\(layerBase)_openapi_\(suffix.lowercased())_\(shard)_\(file).swift"
            }
        }

        func operationLayerShardFileName(layer: Int, shard: Int, file: Int, isSingleFile: Bool = false) -> String {
            switch self {
            case .default:
                if isSingleFile { return "Operations_L\(layer).swift" }
                return "Operations_L\(layer)_\(shard)_\(file).swift"
            case .prefixed(let modulePrefix):
                let opsBase = (modulePrefix + "Operations").lowercased()
                if isSingleFile {
                    return "\(opsBase)_openapi_operations_l\(layer).swift"
                }
                return "\(opsBase)_openapi_operations_l\(layer)_\(shard)_\(file).swift"
            }
        }

        var componentsBaseFileName: String {
            switch self {
            case .default:
                return "Components_base.swift"
            case .prefixed(let modulePrefix):
                return "\(modulePrefix)Components_openapi_components.swift"
            }
        }

        var operationsBaseFileName: String {
            switch self {
            case .default:
                return "Operations_base.swift"
            case .prefixed(let modulePrefix):
                return "\(modulePrefix)Operations_openapi_operations.swift"
            }
        }
    }

    struct ShardImportResolver {
        var config: ShardingConfig
        var naming: ShardNamingStrategy

        private func componentBaseImports(prefix modulePrefix: String, exported: Bool = false) -> [ImportDescription] {
            let compsBase = modulePrefix + "Components"
            var result = [ImportDescription(moduleName: compsBase, exported: exported)]
            for i in 1...config.typeShardCounts[0] {
                result.append(ImportDescription(moduleName: "\(compsBase)_\(i)", exported: exported))
            }
            return result
        }

        private func typeLayerImports(prefix modulePrefix: String, upToLayer: Int, exported: Bool = false) -> [ImportDescription] {
            var result: [ImportDescription] = []
            for layerIndex in 0..<upToLayer {
                let suffix = typeLayerSuffix(layer: layerIndex)
                for i in 1...config.typeShardCount(forLayer: layerIndex + 1) {
                    result.append(ImportDescription(moduleName: "\(modulePrefix)\(suffix)_\(i)", exported: exported))
                }
            }
            return result
        }

        func componentShardImports() -> [ImportDescription] {
            guard case .prefixed(let modulePrefix) = naming else { return [] }
            return [ImportDescription(moduleName: modulePrefix + "Components")]
        }

        func typeLayerShardImports(layerIndex: Int) -> [ImportDescription] {
            guard case .prefixed(let modulePrefix) = naming else { return [] }
            return componentBaseImports(prefix: modulePrefix)
                + typeLayerImports(prefix: modulePrefix, upToLayer: layerIndex)
        }

        func exportedImportsForRootFile(maxLayer: Int) -> [ImportDescription] {
            guard case .prefixed(let modulePrefix) = naming else { return [] }
            let typeLayerCount = min(maxLayer, config.layerCount - 1)
            var result = componentBaseImports(prefix: modulePrefix, exported: true)
                + typeLayerImports(prefix: modulePrefix, upToLayer: typeLayerCount, exported: true)
            let opsBase = modulePrefix + "Operations"
            result.append(ImportDescription(moduleName: opsBase, exported: true))
            for layerIndex in 0...maxLayer {
                let shardCount = config.operationLayerShardCounts[layerIndex]
                if shardCount > 1 {
                    for s in 1...shardCount {
                        result.append(ImportDescription(moduleName: "\(opsBase)_L\(layerIndex)_\(s)", exported: true))
                    }
                } else {
                    result.append(ImportDescription(moduleName: "\(opsBase)_L\(layerIndex)", exported: true))
                }
            }
            return result
        }

        func operationShardImports(layerIndex: Int) -> [ImportDescription] {
            guard case .prefixed(let modulePrefix) = naming else { return [] }
            var result = [ImportDescription(moduleName: "\(modulePrefix)Operations")]
            result += componentBaseImports(prefix: modulePrefix)
            result += typeLayerImports(prefix: modulePrefix, upToLayer: min(layerIndex, config.layerCount - 1))
            return result
        }
    }

    func translateSchemasSharded(
        _ schemas: OpenAPI.ComponentDictionary<JSONSchema>,
        multipartSchemaNames: Set<OpenAPI.ComponentKey>,
        shardingConfig: ShardingConfig,
        naming: ShardNamingStrategy
    ) throws -> ShardedSchemaResult {
        let graph = SchemaDependencyGraph.build(from: schemas)
        var declsBySchemaName: [String: [Declaration]] = [:]
        for (key, value) in schemas {
            let schemaName = key.rawValue
            let decls = try translateSchema(
                componentKey: key,
                schema: value,
                isMultipartContent: multipartSchemaNames.contains(key)
            )
            declsBySchemaName[schemaName] = decls
        }

        let maxLayer = min(shardingConfig.layerCount - 1, max(0, graph.layerCount - 1))

        var islandsByLayer: [Int: [GraphAlgorithms.Island]] = [:]
        for (compId, members) in graph.scc.components.enumerated() {
            let layer = min(graph.layerOf[compId], maxLayer)
            islandsByLayer[layer, default: []].append(members)
        }

        let orderedSchemaDecls: [(name: String, decls: [Declaration])] = schemas.map { key, _ in
            (name: key.rawValue, decls: declsBySchemaName[key.rawValue] ?? [])
        }
        let allDecls = orderedSchemaDecls.flatMap(\.decls)
        let allBoxedDecls = try boxRecursiveTypes(allDecls)
        guard allBoxedDecls.count == allDecls.count else {
            throw GenericError(
                message: "boxRecursiveTypes changed declaration count: \(allDecls.count) → \(allBoxedDecls.count)"
            )
        }
        var boxedDeclsBySchemaName: [String: [Declaration]] = [:]
        var boxedIndex = 0
        for (name, decls) in orderedSchemaDecls {
            boxedDeclsBySchemaName[name] = Array(allBoxedDecls[boxedIndex..<boxedIndex + decls.count])
            boxedIndex += decls.count
        }
        let declarationWeightsBySchemaName = boxedDeclsBySchemaName.mapValues(declarationNodeCount)

        var files: [ShardedFile] = []

        for layerIndex in 0...maxLayer {
            let islands = islandsByLayer[layerIndex] ?? []
            let isComponentLayer = layerIndex == 0
            let shardCount = shardingConfig.typeShardCount(forLayer: layerIndex)
            let maxFiles = shardingConfig.maxFilesPerShard

            let bins = GraphAlgorithms.lptPacking(islands: islands, binCount: shardCount) { island in
                let totalWeight = island.reduce(into: 0) { partialResult, schemaName in
                    partialResult += declarationWeightsBySchemaName[schemaName] ?? 1
                }
                return max(1, totalWeight)
            }

            for (shardIndex, bin) in bins.enumerated() {
                let schemaNames = bin.flatMap { $0 }.sorted()
                let shardDecls = schemaNames.flatMap { boxedDeclsBySchemaName[$0] ?? [] }

                files += Self.emitPaddedFiles(
                    declarations: shardDecls,
                    maxFiles: maxFiles,
                    layer: layerIndex,
                    shardIndex: shardIndex
                ) { fileIndex in
                    if isComponentLayer {
                        naming.componentShardFileName(shard: shardIndex + 1, file: fileIndex + 1)
                    } else {
                        naming.typeLayerShardFileName(layer: layerIndex - 1, shard: shardIndex + 1, file: fileIndex + 1)
                    }
                }
            }
        }

        return ShardedSchemaResult(files: files, graph: graph, maxLayer: maxLayer)
    }

    func translateOperationsSharded(
        _ operationDescriptions: [OperationDescription],
        schemaGraph: SchemaDependencyGraph,
        maxLayer: Int,
        shardingConfig: ShardingConfig,
        naming: ShardNamingStrategy
    ) throws -> ShardedOperationResult {
        var operationDeclsByLayer: [Int: [(operationID: String, declaration: Declaration)]] = [:]

        for description in operationDescriptions {
            let schemaRefs = SchemaDependencyGraph.operationSchemaRefs(
                description.operation,
                in: description.components
            )

            let operationLayer = schemaRefs.compactMap { ref in
                guard let layer = schemaGraph.layer(of: ref) else { return nil as Int? }
                return min(layer, maxLayer)
            }.max() ?? 0

            let declaration = try translateOperation(description)
            operationDeclsByLayer[operationLayer, default: []].append(
                (operationID: description.operationID, declaration: declaration)
            )
        }

        var files: [ShardedFile] = []

        for layerIndex in 0...maxLayer {
            let operations = operationDeclsByLayer[layerIndex] ?? []
            let shardCount = shardingConfig.operationLayerShardCounts[layerIndex]
            let maxFiles = shardingConfig.maxFilesPerShardOps

            let islands: [GraphAlgorithms.Island] = operations.map { [$0.operationID] }
            let declsByOpID = Dictionary(uniqueKeysWithValues: operations.map { ($0.operationID, $0.declaration) })

            let bins = GraphAlgorithms.lptPacking(islands: islands, binCount: shardCount) { island in
                let totalWeight = island.reduce(into: 0) { partialResult, opID in
                    if let decl = declsByOpID[opID] {
                        partialResult += declarationNodeCount(decl)
                    } else {
                        partialResult += 1
                    }
                }
                return max(1, totalWeight)
            }

            for (shardIndex, bin) in bins.enumerated() {
                let opIDs = bin.flatMap { $0 }.sorted()
                let shardDecls = opIDs.compactMap { declsByOpID[$0] }

                let isSingleFile = shardCount == 1 && maxFiles <= 1
                files += Self.emitPaddedFiles(
                    declarations: shardDecls,
                    maxFiles: maxFiles,
                    layer: layerIndex,
                    shardIndex: shardIndex
                ) { fileIndex in
                    naming.operationLayerShardFileName(
                        layer: layerIndex,
                        shard: shardIndex + 1,
                        file: fileIndex + 1,
                        isSingleFile: isSingleFile
                    )
                }
            }
        }

        return ShardedOperationResult(files: files)
    }
}
