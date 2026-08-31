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
import Foundation
import XCTest
@testable import _OpenAPIGeneratorCore

final class Test_TypesFileTranslatorFileSplitting: Test_Core {

    func testDefaultGenerationProducesDepth2NamespaceFiles() throws {
        let input = InMemoryInputFile(absolutePath: URL(string: "openapi.yaml")!, contents: Data(Self.source.utf8))
        let diagnostics = AccumulatingDiagnosticCollector()
        let outputs = try runGenerator(
            input: input,
            config: Config(mode: .types, access: .public, namingStrategy: .defensive),
            diagnostics: diagnostics
        )

        XCTAssertEqual(diagnostics.diagnostics.count, 0)
        XCTAssertEqual(
            outputs.map(\.baseName),
            [
                "Types.swift", "Types+Components.swift", "Types+Operations.swift", "Types+Components+Schemas.swift",
                "Types+Components+Parameters.swift", "Types+Components+RequestBodies.swift",
                "Types+Components+Responses.swift", "Types+Components+Headers.swift",
            ]
        )

        let outputByName = Self.outputByName(outputs)
        let rootSource = try XCTUnwrap(outputByName["Types.swift"])
        let componentsSource = try XCTUnwrap(outputByName["Types+Components.swift"])
        let componentSchemasSource = try XCTUnwrap(outputByName["Types+Components+Schemas.swift"])
        let componentParametersSource = try XCTUnwrap(outputByName["Types+Components+Parameters.swift"])
        let componentRequestBodiesSource = try XCTUnwrap(outputByName["Types+Components+RequestBodies.swift"])
        let componentResponsesSource = try XCTUnwrap(outputByName["Types+Components+Responses.swift"])
        let componentHeadersSource = try XCTUnwrap(outputByName["Types+Components+Headers.swift"])
        let operationsSource = try XCTUnwrap(outputByName["Types+Operations.swift"])

        XCTAssertTrue(rootSource.contains("import OpenAPIRuntime"))
        XCTAssertTrue(componentsSource.contains("import OpenAPIRuntime"))
        XCTAssertTrue(componentSchemasSource.contains("import OpenAPIRuntime"))
        XCTAssertTrue(componentParametersSource.contains("import OpenAPIRuntime"))
        XCTAssertTrue(componentRequestBodiesSource.contains("import OpenAPIRuntime"))
        XCTAssertTrue(componentResponsesSource.contains("import OpenAPIRuntime"))
        XCTAssertTrue(componentHeadersSource.contains("import OpenAPIRuntime"))
        XCTAssertTrue(operationsSource.contains("import OpenAPIRuntime"))
        for outputSource in outputByName.values { XCTAssertTrue(outputSource.contains("public import")) }
        XCTAssertTrue(componentSchemasSource.contains("import struct Foundation.Date"))
        XCTAssertTrue(operationsSource.contains("import struct Foundation.Date"))

        XCTAssertTrue(rootSource.contains("protocol APIProtocol"))
        XCTAssertFalse(rootSource.contains("enum Components"))
        XCTAssertFalse(rootSource.contains("enum Operations"))

        XCTAssertTrue(componentsSource.contains("enum Components"))
        XCTAssertFalse(componentsSource.contains("enum Schemas"))
        XCTAssertFalse(componentsSource.contains("enum Parameters"))
        XCTAssertFalse(componentsSource.contains("enum RequestBodies"))
        XCTAssertFalse(componentsSource.contains("enum Responses"))
        XCTAssertFalse(componentsSource.contains("enum Headers"))
        XCTAssertFalse(componentsSource.contains("struct User"))
        XCTAssertFalse(componentsSource.contains("protocol APIProtocol"))
        XCTAssertFalse(componentsSource.contains("enum Operations"))

        XCTAssertTrue(componentSchemasSource.contains("extension Components"))
        XCTAssertFalse(componentSchemasSource.contains("public extension Components"))
        XCTAssertTrue(componentSchemasSource.contains("enum Schemas"))
        XCTAssertTrue(componentSchemasSource.contains("struct User"))
        XCTAssertFalse(componentSchemasSource.contains("protocol APIProtocol"))
        XCTAssertFalse(componentSchemasSource.contains("enum Operations"))

        Self.assertComponentNamespaceFile(
            componentParametersSource,
            containsNamespace: "Parameters",
            excludesNamespaces: ["Schemas", "RequestBodies", "Responses", "Headers"]
        )
        Self.assertComponentNamespaceFile(
            componentRequestBodiesSource,
            containsNamespace: "RequestBodies",
            excludesNamespaces: ["Schemas", "Parameters", "Responses", "Headers"]
        )
        Self.assertComponentNamespaceFile(
            componentResponsesSource,
            containsNamespace: "Responses",
            excludesNamespaces: ["Schemas", "Parameters", "RequestBodies", "Headers"]
        )
        Self.assertComponentNamespaceFile(
            componentHeadersSource,
            containsNamespace: "Headers",
            excludesNamespaces: ["Schemas", "Parameters", "RequestBodies", "Responses"]
        )

        XCTAssertTrue(operationsSource.contains("enum Operations"))
        XCTAssertFalse(operationsSource.contains("enum Components"))
        XCTAssertFalse(operationsSource.contains("protocol APIProtocol"))
        XCTAssertTrue(operationsSource.contains("getUser"))
    }

