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
import Testing
import OpenAPIKit
@testable import _OpenAPIGeneratorCore


@Suite("Type Assigner Tests")
struct Test_TypeAssigner {
    
    @Test("Type name for references is correct")
    func typeNameForReferences() throws {
        #expect(
            try TestFixtures.typeAssigner.typeName(for: OpenAPI.Reference<JSONSchema>.component(named: "mumble")) ==
            (try newTypeName(swiftFQName: "Components.Schemas.mumble", jsonFQName: "#/components/schemas/mumble"))
        )
        #expect(
            try TestFixtures.typeAssigner.typeName(for: OpenAPI.Reference<OpenAPI.Parameter>.component(named: "mumble")) ==
            (try newTypeName(swiftFQName: "Components.Parameters.mumble", jsonFQName: "#/components/parameters/mumble"))
        )
        #expect(
            try TestFixtures.typeAssigner.typeName(for: OpenAPI.Reference<OpenAPI.Header>.component(named: "mumble")) ==
            (try newTypeName(swiftFQName: "Components.Headers.mumble", jsonFQName: "#/components/headers/mumble"))
        )
        #expect(
            try TestFixtures.typeAssigner.typeName(for: OpenAPI.Reference<OpenAPI.Request>.component(named: "mumble")) ==
            (try newTypeName(swiftFQName: "Components.RequestBodies.mumble", jsonFQName: "#/components/requestBodies/mumble"))
        )
        #expect(
            try TestFixtures.typeAssigner.typeName(for: OpenAPI.Reference<OpenAPI.Response>.component(named: "mumble")) ==
            (try newTypeName(swiftFQName: "Components.Responses.mumble", jsonFQName: "#/components/responses/mumble"))
        )
    }
    
    @Test("Generates expected Swift type names for component keys")
    func testTypeNameForComponentKeys() {
        let expectedSchemaTypeNames: [OpenAPI.ComponentKey: String] = [
            "customtype": "customtype",
            "customType": "customType",
            "custom_type": "custom_type",
            "custom__type": "custom__type",
            "custom_type_": "custom_type_",
            "_custom_type": "_custom_type",
            "__custom__type": "__custom__type",
            "1customtype": "_1customtype",
            "custom.type": "custom_period_type",
            ".custom$type": "_period_custom_dollar_type",
            "enum": "_enum",
        ]
        for (componentKey, expectedSwiftTypeName) in expectedSchemaTypeNames {
            #expect(TestFixtures.context.safeNameGenerator.swiftMemberName(for: componentKey.rawValue) == expectedSwiftTypeName)
        }
    }
    
    @Test("Type names for component pairs match expected values")
    func testTypeNameForComponentPairs() throws {
        let components = OpenAPI.Components(schemas: ["my_reusable_schema": .object])
        #expect(
            components.schemas.map(TestFixtures.typeAssigner.typeName(for:)) ==
            [
                try newTypeName(
                    swiftFQName: "Components.Schemas.my_reusable_schema",
                    jsonFQName: "#/components/schemas/my_reusable_schema"
                )
            ]
        )
    }
    
    @Test("Type name for named component is correct")
    func testTypeNameForNamedComponent() throws {
        let expected: [(String, TypeLocation, String)] = [("Foo", .schemas, "Components.Schemas.Foo")]
        for (originalName, location, typeNameString) in expected {
            #expect(
                TestFixtures.typeAssigner.typeName(forComponentOriginallyNamed: originalName, in: location).fullyQualifiedSwiftName == typeNameString,
                "Expected typeName to be (typeNameString)"
            )
        }
    }
    
    @Test("Type names for object properties")
    func testTypeNameForObjectProperties() throws {
        let parent = TypeName(swiftKeyPath: ["MyType"])
        let components: OpenAPI.Components = .noComponents
        let expected: [(String, JSONSchema, String)] = [
            ("foo", .object(.init(), .init(properties: ["bar": .string])), "MyType.fooPayload"),
            ("foo", .object(.init(nullable: true), .init(properties: ["bar": .string])), "MyType.fooPayload?"),
        ]
        for (originalName, schema, typeNameString) in expected {
            #expect(
                try TestFixtures.typeAssigner.typeUsage(
                    forObjectPropertyNamed: originalName,
                    withSchema: schema,
                    components: components,
                    inParent: parent
                )
                .fullyQualifiedSwiftName == typeNameString,
                "Expected (typeNameString)"
            )
        }
    }
    
    @Test("Content Swift name is generated correctly")
    func testContentSwiftName() throws {
        let defensiveNameMaker = TestFixtures.makeTranslator().context.safeNameGenerator.swiftContentTypeName
        let idiomaticNameMaker = TestFixtures.makeTranslator(namingStrategy: .idiomatic).context.safeNameGenerator.swiftContentTypeName
        let cases: [(input: String, defensive: String, idiomatic: String)] = [
            ("application/json", "json", "json"),
            ("application/x-www-form-urlencoded", "urlEncodedForm", "urlEncodedForm"),
            ("multipart/form-data", "multipartForm", "multipartForm"),
            ("text/plain", "plainText", "plainText"),
            ("*/*", "any", "any"),
            ("application/xml", "xml", "xml"),
            ("application/octet-stream", "binary", "binary"),
            ("text/html", "html", "html"),
            ("application/yaml", "yaml", "yaml"),
            ("text/csv", "csv", "csv"),
            ("image/png", "png", "png"),
            ("application/pdf", "pdf", "pdf"),
            ("image/jpeg", "jpeg", "jpeg"),
            ("application/myformat+json", "application_myformat_plus_json", "applicationMyformatJson"),
            ("foo/bar", "foo_bar", "fooBar"),
            ("text/event-stream", "text_event_hyphen_stream", "textEventStream"),
            ("application/foo", "application_foo", "applicationFoo"),
            ("application/foo; bar=baz; boo=foo", "application_foo_bar_baz_boo_foo", "applicationFooBarBazBooFoo"),
            ("application/foo; bar = baz", "application_foo_bar_baz", "applicationFooBarBaz"),
        ]
        for (string, defensiveName, idiomaticName) in cases {
            let contentType = try ContentType(string: string)
            #expect(defensiveNameMaker(contentType) == defensiveName, "Case \(string) failed for defensive strategy")
            #expect(idiomaticNameMaker(contentType) == idiomaticName, "Case \(string) failed for idiomatic strategy")
        }
    }
}
