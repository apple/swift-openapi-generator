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

final class Test_validateDoc: Test_Core {

    func testSchemaWarningIsNotFatal() throws {
        let schemaWithWarnings = try loadSchemaFromYAML(
            #"""
            type: string
            items:
              type: integer
            """#
        )
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [:],
            components: .init(schemas: ["myImperfectSchema": schemaWithWarnings])
        )
        let diagnostics = try validateDoc(doc, config: .init(mode: .types, access: Config.defaultAccessModifier))
        XCTAssertEqual(diagnostics.count, 1)
    }

    func testStructuralWarningIsFatal() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/foo": .b(
                    .init(
                        get: .init(
                            requestBody: nil,

                            // Fatal error: missing at least one response.
                            responses: [:]
                        )
                    )
                )
            ],
            components: .noComponents
        )
        XCTAssertThrowsError(try validateDoc(doc, config: .init(mode: .types, access: Config.defaultAccessModifier)))
    }

    func testExtractContentTypes() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/path1": .b(
                    OpenAPI.PathItem(
                        get: .init(
                            requestBody: .b(OpenAPI.Request(content: [.init(rawValue: "")!: .init(schema: .string)])),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    OpenAPI.Response(
                                        description: "Test description 1",
                                        content: [
                                            OpenAPI.ContentType(rawValue: "application/json")!: .init(schema: .string)
                                        ]
                                    )
                                )
                            ]
                        )
                    )
                ),
                "/path2": .b(
                    OpenAPI.PathItem(
                        get: .init(
                            requestBody: .b(OpenAPI.Request(content: [.init(rawValue: " ")!: .init(schema: .string)])),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    OpenAPI.Response(
                                        description: "Test description 2",
                                        content: [OpenAPI.ContentType(rawValue: "text/plain")!: .init(schema: .string)]
                                    )
                                )
                            ]
                        )
                    )
                ),
            ],
            components: .noComponents
        )
        XCTAssertEqual(extractContentTypes(from: doc), ["", "application/json", " ", "text/plain"])
    }

    func testValidContentTypes() throws {
        let validContentTypes = ["application/json", "text/html"]
        XCTAssertNoThrow(try validateContentTypes(validContentTypes))
    }

    func testContentTypes_emptyArray() { XCTAssertNoThrow(try validateContentTypes([])) }

    func testInvalidContentTypes_spaceBetweenComponents() {
        let invalidContentTypes = ["application/json", "text / html"]
        XCTAssertThrowsError(try validateContentTypes(invalidContentTypes)) { error in
            XCTAssertTrue(error is Diagnostic)
            XCTAssertEqual(
                error.localizedDescription,
                "error: Invalid content type string: 'text / html' must have 2 components separated by a slash '<type>/<subtype>'.\n"
            )
        }
    }

    func testInvalidContentTypes_missingComponent() {
        let invalidContentTypes = ["/json", "text/html"]
        XCTAssertThrowsError(try validateContentTypes(invalidContentTypes)) { error in
            XCTAssertTrue(error is Diagnostic)
            XCTAssertEqual(
                error.localizedDescription,
                "error: Invalid content type string: '/json' must have 2 components separated by a slash '<type>/<subtype>'.\n"
            )
        }
    }
    func testInvalidContentTypes_emptyComponent() {
        let invalidContentTypes = ["application/json", ""]
        XCTAssertThrowsError(try validateContentTypes(invalidContentTypes)) { error in
            XCTAssertTrue(error is Diagnostic)
            XCTAssertEqual(
                error.localizedDescription,
                "error: Invalid content type string: '' must have 2 components separated by a slash '<type>/<subtype>'.\n"
            )
        }
    }

}
