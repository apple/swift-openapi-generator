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

    func testNamespaceSplittingProducesRootComponentsAndOperationsFiles() throws {
        let input = InMemoryInputFile(
            absolutePath: URL(string: "openapi.yaml")!,
            contents: Data(Self.source.utf8)
        )
        let diagnostics = AccumulatingDiagnosticCollector()
        let outputs = try runGenerator(
            input: input,
            config: Self.splitConfig(strategy: .namespace),
            diagnostics: diagnostics
        )

        XCTAssertEqual(diagnostics.diagnostics.count, 0)
        XCTAssertEqual(outputs.map(\.baseName), ["Types.swift", "Types+Components.swift", "Types+Operations.swift"])

        let outputByName = Dictionary(uniqueKeysWithValues: outputs.map { output in
            (output.baseName, String(decoding: output.contents, as: UTF8.self))
        })
        let rootSource = try XCTUnwrap(outputByName["Types.swift"])
        let componentsSource = try XCTUnwrap(outputByName["Types+Components.swift"])
        let operationsSource = try XCTUnwrap(outputByName["Types+Operations.swift"])

        XCTAssertTrue(rootSource.contains("import OpenAPIRuntime"))
        XCTAssertTrue(componentsSource.contains("import OpenAPIRuntime"))
        XCTAssertTrue(operationsSource.contains("import OpenAPIRuntime"))
        XCTAssertTrue(componentsSource.contains("import struct Foundation.Date"))
        XCTAssertTrue(operationsSource.contains("import struct Foundation.Date"))

        XCTAssertTrue(rootSource.contains("protocol APIProtocol"))
        XCTAssertFalse(rootSource.contains("enum Components"))
        XCTAssertFalse(rootSource.contains("enum Operations"))

        XCTAssertTrue(componentsSource.contains("enum Components"))
        XCTAssertTrue(componentsSource.contains("struct User"))
        XCTAssertFalse(componentsSource.contains("protocol APIProtocol"))
        XCTAssertFalse(componentsSource.contains("enum Operations"))

        XCTAssertTrue(operationsSource.contains("enum Operations"))
        XCTAssertFalse(operationsSource.contains("enum Components"))
        XCTAssertFalse(operationsSource.contains("protocol APIProtocol"))
    }

    func testNamespaceSplittingIsDisabledByDefault() throws {
        let input = InMemoryInputFile(
            absolutePath: URL(string: "openapi.yaml")!,
            contents: Data(Self.source.utf8)
        )
        let diagnostics = AccumulatingDiagnosticCollector()
        let outputs = try runGenerator(
            input: input,
            config: Config(mode: .types, access: .public, namingStrategy: .defensive),
            diagnostics: diagnostics
        )

        XCTAssertEqual(diagnostics.diagnostics.count, 0)
        XCTAssertEqual(outputs.map(\.baseName), ["Types.swift"])
    }

    private static func splitConfig(strategy: TypesFileSplittingStrategy) -> Config {
        .init(
            mode: .types,
            access: .public,
            namingStrategy: .defensive,
            output: .init(
                types: .init(
                    fileSplitting: .init(strategy: strategy)
                )
            )
        )
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
