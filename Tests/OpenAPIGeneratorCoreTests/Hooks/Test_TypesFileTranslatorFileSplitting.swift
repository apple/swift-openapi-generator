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
        """
}
