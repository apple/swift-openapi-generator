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
import XCTest
import Yams
@testable import _OpenAPIGeneratorCore

final class Test_FilteredDocument: XCTestCase {

    func testDocumentFilter() throws {
        let documentYAML = """
            openapi: 3.1.0
            info:
              title: ExampleService
              version: 1.0.0
            tags:
            - name: t
            paths:
              /things/a:
                parameters:
                  - $ref: '#/components/parameters/A'
                get:
                  operationId: getA
                  tags:
                  - t
                  responses:
                    200:
                      $ref: '#/components/responses/A'
                delete:
                  operationId: deleteA
                  responses:
                    200:
                      $ref: '#/components/responses/Empty'
              /things/b:
                get:
                  operationId: getB
                  responses:
                    200:
                      $ref: '#/components/responses/B'
              /things/c:
                parameters:
                  - $ref: '#/components/parameters/C'
                    description: Parameter C reference description
                get:
                  operationId: getC
                  parameters:
                    - $ref: '#/components/parameters/D'
                      description: Parameter D reference description
                  responses:
                    200:
                      $ref: '#/components/responses/C'
                      description: Response C reference description
            components:
              schemas:
                A:
                  type: string
                B:
                  $ref: '#/components/schemas/A'
                C:
                  type: object
                  description: Schema C description
                  properties:
                    value:
                      $ref: '#/components/schemas/A'
                      description: Schema A reference description
              parameters:
                A:
                  in: query
                  schema:
                    type: string
                  name: A
                C:
                  in: query
                  name: cParam
                  schema:
                    $ref: '#/components/schemas/C'
                    description: Schema C reference description
                D:
                  in: query
                  name: dParam
                  schema:
                    type: string
              headers:
                C:
                  schema:
                    $ref: '#/components/schemas/A'
                    description: Schema A reference description
                  description: Header C
              responses:
                A:
                  description: success
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/A'
                B:
                  description: success
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/B'
                C:
                  description: Response C description
                  headers:
                    X-Custom-Header:
                      $ref: '#/components/headers/C'
                      description: Header C reference description
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/C'
                        description: Schema C reference description
                      examples:
                        example1:
                          $ref: '#/components/examples/C'
                          description: Example C reference description
                Empty:
                  description: success
              examples:
                C:
                  value:
                    value: "test"
                    nested:
                      deepValue: "nested test"
            """
        let document = try YAMLDecoder().decode(OpenAPI.Document.self, from: documentYAML)
        assert(filtering: document, filter: DocumentFilter(), hasPaths: [], hasOperations: [], hasSchemas: [])
        assert(
            filtering: document,
            filter: DocumentFilter(tags: ["t"]),
            hasPaths: ["/things/a"],
            hasOperations: ["getA"],
            hasSchemas: ["A"],
            hasParameters: ["A"]
        )
        assert(
            filtering: document,
            filter: DocumentFilter(paths: ["/things/a"]),
            hasPaths: ["/things/a"],
            hasOperations: ["getA", "deleteA"],
            hasSchemas: ["A"],
            hasParameters: ["A"]
        )
        assert(
            filtering: document,
            filter: DocumentFilter(paths: ["/things/b"]),
            hasPaths: ["/things/b"],
            hasOperations: ["getB"],
            hasSchemas: ["A", "B"]
        )
        assert(
            filtering: document,
            filter: DocumentFilter(paths: ["/things/a", "/things/b"]),
            hasPaths: ["/things/a", "/things/b"],
            hasOperations: ["getA", "deleteA", "getB"],
            hasSchemas: ["A", "B"],
            hasParameters: ["A"]
        )
        assert(
            filtering: document,
            filter: DocumentFilter(schemas: ["A"]),
            hasPaths: [],
            hasOperations: [],
            hasSchemas: ["A"]
        )
        assert(
            filtering: document,
            filter: DocumentFilter(schemas: ["B"]),
            hasPaths: [],
            hasOperations: [],
            hasSchemas: ["A", "B"]
        )
        assert(
            filtering: document,
            filter: DocumentFilter(paths: ["/things/a"], schemas: ["B"]),
            hasPaths: ["/things/a"],
            hasOperations: ["getA", "deleteA"],
            hasSchemas: ["A", "B"],
            hasParameters: ["A"]
        )
        assert(
            filtering: document,
            filter: DocumentFilter(tags: ["t"], schemas: ["B"]),
            hasPaths: ["/things/a"],
            hasOperations: ["getA"],
            hasSchemas: ["A", "B"],
            hasParameters: ["A"]
        )
        assert(
            filtering: document,
            filter: DocumentFilter(operations: ["deleteA"]),
            hasPaths: ["/things/a"],
            hasOperations: ["deleteA"],
            hasSchemas: [],
            hasParameters: ["A"]
        )
        assert(
            filtering: document,
            filter: DocumentFilter(paths: ["/things/c"]),
            hasPaths: ["/things/c"],
            hasOperations: ["getC"],
            hasSchemas: ["A", "C"],
            hasParameters: ["C", "D"],
            hasHeaders: ["C"],
            hasExamples: ["C"]
        )
    }

    func assert(
        filtering document: OpenAPI.Document,
        filter: DocumentFilter,
        hasPaths paths: [OpenAPI.Path.RawValue],
        hasOperations operationIDs: [String],
        hasSchemas schemas: [String],
        hasParameters parameters: [String] = [],
        hasHeaders headers: [String] = [],
        hasExamples examples: [String] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let filteredDocument: OpenAPI.Document
        do { filteredDocument = try filter.filter(document) } catch {
            XCTFail("Filter threw error: \(error)", file: file, line: line)
            return
        }
        XCTAssertUnsortedEqual(
            filteredDocument.paths.keys.map(\.rawValue),
            paths,
            "Paths don't match",
            file: file,
            line: line
        )
        XCTAssertUnsortedEqual(
            filteredDocument.allOperationIds,
            operationIDs,
            "Operations don't match",
            file: file,
            line: line
        )
        XCTAssertUnsortedEqual(
            filteredDocument.components.schemas.keys.map(\.rawValue),
            schemas,
            "Schemas don't match",
            file: file,
            line: line
        )
        XCTAssertUnsortedEqual(
            filteredDocument.components.parameters.keys.map(\.rawValue),
            parameters,
            "Parameters don't match",
            file: file,
            line: line
        )
        XCTAssertUnsortedEqual(
            filteredDocument.components.headers.keys.map(\.rawValue),
            headers,
            "Headers don't match",
            file: file,
            line: line
        )
        XCTAssertUnsortedEqual(
            filteredDocument.components.examples.keys.map(\.rawValue),
            examples,
            "Examples don't match",
            file: file,
            line: line
        )
    }
}
