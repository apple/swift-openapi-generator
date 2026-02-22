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
import Foundation
@testable import _OpenAPIGeneratorCore

final class Test_ShardedGeneration: XCTestCase {

    /// A minimal OpenAPI spec with 5 schemas across 2+ dependency layers and 2 operations.
    private static let specYAML = """
        openapi: "3.1.0"
        info:
          title: "Sharding Test API"
          version: "1.0.0"
        paths:
          /items:
            get:
              operationId: listItems
              responses:
                "200":
                  description: OK
                  content:
                    application/json:
                      schema:
                        type: array
                        items:
                          $ref: "#/components/schemas/Item"
          /items/{id}:
            get:
              operationId: getItem
              parameters:
                - name: id
                  in: path
                  required: true
                  schema:
                    type: string
              responses:
                "200":
                  description: OK
                  content:
                    application/json:
                      schema:
                        $ref: "#/components/schemas/Item"
        components:
          schemas:
            Color:
              type: string
              enum: [red, green, blue]
            Tag:
              type: object
              properties:
                name:
                  type: string
            Category:
              type: object
              properties:
                label:
                  type: string
                color:
                  $ref: "#/components/schemas/Color"
            Item:
              type: object
              properties:
                name:
                  type: string
                category:
                  $ref: "#/components/schemas/Category"
                tags:
                  type: array
                  items:
                    $ref: "#/components/schemas/Tag"
            DetailedItem:
              type: object
              properties:
                item:
                  $ref: "#/components/schemas/Item"
                description:
                  type: string
        """

    func testShardedGenerationProducesExpectedFiles() throws {
        let config = Config(
            mode: .types,
            access: .public,
            namingStrategy: .defensive,
            sharding: ShardingConfig(
                typeShardCounts: [1, 1, 1],
                maxFilesPerShard: 1,
                maxFilesPerShardOps: 1,
                operationLayerShardCounts: [1, 1, 1]
            )
        )

        let input = InMemoryInputFile(
            absolutePath: URL(string: "openapi.yaml")!,
            contents: Data(Self.specYAML.utf8)
        )
        let diagnostics = AccumulatingDiagnosticCollector()
        let outputs = try runShardedGenerator(
            input: input,
            config: config,
            diagnostics: diagnostics
        )

        let fileNames = outputs.map(\.baseName)
        let fileNameSet = Set(fileNames)

        // Must have the root types file
        XCTAssertTrue(fileNameSet.contains("Types_root.swift"), "Missing Types_root.swift, got: \(fileNames)")

        // Must have exactly one component base file
        XCTAssertEqual(
            fileNames.filter { $0 == "Components_base.swift" }.count, 1,
            "Expected exactly one Components_base.swift, got: \(fileNames)"
        )

        // Must have component shard files (excluding the base file)
        let componentShardFiles = fileNames.filter {
            $0.hasPrefix("Components_") && $0 != "Components_base.swift"
        }
        XCTAssertEqual(componentShardFiles.count, 1, "Expected 1 component shard file (1 shard × 1 file), got: \(componentShardFiles)")

        // Must have operation files
        let operationBaseFiles = fileNames.filter { $0 == "Operations_base.swift" }
        XCTAssertEqual(operationBaseFiles.count, 1, "Expected exactly one Operations_base.swift, got: \(fileNames)")

        let operationLayerFiles = fileNames.filter {
            $0.hasPrefix("Operations_L") || $0.hasPrefix("Operations_") && $0 != "Operations_base.swift"
        }
        XCTAssertEqual(operationLayerFiles.count, 3, "Expected 3 operation layer files (L0, L1, L2), got: \(operationLayerFiles)")

        // Verify Types_root.swift contains the API protocol
        let rootFile = try XCTUnwrap(outputs.first { $0.baseName == "Types_root.swift" })
        let rootContent = String(data: rootFile.contents, encoding: .utf8)!
        XCTAssertTrue(rootContent.contains("protocol APIProtocol"))

        // No diagnostics expected for a valid spec
        XCTAssertEqual(diagnostics.diagnostics.count, 0)
    }

    func testShardedGenerationWithPrefixedNaming() throws {
        let config = Config(
            mode: .types,
            access: .public,
            namingStrategy: .defensive,
            sharding: ShardingConfig(
                typeShardCounts: [1, 1, 1],
                maxFilesPerShard: 1,
                maxFilesPerShardOps: 1,
                operationLayerShardCounts: [1, 1, 1],
                modulePrefix: "TestModule"
            )
        )

        let input = InMemoryInputFile(
            absolutePath: URL(string: "openapi.yaml")!,
            contents: Data(Self.specYAML.utf8)
        )
        let diagnostics = AccumulatingDiagnosticCollector()
        let outputs = try runShardedGenerator(
            input: input,
            config: config,
            diagnostics: diagnostics
        )

        let fileNames = outputs.map(\.baseName)

        // Prefixed naming should produce module-prefixed filenames
        let componentFiles = fileNames.filter { $0.contains("TestModuleComponents") }
        XCTAssertGreaterThanOrEqual(componentFiles.count, 1, "Expected TestModule-prefixed component files")

        // Should have operation files with module prefix
        let operationFiles = fileNames.filter { $0.contains("testmoduleoperations") }
        XCTAssertGreaterThanOrEqual(operationFiles.count, 1, "Expected TestModule-prefixed operation files")

        // Types_root should have @_exported imports
        let rootFile = try XCTUnwrap(outputs.first { $0.baseName == "Types_root.swift" })
        let rootContent = String(data: rootFile.contents, encoding: .utf8)!
        XCTAssertTrue(rootContent.contains("@_exported import"), "Types_root.swift should contain @_exported imports")
    }
}
