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
import OpenAPIKit30
import XCTest
@testable import _OpenAPIGeneratorCore

final class Test_OperationDescription: Test_Core {

    func testAllParameters_duplicates_retainOnlyOperationParameters() throws {
        let allParameters = try _test(
            """
            openapi: "3.0.0"
            info:
              title: "Test"
              version: "1.0.0"
            paths:
              /system:
                get:
                  description: This is a unit test.
                  responses:
                    '200':
                      description: Success
                  parameters:
                    - name: test
                      in: query
                      schema:
                        type: string
                parameters:
                  - name: test
                    in: query
                    schema:
                      type: integer
            """
        )

        XCTAssertEqual(
            allParameters,
            [.b(OpenAPI.Parameter(name: "test", context: .query(required: false), schema: .integer))]
        )
    }

    func testAllParameters_duplicates_keepsDuplicatesAtDifferentLocation() throws {
        let allParameters = try _test(
            """
            openapi: "3.0.0"
            info:
              title: "Test"
              version: "1.0.0"
            paths:
              /system:
                get:
                  description: This is a unit test.
                  responses:
                    '200':
                      description: Success
                  parameters:
                    - name: test
                      in: query
                      schema:
                        type: string
                parameters:
                  - name: test
                    in: path
                    required: true
                    schema:
                      type: integer
            """
        )

        XCTAssertEqual(
            allParameters,
            [
                .b(OpenAPI.Parameter(name: "test", context: .path, schema: .integer)),
                .b(OpenAPI.Parameter(name: "test", context: .query(required: false), schema: .string))
            ]
        )
    }

    private func _test(_ yaml: String) throws -> [UnresolvedParameter] {
        let document = try YamsParser()
            .parseOpenAPI(
                .init(
                    absolutePath: URL(fileURLWithPath: "/foo.yaml"),
                    contents: Data(yaml.utf8)
                ),
                config: .init(mode: .types),
                diagnostics: PrintingDiagnosticCollector()
            )

        guard let operationDescription = try OperationDescription.all(
            from: document.paths,
            in: document.components,
            asSwiftSafeName: { $0 }
        ).first else {
            XCTFail("Unable to retrieve the operation description.")
            return []
        }

        return try operationDescription.allParameters
    }
}
