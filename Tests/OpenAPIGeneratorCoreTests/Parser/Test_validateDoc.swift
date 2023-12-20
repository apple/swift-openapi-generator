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

    func testValidateContentTypes_validContentTypes() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/path1": .b(
                    .init(
                        get: .init(
                            requestBody: .b(
                                .init(content: [.init(rawValue: "application/xml")!: .init(schema: .string)])
                            ),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [.init(rawValue: "application/json")!: .init(schema: .string)]
                                    )
                                )
                            ]
                        )
                    )
                ),
                "/path2": .b(
                    .init(
                        get: .init(
                            requestBody: .b(.init(content: [.init(rawValue: "text/html")!: .init(schema: .string)])),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 2",
                                        content: [.init(rawValue: "text/plain")!: .init(schema: .string)]
                                    )
                                )
                            ]
                        )
                    )
                ),
            ],
            components: .noComponents
        )
        XCTAssertNoThrow(
            try validateContentTypes(in: doc) { contentType in
                (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
            }
        )
    }

    func testValidateContentTypes_invalidContentTypesInRequestBody() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/path1": .b(
                    .init(
                        get: .init(
                            requestBody: .b(.init(content: [.init(rawValue: "application/")!: .init(schema: .string)])),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [.init(rawValue: "application/json")!: .init(schema: .string)]
                                    )
                                )
                            ]
                        )
                    )
                ),
                "/path2": .b(
                    .init(
                        get: .init(
                            requestBody: .b(.init(content: [.init(rawValue: "text/html")!: .init(schema: .string)])),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 2",
                                        content: [.init(rawValue: "text/plain")!: .init(schema: .string)]
                                    )
                                )
                            ]
                        )
                    )
                ),
            ],
            components: .noComponents
        )
        XCTAssertThrowsError(
            try validateContentTypes(in: doc) { contentType in
                (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
            }
        ) { error in
            XCTAssertTrue(error is Diagnostic)
            XCTAssertEqual(
                error.localizedDescription,
                "error: Invalid content type string: 'application/' found in requestBody at path '/path1'. Must have 2 components separated by a slash '<type>/<subtype>'.\n"
            )
        }
    }

    func testValidateContentTypes_invalidContentTypesInResponses() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/path1": .b(
                    .init(
                        get: .init(
                            requestBody: .b(
                                .init(content: [.init(rawValue: "application/xml")!: .init(schema: .string)])
                            ),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [.init(rawValue: "application/json")!: .init(schema: .string)]
                                    )
                                )
                            ]
                        )
                    )
                ),
                "/path2": .b(
                    .init(
                        get: .init(
                            requestBody: .b(.init(content: [.init(rawValue: "text/html")!: .init(schema: .string)])),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 2",
                                        content: [.init(rawValue: "/plain")!: .init(schema: .string)]
                                    )
                                )
                            ]
                        )
                    )
                ),
            ],
            components: .noComponents
        )
        XCTAssertThrowsError(
            try validateContentTypes(in: doc) { contentType in
                (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
            }
        ) { error in
            XCTAssertTrue(error is Diagnostic)
            XCTAssertEqual(
                error.localizedDescription,
                "error: Invalid content type string: '/plain' found in responses at path '/path2'. Must have 2 components separated by a slash '<type>/<subtype>'.\n"
            )
        }
    }

    func testValidateContentTypes_invalidContentTypesInComponentsRequestBodies() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/path1": .b(
                    .init(
                        get: .init(
                            requestBody: .b(
                                .init(content: [.init(rawValue: "application/xml")!: .init(schema: .string)])
                            ),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [.init(rawValue: "application/json")!: .init(schema: .string)]
                                    )
                                )
                            ]
                        )
                    )
                )
            ],
            components: .init(requestBodies: [
                "exampleRequestBody1": .init(content: [.init(rawValue: "application/pdf")!: .init(schema: .string)]),
                "exampleRequestBody2": .init(content: [.init(rawValue: "image/")!: .init(schema: .string)]),
            ])
        )
        XCTAssertThrowsError(
            try validateContentTypes(in: doc) { contentType in
                (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
            }
        ) { error in
            XCTAssertTrue(error is Diagnostic)
            XCTAssertEqual(
                error.localizedDescription,
                "error: Invalid content type string: 'image/' found in #/components/requestBodies. Must have 2 components separated by a slash '<type>/<subtype>'.\n"
            )
        }
    }

    func testValidateContentTypes_invalidContentTypesInComponentsResponses() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/path1": .b(
                    .init(
                        get: .init(
                            requestBody: .b(
                                .init(content: [.init(rawValue: "application/xml")!: .init(schema: .string)])
                            ),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [.init(rawValue: "application/json")!: .init(schema: .string)]
                                    )
                                )
                            ]
                        )
                    )
                )
            ],
            components: .init(responses: [
                "exampleRequestBody1": .init(
                    description: "Test description 1",
                    content: [.init(rawValue: "application/pdf")!: .init(schema: .string)]
                ),
                "exampleRequestBody2": .init(
                    description: "Test description 2",
                    content: [.init(rawValue: "")!: .init(schema: .string)]
                ),
            ])
        )
        XCTAssertThrowsError(
            try validateContentTypes(in: doc) { contentType in
                (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
            }
        ) { error in
            XCTAssertTrue(error is Diagnostic)
            XCTAssertEqual(
                error.localizedDescription,
                "error: Invalid content type string: '' found in #/components/responses. Must have 2 components separated by a slash '<type>/<subtype>'.\n"
            )
        }
    }

}