    func testConfiguredMaximumSplitsDeclarationsAcrossExtensionFiles() throws {
        let input = InMemoryInputFile(absolutePath: URL(string: "openapi.yaml")!, contents: Data(Self.source.utf8))
        let diagnostics = AccumulatingDiagnosticCollector()
        let outputs = try runGenerator(
            input: input,
            config: Config(mode: .types, access: .public, namingStrategy: .defensive, maxDeclarationsPerFile: 1),
            diagnostics: diagnostics
        )

        XCTAssertEqual(diagnostics.diagnostics.count, 0)
        XCTAssertEqual(
            outputs.map(\.baseName),
            [
                "Types.swift", "Types+Components.swift", "Types+Operations.swift", "Types+Operations+1.swift",
                "Types+Components+Schemas.swift", "Types+Components+Schemas+1.swift",
                "Types+Components+Parameters.swift", "Types+Components+RequestBodies.swift",
                "Types+Components+Responses.swift", "Types+Components+Headers.swift",
            ]
        )

        let outputByName = Self.outputByName(outputs)
        for outputSource in outputByName.values { XCTAssertTrue(outputSource.contains("public import")) }
        let operationsContainer = try XCTUnwrap(outputByName["Types+Operations.swift"])
        let operationsSplitFile = try XCTUnwrap(outputByName["Types+Operations+1.swift"])
        let schemasContainer = try XCTUnwrap(outputByName["Types+Components+Schemas.swift"])
        let schemasSplitFile = try XCTUnwrap(outputByName["Types+Components+Schemas+1.swift"])

        XCTAssertTrue(operationsContainer.contains("extension Operations"))
        XCTAssertFalse(operationsContainer.contains("enum Operations"))
        XCTAssertTrue(operationsContainer.contains("getUser"))
        XCTAssertFalse(operationsContainer.contains("listUsers"))
        XCTAssertTrue(operationsSplitFile.contains("extension Operations"))
        XCTAssertFalse(operationsSplitFile.contains("getUser"))
        XCTAssertTrue(operationsSplitFile.contains("listUsers"))
        XCTAssertTrue(schemasContainer.contains("extension Components.Schemas"))
        XCTAssertFalse(schemasContainer.contains("enum Schemas"))
        XCTAssertTrue(schemasContainer.contains("struct User"))
        XCTAssertFalse(schemasContainer.contains("Role"))
        XCTAssertTrue(schemasSplitFile.contains("extension Components.Schemas"))
        XCTAssertFalse(schemasSplitFile.contains("struct User"))
        XCTAssertTrue(schemasSplitFile.contains("Role"))
    }

