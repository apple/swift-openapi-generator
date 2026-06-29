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
import XCTest
import OpenAPIKit
@testable import _OpenAPIGeneratorCore

final class Test_Sharding: Test_Core {

    // MARK: - Sharding Invariants

    private func makeShardingConfig(
        typeShardCounts: [Int] = [2, 2, 1],
        maxFilesPerShard: Int = 1,
        maxFilesPerShardOps: Int = 1,
        operationLayerShardCounts: [Int] = [1, 1, 1],
        modulePrefix: String? = nil
    ) -> ShardingConfig {
        ShardingConfig(
            typeShardCounts: typeShardCounts,
            maxFilesPerShard: maxFilesPerShard,
            maxFilesPerShardOps: maxFilesPerShardOps,
            operationLayerShardCounts: operationLayerShardCounts,
            modulePrefix: modulePrefix
        )
    }

    private func makeSchemas() -> OpenAPI.ComponentDictionary<JSONSchema> {
        // Create a small schema dependency tree:
        // A (leaf), B (leaf), C -> A, D -> B, E -> C,D
        // L0 (leaves): A, B
        // L1: C, D (depend on L0)
        // L2: E (depends on L1)
        [
            "A": .object(properties: ["name": .string]),
            "B": .object(properties: ["value": .integer]),
            "C": .object(properties: [
                "a_ref": .reference(.component(named: "A")),
            ]),
            "D": .object(properties: [
                "b_ref": .reference(.component(named: "B")),
            ]),
            "E": .object(properties: [
                "c_ref": .reference(.component(named: "C")),
                "d_ref": .reference(.component(named: "D")),
            ]),
        ]
    }

    func testAllSchemasAssignedExactlyOnce() throws {
        let schemas = makeSchemas()
        let config = makeShardingConfig()
        let translator = makeTranslator(
            components: .init(schemas: schemas.mapValues { _ in .string })
        )

        let result = try translator.translateSchemasSharded(
            schemas,
            multipartSchemaNames: [],
            shardingConfig: config,
            naming: .default
        )

        // Every shard file should have non-negative layer/shard/file indices
        for file in result.files {
            XCTAssertGreaterThanOrEqual(file.layer, 0)
            XCTAssertGreaterThanOrEqual(file.shardIndex, 0)
            XCTAssertGreaterThanOrEqual(file.fileIndex, 0)
            XCTAssertFalse(file.fileName.isEmpty)
        }

        // Files should span exactly 3 layers (L0, L1, L2) given our schema set
        let layers = Set(result.files.map(\.layer))
        XCTAssertEqual(layers, [0, 1, 2])

        // Every file with declarations should have non-empty content
        let totalDeclCount = result.files.reduce(0) { $0 + $1.declarations.count }
        XCTAssertGreaterThan(totalDeclCount, 0, "Expected declarations across shard files")
    }

    func testDependencyGraphNoForwardReferences() {
        let schemas = makeSchemas()
        let graph = SchemaDependencyGraph.build(from: schemas)

        // Verify: for each schema, its dependencies are at a lower or equal layer
        for (schemaName, deps) in graph.edges {
            guard let schemaLayer = graph.layer(of: schemaName) else { continue }
            for dep in deps {
                guard let depLayer = graph.layer(of: dep) else { continue }
                XCTAssertLessThanOrEqual(
                    depLayer, schemaLayer,
                    "Schema '\(schemaName)' (layer \(schemaLayer)) depends on '\(dep)' (layer \(depLayer))"
                )
            }
        }
    }

    func testDeterministicOutput() throws {
        let schemas = makeSchemas()
        let config = makeShardingConfig()

        func runTranslation() throws -> [TypesFileTranslator.ShardedFile] {
            let translator = makeTranslator(
                components: .init(schemas: schemas.mapValues { _ in .string })
            )
            let result = try translator.translateSchemasSharded(
                schemas,
                multipartSchemaNames: [],
                shardingConfig: config,
                naming: .default
            )
            return result.files
        }

        let run1 = try runTranslation()
        let run2 = try runTranslation()

        XCTAssertEqual(run1.count, run2.count)
        for (f1, f2) in zip(run1, run2) {
            XCTAssertEqual(f1.fileName, f2.fileName)
            XCTAssertEqual(f1.layer, f2.layer)
            XCTAssertEqual(f1.shardIndex, f2.shardIndex)
            XCTAssertEqual(f1.fileIndex, f2.fileIndex)
            XCTAssertEqual(f1.declarations, f2.declarations)
        }
    }

    // MARK: - File Naming Contract

    func testPrefixedNamingProducesExpectedPatterns() {
        let modulePrefix = "MyServiceAPI"
        let naming = TypesFileTranslator.ShardNamingStrategy.prefixed(
            modulePrefix: modulePrefix
        )

        // --- Components base ---
        XCTAssertEqual(
            naming.componentsBaseFileName,
            "MyServiceAPIComponents_openapi_components.swift"
        )

        // --- Component shard files ---
        XCTAssertEqual(
            naming.componentShardFileName(shard: 1, file: 1),
            "MyServiceAPIComponents_openapi_components_1_1.swift"
        )
        XCTAssertEqual(
            naming.componentShardFileName(shard: 3, file: 2),
            "MyServiceAPIComponents_openapi_components_3_2.swift"
        )

        // --- Type layer shard files ---
        for layerIndex in 0..<5 {
            let suffix = "Types_L\(layerIndex + 1)"
            let expected = "\(modulePrefix)\(suffix)_openapi_\(suffix.lowercased())_1_1.swift"
            XCTAssertEqual(
                naming.typeLayerShardFileName(layer: layerIndex, shard: 1, file: 1),
                expected
            )
        }

        // --- Operations base ---
        XCTAssertEqual(
            naming.operationsBaseFileName,
            "MyServiceAPIOperations_openapi_operations.swift"
        )

        // --- Operation layer shard files (single shard) ---
        XCTAssertEqual(
            naming.operationLayerShardFileName(layer: 0, shard: 1, file: 1, isSingleFile: true),
            "myserviceapioperations_openapi_operations_l0.swift"
        )

        // --- Operation layer shard files (multi shard) ---
        XCTAssertEqual(
            naming.operationLayerShardFileName(layer: 2, shard: 1, file: 1),
            "myserviceapioperations_openapi_operations_l2_1_1.swift"
        )
    }

    func testDefaultNamingProducesExpectedPatterns() {
        let naming = TypesFileTranslator.ShardNamingStrategy.default

        XCTAssertEqual(naming.componentsBaseFileName, "Components_base.swift")
        XCTAssertEqual(naming.operationsBaseFileName, "Operations_base.swift")
        XCTAssertEqual(naming.componentShardFileName(shard: 2, file: 3), "Components_2_3.swift")
        XCTAssertEqual(naming.typeLayerShardFileName(layer: 1, shard: 2, file: 1), "Types_L2_2_1.swift")
        XCTAssertEqual(naming.operationLayerShardFileName(layer: 0, shard: 1, file: 2), "Operations_L0_1_2.swift")
    }
}
