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

final class FilteredDocumentTests: XCTestCase {

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
            components:
              schemas:
                A:
                  type: string
                B:
                  $ref: '#/components/schemas/A'
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
                Empty:
                  description: success
            """
        let document = try YAMLDecoder().decode(OpenAPI.Document.self, from: documentYAML)
        try assert(
            filtering: document,
            filter: DocumentFilter(),
            hasPaths: [],
            hasOperations: [],
            hasSchemas: []
        )
        try assert(
            filtering: document,
            filter: DocumentFilter(tags: ["t"]),
            hasPaths: ["/things/a"],
            hasOperations: ["getA"],
            hasSchemas: ["A"]
        )
        try assert(
            filtering: document,
            filter: DocumentFilter(paths: ["/things/a"]),
            hasPaths: ["/things/a"],
            hasOperations: ["getA", "deleteA"],
            hasSchemas: ["A"]
        )
        try assert(
            filtering: document,
            filter: DocumentFilter(paths: ["/things/b"]),
            hasPaths: ["/things/b"],
            hasOperations: ["getB"],
            hasSchemas: ["A", "B"]
        )
        try assert(
            filtering: document,
            filter: DocumentFilter(paths: ["/things/a", "/things/b"]),
            hasPaths: ["/things/a", "/things/b"],
            hasOperations: ["getA", "deleteA", "getB"],
            hasSchemas: ["A", "B"]
        )
        try assert(
            filtering: document,
            filter: DocumentFilter(schemas: ["A"]),
            hasPaths: [],
            hasOperations: [],
            hasSchemas: ["A"]
        )
        try assert(
            filtering: document,
            filter: DocumentFilter(schemas: ["B"]),
            hasPaths: [],
            hasOperations: [],
            hasSchemas: ["A", "B"]
        )
        try assert(
            filtering: document,
            filter: DocumentFilter(paths: ["/things/a"], schemas: ["B"]),
            hasPaths: ["/things/a"],
            hasOperations: ["getA", "deleteA"],
            hasSchemas: ["A", "B"]
        )
        try assert(
            filtering: document,
            filter: DocumentFilter(tags: ["t"], schemas: ["B"]),
            hasPaths: ["/things/a"],
            hasOperations: ["getA"],
            hasSchemas: ["A", "B"]
        )
    }

    func assert(
        filtering document: OpenAPI.Document,
        filter: DocumentFilter,
        hasPaths paths: [OpenAPI.Path.RawValue],
        hasOperations operationIDs: [String],
        hasSchemas schemas: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let filteredDocument: OpenAPI.Document
        do {
            filteredDocument = try filter.filter(document)
        } catch {
            XCTFail("Filter threw error: \(error)", file: file, line: line)
            return
        }
        XCTAssertUnsortedEqual(filteredDocument.paths.keys.map(\.rawValue), paths, file: file, line: line)
        XCTAssertUnsortedEqual(filteredDocument.allOperationIds, operationIDs, file: file, line: line)
        XCTAssertUnsortedEqual(filteredDocument.components.schemas.keys.map(\.rawValue), schemas, file: file, line: line)
    }
}

fileprivate func XCTAssertUnsortedEqual<T>(
    _ expression1: @autoclosure () throws -> Array<T>,
    _ expression2: @autoclosure () throws -> Array<T>,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) where T: Comparable {
    XCTAssertEqual(
        try expression1().sorted(),
        try expression2().sorted(),
        message(),
        file: file,
        line: line
    )
}
