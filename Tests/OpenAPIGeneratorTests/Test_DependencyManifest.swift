//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import XCTest
import _OpenAPIGeneratorCore

#if !os(Windows)
@testable import swift_openapi_generator

final class Test_DependencyManifest: XCTestCase {
    func testSHA256KnownVector() {
        XCTAssertEqual(
            SHA256Digest.hexDigest(Data("abc".utf8)),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    func testDirectAndCommandPluginWriteDeterministicSemanticManifest() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let documentURL = temporaryDirectory.appendingPathComponent("openapi.yaml")
        let document = Data(Self.document.utf8)
        try document.write(to: documentURL)
        let configs = [
            Config(
                mode: .types,
                access: .internal,
                namingStrategy: .defensive,
                maxDeclarationsPerFile: 1,
                dependencyLayerCount: 2
            ), Config(mode: .client, access: .internal, namingStrategy: .defensive),
        ]

        var encodedManifests: [Data] = []
        for (name, pluginSource) in [("direct", nil), ("command", PluginSource.command)] {
            let outputDirectory = temporaryDirectory.appendingPathComponent(name)
            try await _Tool.runGenerator(
                doc: documentURL,
                configs: configs,
                pluginSource: pluginSource,
                outputDirectory: outputDirectory,
                isDryRun: false,
                dependencyManifestFileName: "dependency-manifest.json",
                diagnostics: StdErrPrintingDiagnosticCollector()
            )
            let data = try Data(contentsOf: outputDirectory.appendingPathComponent("dependency-manifest.json"))
            encodedManifests.append(data)
            let manifest = try JSONDecoder().decode(DependencyManifest.self, from: data)
            XCTAssertEqual(manifest.formatVersion, 1)
            XCTAssertEqual(manifest.inputDigest.algorithm, "sha256")
            XCTAssertEqual(manifest.inputDigest.value, SHA256Digest.hexDigest(document))
            XCTAssertEqual(manifest.outputDigest.value.count, 64)
            XCTAssertEqual(manifest.files.map(\.path), manifest.files.map(\.path).sorted())
            XCTAssertTrue(manifest.files.contains { $0.path == "Client.swift" && $0.role == "client" })

            let filesByPath = Dictionary(uniqueKeysWithValues: manifest.files.map { ($0.path, $0) })
            XCTAssertEqual(
                filesByPath["Types.swift"]?.declarations,
                ["APIProtocol", "Components", "Operations", "Servers"]
            )
            XCTAssertEqual(filesByPath["Types.swift"]?.moduleIdentity, "facade")
            XCTAssertEqual(
                filesByPath["Types+Components.swift"]?.declarations,
                [
                    "Components.Headers", "Components.Parameters", "Components.RequestBodies", "Components.Responses",
                    "Components.Schemas",
                ]
            )
            XCTAssertEqual(filesByPath["Types+Components.swift"]?.moduleIdentity, "components_base")
            let leaf = try XCTUnwrap(filesByPath["Types+Components+Schemas+Layer0.swift"])
            XCTAssertEqual(leaf.role, "schema")
            XCTAssertEqual(leaf.namespace, "Components.Schemas")
            XCTAssertEqual(leaf.declarations, ["Leaf"])
            XCTAssertEqual(leaf.schemaDependencies, [])
            XCTAssertEqual(leaf.dependencyLayer, 0)
            XCTAssertEqual(leaf.declarationChunk, 0)

            let order = try XCTUnwrap(filesByPath["Types+Components+Schemas+Layer1.swift"])
            XCTAssertEqual(order.declarations, ["Order"])
            XCTAssertEqual(order.schemaDependencies, ["Leaf"])
            XCTAssertNotEqual(order.moduleIdentity, leaf.moduleIdentity)

            let response = try XCTUnwrap(filesByPath["Types+Components+Responses+Layer1.swift"])
            XCTAssertEqual(response.declarations, ["response:OrderResponse"])
            XCTAssertEqual(response.schemaDependencies, ["Leaf", "Order"])
            XCTAssertEqual(response.componentDependencies, ["header:LeafHeader"])
            XCTAssertEqual(response.moduleIdentity, "reusable_components")
            XCTAssertEqual(
                response.moduleIdentity,
                filesByPath["Types+Components+Parameters+Layer0.swift"]?.moduleIdentity
            )

            let operation = try XCTUnwrap(filesByPath["Types+Operations+Layer1.swift"])
            XCTAssertEqual(operation.declarations, ["createOrder"])
            XCTAssertEqual(operation.schemaDependencies, ["Leaf", "Order"])
            XCTAssertEqual(
                operation.componentDependencies,
                ["parameter:LeafParam", "requestBody:OrderRequest", "response:OrderResponse"]
            )
        }
        XCTAssertEqual(encodedManifests[0], encodedManifests[1])
    }

    func testBuildPluginRejectsDependencyManifest() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let documentURL = temporaryDirectory.appendingPathComponent("openapi.yaml")
        try Data(Self.document.utf8).write(to: documentURL)

        do {
            try await _Tool.runGenerator(
                doc: documentURL,
                configs: [Config(mode: .client, access: .internal, namingStrategy: .defensive)],
                pluginSource: .build,
                outputDirectory: temporaryDirectory,
                isDryRun: false,
                dependencyManifestFileName: "dependency-manifest.json",
                diagnostics: StdErrPrintingDiagnosticCollector()
            )
            XCTFail("Expected the build-tool plugin invocation to reject a dependency manifest.")
        } catch { XCTAssertTrue(String(describing: error).contains("Dependency manifests are not supported")) }
    }

    func testTypeOverrideRemovesReplacedSchemaDependencies() throws {
        let outputs = try _OpenAPIGeneratorCore.runGenerator(
            input: .init(absolutePath: URL(fileURLWithPath: "/openapi.yaml"), contents: Data(Self.document.utf8)),
            config: .init(
                mode: .types,
                access: .internal,
                namingStrategy: .defensive,
                typeOverrides: .init(schemas: ["Order": "Swift.String"]),
                dependencyLayerCount: 2
            ),
            diagnostics: StdErrPrintingDiagnosticCollector()
        )
        let order = try XCTUnwrap(outputs.first { $0.metadata?.declarations == ["Order"] })
        XCTAssertEqual(order.metadata?.schemaDependencies, [])
    }

    private static let document = """
        openapi: "3.1.0"
        info:
          title: ManifestTest
          version: "1.0.0"
        components:
          schemas:
            Leaf:
              type: string
            Order:
              type: object
              properties:
                leaf:
                  $ref: '#/components/schemas/Leaf'
          parameters:
            LeafParam:
              name: leaf
              in: query
              schema:
                $ref: '#/components/schemas/Leaf'
          headers:
            LeafHeader:
              schema:
                $ref: '#/components/schemas/Leaf'
          requestBodies:
            OrderRequest:
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Order'
          responses:
            OrderResponse:
              description: order
              headers:
                leaf:
                  $ref: '#/components/headers/LeafHeader'
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Order'
        paths:
          /orders:
            post:
              operationId: createOrder
              parameters:
                - $ref: '#/components/parameters/LeafParam'
              requestBody:
                $ref: '#/components/requestBodies/OrderRequest'
              responses:
                '200':
                  $ref: '#/components/responses/OrderResponse'
        """
}
#endif
