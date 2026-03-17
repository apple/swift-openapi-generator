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
        let diagnostics = try validateDoc(
            doc,
            config: .init(
                mode: .types,
                access: Config.defaultAccessModifier,
                namingStrategy: Config.defaultNamingStrategy
            )
        )
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
        XCTAssertThrowsError(
            try validateDoc(
                doc,
                config: .init(
                    mode: .types,
                    access: Config.defaultAccessModifier,
                    namingStrategy: Config.defaultNamingStrategy
                )
            )
        )
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
                                .init(content: [.init(rawValue: "application/xml")!: .content(.init(schema: .string))])
                            ),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [.init(rawValue: "application/json")!: .content(.init(schema: .string))]
                                    )
                                )
                            ]
                        )
                    )
                ),
                "/path2": .b(
                    .init(
                        get: .init(
                            requestBody: .b(.init(content: [.init(rawValue: "text/html")!: .content(.init(schema: .string))])),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 2",
                                        content: [.init(rawValue: "text/plain")!: .content(.init(schema: .string))]
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
                            requestBody: .b(.init(content: [.init(rawValue: "application/")!: .content(.init(schema: .string))])),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [.init(rawValue: "application/json")!: .content(.init(schema: .string))]
                                    )
                                )
                            ]
                        )
                    )
                ),
                "/path2": .b(
                    .init(
                        get: .init(
                            requestBody: .b(.init(content: [.init(rawValue: "text/html")!: .content(.init(schema: .string))])),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 2",
                                        content: [.init(rawValue: "text/plain")!: .content(.init(schema: .string))]
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
                                .init(content: [.init(rawValue: "application/xml")!: .content(.init(schema: .string))])
                            ),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [.init(rawValue: "application/json")!: .content(.init(schema: .string))]
                                    )
                                )
                            ]
                        )
                    )
                ),
                "/path2": .b(
                    .init(
                        get: .init(
                            requestBody: .b(.init(content: [.init(rawValue: "text/html")!: .content(.init(schema: .string))])),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 2",
                                        content: [.init(rawValue: "/plain")!: .content(.init(schema: .string))]
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
                                .init(content: [.init(rawValue: "application/xml")!: .content(.init(schema: .string))])
                            ),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [.init(rawValue: "application/json")!: .content(.init(schema: .string))]
                                    )
                                )
                            ]
                        )
                    )
                )
            ],
            components: .direct(requestBodies: [
                "exampleRequestBody1": .init(content: [.init(rawValue: "application/pdf")!: .content(.init(schema: .string))]),
                "exampleRequestBody2": .init(content: [.init(rawValue: "image/")!: .content(.init(schema: .string))]),
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
                                .init(content: [.init(rawValue: "application/xml")!: .content(.init(schema: .string))])
                            ),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [.init(rawValue: "application/json")!: .content(.init(schema: .string))]
                                    )
                                )
                            ]
                        )
                    )
                )
            ],
            components: .direct(responses: [
                "exampleRequestBody1": .init(
                    description: "Test description 1",
                    content: [.init(rawValue: "application/pdf")!: .content(.init(schema: .string))]
                ),
                "exampleRequestBody2": .init(
                    description: "Test description 2",
                    content: [.init(rawValue: "")!: .content(.init(schema: .string))]
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
                                    .path(
                                        name: "ID",
                                        content: [
                                            .init(rawValue: "text/plain")!: .content(.init(
                                                schema: .reference(.component(named: "Path1ParametersContentSchemaReference"))
                                            ))
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
                                            .init(rawValue: "text/plain")!: .content(.init(
                                                schema: .reference(.component(named: "ResponsesContentSchemaReference"))
                                            ))
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
                                    .init(rawValue: "text/html")!: .content(.init(
                                        schema: .reference(.component(named: "RequestBodyContentSchemaReference"))
                                    ))
                                ])
                            ),
                            responses: [200: .response()],
                            callbacks: [.init("Callback"): .a(.component(named: "CallbackReference"))]
                        )
                    )
                ),
            ],
            components: .direct(
                schemas: [
                    "ResponsesContentSchemaReference": .init(schema: .string(.init(), .init())),
                    "RequestBodyContentSchemaReference": .init(schema: .integer(.init(), .init())),
                    "Path1ParametersContentSchemaReference": .init(schema: .string(.init(), .init())),
                ],
                responses: ["ResponsesReference": .init(description: "Description")],
                parameters: [
                    "Path3ExampleID": .path(name: "ID", content: .init()),
                    "Path1ParametersReference": .path(name: "Schema", schema: .array),
                ],
                requestBodies: [
                    "RequestBodyReference": .init(content: .init())

                ],
                headers: ["ResponsesHeaderReference": .init(schema: .array)],
                callbacks: ["CallbackReference": .init()],
                pathItems: ["Path2Reference": .init()]
            )
        )
        XCTAssertNoThrow(
            try validateDoc(
                doc,
                config: .init(
                    mode: .types,
                    access: Config.defaultAccessModifier,
                    namingStrategy: Config.defaultNamingStrategy
                )
            )
        )
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
                                    .init(rawValue: "text/html")!: .content(.init(
                                        schema: .reference(.component(named: "RequestBodyContentSchemaReference"))
                                    ))
                                ])
                            ),
                            responses: [200: .response()]
                        )
                    )
                )
            ],
            components: .init(schemas: ["RequestBodyContentSchema": .init(schema: .integer(.init(), .init()))])
        )
        XCTAssertThrowsError(
            try validateDoc(
                doc,
                config: .init(
                    mode: .types,
                    access: Config.defaultAccessModifier,
                    namingStrategy: Config.defaultNamingStrategy
                )
            )
        ) { error in
            XCTAssertTrue(error is ValidationErrorCollection)
            XCTAssertEqual(
                OpenAPI.Error(from: error).localizedDescription,
                "Failed to satisfy: JSONSchema reference points to this document and can be found in components/schemas at path: .paths['/path'].get.requestBody.content['text/html'].schema"
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
        XCTAssertThrowsError(
            try validateDoc(
                doc,
                config: .init(
                    mode: .types,
                    access: Config.defaultAccessModifier,
                    namingStrategy: Config.defaultNamingStrategy
                )
            )
        ) { error in
            XCTAssertTrue(error is ValidationErrorCollection)
            XCTAssertEqual(
                OpenAPI.Error(from: error).localizedDescription,
                "Failed to satisfy: Response reference points to this document and can be found in components/responses at path: .paths['/path'].get.responses.200"
            )
        }
    }
    func testValidateTypeOverrides() throws {
        let schema = try loadSchemaFromYAML(
            #"""
            type: string
            """#
        )
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [:],
            components: .init(schemas: ["MyType": schema])
        )
        let diagnostics = validateTypeOverrides(
            doc,
            config: .init(
                mode: .types,
                access: Config.defaultAccessModifier,
                namingStrategy: Config.defaultNamingStrategy,
                typeOverrides: TypeOverrides(schemas: ["NonExistent": "NonExistent"])
            )
        )
        XCTAssertEqual(diagnostics.count, 1)
        XCTAssertEqual(
            diagnostics.first?.message,
            "A type override defined for schema 'NonExistent' is not defined in the OpenAPI document."
        )
    }

}
