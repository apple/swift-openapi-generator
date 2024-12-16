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

class Test_TypeAssigner: Test_Core {

    func testTypeNameForReferences() throws {
        try XCTAssertEqual(
            typeAssigner.typeName(for: OpenAPI.Reference<JSONSchema>.component(named: "mumble")),
            newTypeName(swiftFQName: "Components.Schemas.mumble", jsonFQName: "#/components/schemas/mumble")
        )
        try XCTAssertEqual(
            typeAssigner.typeName(for: OpenAPI.Reference<OpenAPI.Parameter>.component(named: "mumble")),
            newTypeName(swiftFQName: "Components.Parameters.mumble", jsonFQName: "#/components/parameters/mumble")
        )
        try XCTAssertEqual(
            typeAssigner.typeName(for: OpenAPI.Reference<OpenAPI.Header>.component(named: "mumble")),
            newTypeName(swiftFQName: "Components.Headers.mumble", jsonFQName: "#/components/headers/mumble")

        )
        try XCTAssertEqual(
            typeAssigner.typeName(for: OpenAPI.Reference<OpenAPI.Request>.component(named: "mumble")),
            newTypeName(swiftFQName: "Components.RequestBodies.mumble", jsonFQName: "#/components/requestBodies/mumble")

        )
        try XCTAssertEqual(
            typeAssigner.typeName(for: OpenAPI.Reference<OpenAPI.Response>.component(named: "mumble")),
            newTypeName(swiftFQName: "Components.Responses.mumble", jsonFQName: "#/components/responses/mumble")
        )
    }

    func testTypeNameForComponentKeys() {
        let expectedSchemaTypeNames: [OpenAPI.ComponentKey: String] = [
            // camel-casing behaviour
            "customtype": "customtype", "customType": "customType", "custom_type": "custom_type",
            "custom__type": "custom__type", "custom_type_": "custom_type_",
            // preserve leading underscores
            "_custom_type": "_custom_type", "__custom__type": "__custom__type",
            // sanitization
            "1customtype": "_1customtype", "custom.type": "custom_period_type",
            ".custom$type": "_period_custom_dollar_type",
            // keywords
            "enum": "_enum",
        ]
        for (componentKey, expectedSwiftTypeName) in expectedSchemaTypeNames {
            XCTAssertEqual(asSwiftSafeName(componentKey.rawValue, .noncapitalized), expectedSwiftTypeName)
        }
    }

    func testTypeNameForComponentPairs() throws {
        let components = OpenAPI.Components(schemas: ["my_reusable_schema": .object])
        XCTAssertEqual(
            components.schemas.map(typeAssigner.typeName(for:)),
            [
                try newTypeName(
                    swiftFQName: "Components.Schemas.my_reusable_schema",
                    jsonFQName: "#/components/schemas/my_reusable_schema"
                )
            ]
        )
    }

    func testTypeNameForNamedComponent() throws {
        let expected: [(String, TypeLocation, String)] = [("Foo", .schemas, "Components.Schemas.Foo")]
        for (originalName, location, typeNameString) in expected {
            XCTAssertEqual(
                typeAssigner.typeName(forComponentOriginallyNamed: originalName, in: location).fullyQualifiedSwiftName,
                typeNameString
            )
        }
    }

    func testTypeNameForObjectProperties() throws {
        let parent = TypeName(swiftKeyPath: ["MyType"])
        let components: OpenAPI.Components = .noComponents
        let expected: [(String, JSONSchema, String)] = [
            ("foo", .object(.init(), .init(properties: ["bar": .string])), "MyType.fooPayload"),
            ("foo", .object(.init(nullable: true), .init(properties: ["bar": .string])), "MyType.fooPayload?"),
        ]
        for (originalName, schema, typeNameString) in expected {
            try XCTAssertEqual(
                typeAssigner.typeUsage(
                    forObjectPropertyNamed: originalName,
                    withSchema: schema,
                    components: components,
                    inParent: parent
                )
                .fullyQualifiedSwiftName,
                typeNameString
            )
        }
    }

    func testContentSwiftName() throws {
        let defensiveNameMaker = makeTranslator().typeAssigner.contentSwiftName
        let idiomaticNameMaker = makeTranslator(namingStrategy: .idiomatic).typeAssigner.contentSwiftName
        let cases: [(input: String, defensive: String, idiomatic: String)] = [

            // Short names.
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

            // Generic names.
            ("application/myformat+json", "application_myformat_plus_json", "applicationMyformatJson"),
            ("foo/bar", "foo_bar", "fooBar"),
            ("text/event-stream", "text_event_hyphen_stream", "textEventStream"),

            // Names with a parameter.
            ("application/foo", "application_foo", "applicationFoo"),
            ("application/foo; bar=baz; boo=foo", "application_foo_bar_baz_boo_foo", "applicationFooBarBazBooFoo"),
            ("application/foo; bar = baz", "application_foo_bar_baz", "applicationFooBarBaz"),
        ]
        for (string, defensiveName, idiomaticName) in cases {
            let contentType = try XCTUnwrap(ContentType(string: string))
            XCTAssertEqual(defensiveNameMaker(contentType), defensiveName, "Case \(string) failed for defensive strategy")
            XCTAssertEqual(idiomaticNameMaker(contentType), idiomaticName, "Case \(string) failed for idiomatic strategy")
        }
    }
}