    func testConfiguredMaximumMustBePositive() throws {
        let input = InMemoryInputFile(absolutePath: URL(string: "openapi.yaml")!, contents: Data(Self.source.utf8))

        for invalidLimit in [0, -1] {
            XCTAssertThrowsError(
                try runGenerator(
                    input: input,
                    config: Config(
                        mode: .types,
                        access: .public,
                        namingStrategy: .defensive,
                        maxDeclarationsPerFile: invalidLimit
                    ),
                    diagnostics: AccumulatingDiagnosticCollector()
                )
            ) { error in
                XCTAssertTrue(String(describing: error).contains("maxDeclarationsPerFile to be greater than zero"))
            }
        }
    }

    func testDependencyLayersMustBePositive() throws {
        let input = InMemoryInputFile(absolutePath: URL(string: "openapi.yaml")!, contents: Data(Self.source.utf8))

        for invalidCount in [0, -1] {
            XCTAssertThrowsError(
                try runGenerator(
                    input: input,
                    config: Config(
                        mode: .types,
                        access: .public,
                        namingStrategy: .defensive,
                        dependencyLayerCount: invalidCount
                    ),
                    diagnostics: AccumulatingDiagnosticCollector()
                )
            ) { error in
                XCTAssertTrue(String(describing: error).contains("dependencyLayerCount to be greater than zero"))
            }
        }
    }

    func testShallowDependencyGraphDoesNotProduceEmptyLayerFiles() throws {
        let input = InMemoryInputFile(absolutePath: URL(string: "openapi.yaml")!, contents: Data(Self.source.utf8))
        let outputs = try runGenerator(
            input: input,
            config: Config(mode: .types, access: .public, namingStrategy: .defensive, dependencyLayerCount: 4),
            diagnostics: AccumulatingDiagnosticCollector()
        )

        XCTAssertEqual(
            outputs.map(\.baseName),
            [
                "Types.swift", "Types+Components.swift", "Types+Components+Schemas+Layer0.swift",
                "Types+Operations+Layer0.swift",
            ]
        )
        XCTAssertFalse(outputs.map(\.baseName).contains { $0.contains("Layer1") })
    }

    func testEmptySchemaGraphPlacesUnreferencedOperationsInLayerZero() throws {
        let source = """
            openapi: "3.1.0"
            info:
              title: NoSchemas
              version: "1.0.0"
            paths:
              /health:
                get:
                  operationId: getHealth
                  responses:
                    "204":
                      description: Healthy.
            """
        let input = InMemoryInputFile(absolutePath: URL(string: "openapi.yaml")!, contents: Data(source.utf8))
        let outputs = try runGenerator(
            input: input,
            config: Config(mode: .types, access: .public, namingStrategy: .defensive, dependencyLayerCount: 3),
            diagnostics: AccumulatingDiagnosticCollector()
        )
        let outputByName = Self.outputByName(outputs)

        XCTAssertNil(outputByName["Types+Components+Schemas+Layer0.swift"])
        XCTAssertTrue(try XCTUnwrap(outputByName["Types+Operations+Layer0.swift"]).contains("getHealth"))
        XCTAssertFalse(outputs.map(\.baseName).contains { $0.contains("Layer1") })
    }

