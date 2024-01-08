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
                "error: Invalid content type string. [context: contentType=application/, location=/path1/GET/requestBody, recoverySuggestion=Must have 2 components separated by a slash '<type>/<subtype>'.]"
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
                "error: Invalid content type string. [context: contentType=/plain, location=/path2/GET/responses, recoverySuggestion=Must have 2 components separated by a slash '<type>/<subtype>'.]"
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
                "error: Invalid content type string. [context: contentType=image/, location=#/components/requestBodies/exampleRequestBody2, recoverySuggestion=Must have 2 components separated by a slash '<type>/<subtype>'.]"
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
                "error: Invalid content type string. [context: contentType=, location=#/components/responses/exampleRequestBody2, recoverySuggestion=Must have 2 components separated by a slash '<type>/<subtype>'.]"
            )
        }
    }

    func testValidateReferences_validReferences() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/path1": .b(
                    .init(
                        get: .init(
                            parameters: .init(
                                arrayLiteral: .b(
                                    .init(
                                        name: "ID",
                                        context: .path,
                                        content: [
                                            .init(rawValue: "text/plain")!: .init(
                                                schema: .a(.component(named: "Path1ParametersContentSchemaReference"))
                                            )
                                        ]
                                    )
                                ),
                                .init(.component(named: "Path1ParametersReference"))
                            ),
                            requestBody: .reference(.component(named: "RequestBodyReference")),
                            responses: [
                                .init(integerLiteral: 200): .reference(.component(named: "ResponsesReference")),
                                .init(integerLiteral: 202): .response(
                                    .init(
                                        description: "ResponseDescription",
                                        content: [
                                            .init(rawValue: "text/plain")!: .init(
                                                schema: .a(.component(named: "ResponsesContentSchemaReference"))
                                            )
                                        ]
                                    )
                                ),
                                .init(integerLiteral: 204): .response(
                                    description: "Response Description",
                                    headers: ["Header": .a(.component(named: "ResponsesHeaderReference"))]
                                ),
                            ]
                        )
                    )
                ), "/path2": .a(.component(named: "Path2Reference")),
                "/path3": .b(
                    .init(
                        get: .init(
                            parameters: .init(arrayLiteral: .a(.component(named: "Path3ExampleID"))),
                            requestBody: .b(
                                .init(content: [
                                    .init(rawValue: "text/html")!: .init(
                                        schema: .a(.component(named: "RequestBodyContentSchemaReference"))
                                    )
                                ])
                            ),
                            responses: [:],
                            callbacks: [.init("Callback"): .a(.component(named: "CallbackReference"))]
                        )
                    )
                ),
            ],
            components: .init(
                schemas: [
                    "ResponsesContentSchemaReference": .init(schema: .string(.init(), .init())),
                    "RequestBodyContentSchemaReference": .init(schema: .integer(.init(), .init())),
                    "Path1ParametersContentSchemaReference": .init(schema: .string(.init(), .init())),
                ],
                responses: ["ResponsesReference": .init(description: "Description")],
                parameters: [
                    "Path3ExampleID": .init(name: "ID", context: .path, content: .init()),
                    "Path1ParametersReference": .init(name: "Schema", context: .path, schema: .array),
                ],
                requestBodies: [
                    "RequestBodyReference": .init(content: .init())

                ],
                headers: ["ResponsesHeaderReference": .init(schema: .array)],
                callbacks: ["CallbackReference": .init()],
                pathItems: ["Path2Reference": .init()]
            )
        )
        XCTAssertNoThrow(try validateReferences(in: doc))
    }

    func testValidateReferences_referenceNotFoundInComponents() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/path": .b(
                    .init(
                        get: .init(
                            requestBody: .b(
                                .init(content: [
                                    .init(rawValue: "text/html")!: .init(
                                        schema: .a(.component(named: "RequestBodyContentSchemaReference"))
                                    )
                                ])
                            ),
                            responses: [:]
                        )
                    )
                )
            ],
            components: .init(schemas: ["RequestBodyContentSchema": .init(schema: .integer(.init(), .init()))])
        )
        XCTAssertThrowsError(try validateReferences(in: doc)) { error in
            XCTAssertTrue(error is Diagnostic)
            XCTAssertEqual(
                error.localizedDescription,
                "error: Reference not found in components. [context: location=/path/GET/requestBody/content/text/html/schema, reference=#/components/schemas/RequestBodyContentSchemaReference]"
            )
        }
    }

    func testValidateReferences_foundExternalReference() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/path": .b(
                    .init(
                        get: .init(
                            requestBody: .b(.init(content: .init())),
                            responses: [.init(integerLiteral: 200): .reference(.external(URL(string: "ExternalURL")!))]
                        )
                    )
                )
            ],
            components: .noComponents
        )
        XCTAssertThrowsError(try validateReferences(in: doc)) { error in
            XCTAssertTrue(error is Diagnostic)
            XCTAssertEqual(
                error.localizedDescription,
                "error: External references are not suppported. [context: location=/path/GET/responses/200, reference=ExternalURL]"
            )
        }
    }

}
