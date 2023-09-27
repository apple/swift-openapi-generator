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

    func testFilteredDocumentBuilder() throws {
        let documentYAML = """
            openapi: '3.1.0'
            info:
              title: GreetingService
              version: 1.0.0
            paths:
              /A:
                get:
                  operationId: getA
                  responses:
                    '200':
                      description: Success.
                      content:
                        application/json:
                          schema:
                            $ref: '#/components/schemas/A'
              /B:
                get:
                  operationId: getB
                  responses:
                    '200':
                      description: Success.
                      content:
                        application/json:
                          schema:
                            $ref: '#/components/schemas/B'
            components:
              schemas:
                A: {}
                B:
                  $ref: '#/components/schemas/A'
            """
        let document = try YAMLDecoder().decode(OpenAPI.Document.self, from: documentYAML)
        do {
            let builder = FilteredDocumentBuilder(document: document)
            let filteredDocument = try builder.filter()
            XCTAssertEqual(filteredDocument.paths.keys, [])
            XCTAssertEqual(filteredDocument.allOperationIds, [])
            XCTAssertEqual(filteredDocument.components, .noComponents)
        }
        do {
            var builder = FilteredDocumentBuilder(document: document)
            try builder.requirePath(operationID: "getA")
            let filteredDocument = try builder.filter()
            XCTAssertEqual(filteredDocument.paths.keys, ["/A"])
            XCTAssertEqual(filteredDocument.allOperationIds, ["getA"])
            XCTAssertEqual(filteredDocument.components.schemas.keys.map(\.rawValue).sorted(), ["A"].sorted())
        }
        do {
            var builder = FilteredDocumentBuilder(document: document)
            try builder.requirePath(operationID: "getB")
            let filteredDocument = try builder.filter()
            XCTAssertEqual(filteredDocument.paths.keys, ["/B"])
            XCTAssertEqual(filteredDocument.allOperationIds, ["getB"])
            XCTAssertEqual(filteredDocument.components.schemas.keys.map(\.rawValue).sorted(), ["A", "B"].sorted())
        }
        do {
            var builder = FilteredDocumentBuilder(document: document)
            try builder.requirePath("/A")
            let filteredDocument = try builder.filter()
            XCTAssertEqual(filteredDocument.paths.keys, ["/A"])
            XCTAssertEqual(filteredDocument.allOperationIds, ["getA"])
            XCTAssertEqual(filteredDocument.components.schemas.keys.map(\.rawValue).sorted(), ["A"].sorted())
        }
    }
}