    func testDependencyLayersPlaceComponentsAndOperationsAtHighestReferencedLayer() throws {
        let input = InMemoryInputFile(
            absolutePath: URL(string: "openapi.yaml")!,
            contents: Data(Self.dependencyLayerSource.utf8)
        )
        let diagnostics = AccumulatingDiagnosticCollector()
        let outputs = try runGenerator(
            input: input,
            config: Config(mode: .types, access: .public, namingStrategy: .defensive, dependencyLayerCount: 4),
            diagnostics: diagnostics
        )
        XCTAssertEqual(diagnostics.diagnostics.filter { $0.severity == .error }.count, 0)
        let outputByName = Self.outputByName(outputs)

        let lowestSchemas = try XCTUnwrap(outputByName["Types+Components+Schemas+Layer0.swift"])
        XCTAssertTrue(lowestSchemas.contains("struct A"))
        XCTAssertTrue(lowestSchemas.contains("struct B"))
        XCTAssertTrue(try XCTUnwrap(outputByName["Types+Components+Schemas+Layer1.swift"]).contains("struct C"))
        XCTAssertTrue(try XCTUnwrap(outputByName["Types+Components+Schemas+Layer2.swift"]).contains("struct D"))
        let highestSchemas = try XCTUnwrap(outputByName["Types+Components+Schemas+Layer3.swift"])
        XCTAssertTrue(highestSchemas.contains("struct HelperOwner"))

        XCTAssertTrue(try XCTUnwrap(outputByName["Types+Components+Parameters+Layer2.swift"]).contains("HighParameter"))
        XCTAssertTrue(
            try XCTUnwrap(outputByName["Types+Components+RequestBodies+Layer2.swift"]).contains("HighRequest")
        )
        XCTAssertTrue(try XCTUnwrap(outputByName["Types+Components+Responses+Layer2.swift"]).contains("HighResponse"))
        XCTAssertTrue(try XCTUnwrap(outputByName["Types+Components+Headers+Layer1.swift"]).contains("HighHeader"))
        XCTAssertTrue(try XCTUnwrap(outputByName["Types+Operations+Layer0.swift"]).contains("getLow"))
        XCTAssertTrue(try XCTUnwrap(outputByName["Types+Operations+Layer2.swift"]).contains("getHigh"))
    }

    func testDependencyLayersComposeWithDeclarationSplittingAndKeepSCCsTogether() throws {
        let input = InMemoryInputFile(
            absolutePath: URL(string: "openapi.yaml")!,
            contents: Data(Self.dependencyLayerSource.utf8)
        )
        let config = Config(
            mode: .types,
            access: .public,
            namingStrategy: .defensive,
            maxDeclarationsPerFile: 1,
            dependencyLayerCount: 2
        )
        let first = try runGenerator(input: input, config: config, diagnostics: AccumulatingDiagnosticCollector())
        let second = try runGenerator(input: input, config: config, diagnostics: AccumulatingDiagnosticCollector())

        XCTAssertEqual(first.map(\.baseName), second.map(\.baseName))
        XCTAssertEqual(first.map(\.contents), second.map(\.contents))
        XCTAssertTrue(first.map(\.baseName).contains("Types+Components+Schemas+Layer0+1.swift"))
        XCTAssertTrue(first.map(\.baseName).contains("Types+Components+Schemas+Layer1+1.swift"))

        let sources = first.map { String(decoding: $0.contents, as: UTF8.self) }
        let mutualSource = try XCTUnwrap(sources.first { $0.contains("struct MutualOne") })
        XCTAssertTrue(mutualSource.contains("struct MutualTwo"))
        XCTAssertTrue(mutualSource.contains("Storage"), "Expected recursive boxing to remain applied within the SCC.")
        XCTAssertFalse(sources.filter { $0.contains("struct MutualOne") || $0.contains("struct MutualTwo") }.count > 1)

        let helperSource = try XCTUnwrap(sources.first { $0.contains("struct HelperOwner") })
        XCTAssertTrue(helperSource.contains("struct detailPayload"))
    }

    func testDependencyLayersPreserveDuplicateGeneratedNameDiagnostic() throws {
        let source = """
            openapi: "3.1.0"
            info:
              title: DuplicateNames
              version: "1.0.0"
            paths: {}
            components:
              schemas:
                NullTime:
                  type: string
                nullTime:
                  type: string
            """
        let input = InMemoryInputFile(absolutePath: URL(string: "openapi.yaml")!, contents: Data(source.utf8))
        let diagnostics = AccumulatingDiagnosticCollector()

        _ = try runGenerator(
            input: input,
            config: Config(mode: .types, access: .public, namingStrategy: .idiomatic, dependencyLayerCount: 2),
            diagnostics: diagnostics
        )

        XCTAssertEqual(diagnostics.diagnostics.count, 1)
        XCTAssertTrue(diagnostics.diagnostics[0].description.contains("Multiple schemas"))
        XCTAssertEqual(diagnostics.diagnostics[0].context, ["names": "'NullTime'"])
    }

