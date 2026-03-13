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
import OpenAPIKit
import Testing
@testable import _OpenAPIGeneratorCore


@Suite("ValidateDoc Tests")
struct ValidateDocTests {
    
    @Test("Schema warning is not fatal")
    func testSchemaWarningIsNotFatal() throws {
        let schemaWithWarnings = try TestFixtures.loadSchemaFromYAML(
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
            
        #expect(diagnostics.count == 1, "Expected exactly 1 diagnostic for schema warning")
    }
    
    
    @Test("Schema warning is fatal")
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
        
        #expect(throws: (any Error).self) {
            try validateDoc(doc, config:
                    .init(mode: .types, access: Config.defaultAccessModifier, namingStrategy: Config.defaultNamingStrategy)
            )
        }
    }
    
    
    @Test("Validates valid content types pass without throwing")
    func testValidateContentTypes_validContentTypes() {
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
        #expect(throws: Never.self) {
            try validateContentTypes(in: doc) { contentType in
                (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
            }
        }
    }
    

    @Test("Invalid content types in request body fail validation")
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
        
        let error = try #require(throws: Diagnostic.self) {
            try validateContentTypes(in: doc) { contentType in
                (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
            }
        }
        #expect(error.localizedDescription == "error: Invalid content type string. [context: contentType=application/, location=/path1/GET/requestBody, recoverySuggestion=Must have 2 components separated by a slash '<type>/<subtype>'.]")
    }
    
    
    @Test("Invalid content types in responses fail validation")
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
        
        let error = try #require(throws: Diagnostic.self) {
            try validateContentTypes(in: doc) { contentType in
                (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
            }
        }
        #expect(error.localizedDescription == "error: Invalid content type string. [context: contentType=/plain, location=/path2/GET/responses, recoverySuggestion=Must have 2 components separated by a slash '<type>/<subtype>'.]")
    }
    
    
    @Test("Validate content types throws error for invalid content types in components request bodies")
    func validateContentTypes_invalidContentTypesInComponentsRequestBodies() throws {
        let doc = OpenAPI.Document(
            info: .init(title: "Test", version: "1.0.0"),
            servers: [],
            paths: [
                "/path1": .b(
                    .init(
                        get: .init(
                            requestBody: .b(
                                .init(content: [
                                    .init(rawValue: "application/xml")!: .init(schema: .string)
                                ])
                            ),
                            responses: [
                                .init(integerLiteral: 200): .b(
                                    .init(
                                        description: "Test description 1",
                                        content: [
                                            .init(rawValue: "application/json")!: .init(schema: .string)
                                        ]
                                    )
                                )
                            ]
                        )
                    )
                )
            ],
            components: .init(requestBodies: [
                "exampleRequestBody1": .init(content: [
                    .init(rawValue: "application/pdf")!: .init(schema: .string)
                ]),
                "exampleRequestBody2": .init(content: [
                    .init(rawValue: "image/")!: .init(schema: .string)
                ]),
            ])
        )
        
        let error = try #require(throws: Diagnostic.self) {
            try validateContentTypes(in: doc) { contentType in
                (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
            }
        }
        #expect(error.localizedDescription == "error: Invalid content type string. [context: contentType=image/, location=#/components/requestBodies/exampleRequestBody2, recoverySuggestion=Must have 2 components separated by a slash '<type>/<subtype>'.]")
    }


    @Test("Invalid content types in components responses fail validation")
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
        
        let error = try #require(throws: Diagnostic.self) {
            try validateContentTypes(in: doc) { contentType in
                (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
            }
        }
        #expect(error.localizedDescription == "error: Invalid content type string. [context: contentType=, location=#/components/responses/exampleRequestBody2, recoverySuggestion=Must have 2 components separated by a slash '<type>/<subtype>'.]"
        )
    }
    

    @Test("Validates that valid references do not throw errors")
    func testValidateReferences_validReferences() {
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
                ),
                "/path2": .a(.component(named: "Path2Reference")),
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
        
        #expect(throws: Never.self) { try validateReferences(in: doc) }
    }
    
    
    @Test("Reference not found in components should throw diagnostic error")
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
        
        
        let error = try #require(throws: Diagnostic.self) { try validateReferences(in: doc) }
        #expect(error.localizedDescription == "error: Reference not found in components. [context: location=/path/GET/requestBody/content/text/html/schema, reference=#/components/schemas/RequestBodyContentSchemaReference]")
    }
    
    
    @Test("External references should throw diagnostic error")
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
        
        let error = try #require(throws: Diagnostic.self) { try validateReferences(in: doc) }
        #expect(error.localizedDescription == "error: External references are not suppported. [context: location=/path/GET/responses/200, reference=ExternalURL]")
    }

    
    @Test("Validates type overrides")
    func testValidateTypeOverrides() throws {
        let schema = try TestFixtures.loadSchemaFromYAML(
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
        
        #expect(diagnostics.count == 1, "Expected exactly one diagnostic")
        #expect(diagnostics.first?.message == "A type override defined for schema 'NonExistent' is not defined in the OpenAPI document.")
    }
}