    private static func outputByName(_ outputs: [InMemoryOutputFile]) -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: outputs.map { output in
                (output.baseName, String(decoding: output.contents, as: UTF8.self))
            }
        )
    }

    private static func assertComponentNamespaceFile(
        _ source: String,
        containsNamespace namespace: String,
        excludesNamespaces excludedNamespaces: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(source.contains("extension Components"), file: file, line: line)
        XCTAssertTrue(source.contains("enum \(namespace)"), file: file, line: line)
        XCTAssertFalse(source.contains("protocol APIProtocol"), file: file, line: line)
        XCTAssertFalse(source.contains("enum Operations"), file: file, line: line)
        for excludedNamespace in excludedNamespaces {
            XCTAssertFalse(source.contains("enum \(excludedNamespace)"), file: file, line: line)
        }
    }

    private static let source = """
        openapi: "3.1.0"
        info:
          title: GreetingService
          version: "1.0.0"
        paths:
          /users/{id}:
            get:
              operationId: getUser
              parameters:
                - name: id
                  in: path
                  required: true
                  schema:
                    type: string
              responses:
                "200":
                  description: A user.
                  headers:
                    X-Expires-After:
                      schema:
                        type: string
                        format: date-time
                  content:
                    application/json:
                      schema:
                        $ref: "#/components/schemas/User"
          /users:
            get:
              operationId: listUsers
              responses:
                "200":
                  description: A list of users.
        components:
          schemas:
            User:
              type: object
              properties:
                id:
                  type: string
                createdAt:
                  type: string
                  format: date-time
              required:
                - id
            Role:
              type: string
        """

    private static let dependencyLayerSource = """
        openapi: "3.1.0"
        info:
          title: DependencyLayers
          version: "1.0.0"
        paths:
          /low:
            get:
              operationId: getLow
              responses:
                "200":
                  description: Low.
                  content:
                    application/json:
                      schema:
                        $ref: "#/components/schemas/A"
          /high:
            get:
              operationId: getHigh
              parameters:
                - $ref: "#/components/parameters/HighParameter"
              requestBody:
                $ref: "#/components/requestBodies/HighRequest"
              responses:
                "200":
                  $ref: "#/components/responses/HighResponse"
        components:
          schemas:
            A:
              type: object
              properties:
                value:
                  type: string
            B:
              type: object
              properties:
                a:
                  $ref: "#/components/schemas/A"
            C:
              type: object
              properties:
                b:
                  $ref: "#/components/schemas/B"
            D:
              type: object
              properties:
                c:
                  $ref: "#/components/schemas/C"
            HelperOwner:
              type: object
              properties:
                d:
                  $ref: "#/components/schemas/D"
                detail:
                  type: object
                  properties:
                    value:
                      type: string
            MutualOne:
              type: object
              properties:
                other:
                  $ref: "#/components/schemas/MutualTwo"
            MutualTwo:
              type: object
              properties:
                other:
                  $ref: "#/components/schemas/MutualOne"
          parameters:
            HighParameter:
              name: high
              in: query
              schema:
                $ref: "#/components/schemas/D"
          headers:
            HighHeader:
              schema:
                $ref: "#/components/schemas/C"
          requestBodies:
            HighRequest:
              content:
                application/json:
                  schema:
                    $ref: "#/components/schemas/D"
          responses:
            HighResponse:
              description: High.
              headers:
                X-High:
                  $ref: "#/components/headers/HighHeader"
              content:
                application/json:
                  schema:
                    $ref: "#/components/schemas/D"
        """
}
