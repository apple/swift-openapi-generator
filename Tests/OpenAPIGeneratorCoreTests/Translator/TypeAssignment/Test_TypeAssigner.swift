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
            XCTAssertEqual(asSwiftSafeName(componentKey.rawValue), expectedSwiftTypeName)
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

    func testTypeNameForReferenceProperties() throws {
        let parent = TypeName(swiftKeyPath: ["MyType"])
        let components: OpenAPI.Components = .init(schemas: [
            "SomeString": .string(),
            "MaybeString": .one(of: [.reference(.component(named: "SomeString")), .null()]),
        ])
        func assertTypeName(_ property: String, _ schema: JSONSchema, _ typeName: String, file: StaticString = #file, line: UInt = #line) throws {
            let actual = try typeAssigner.typeUsage(
                forObjectPropertyNamed: property,
                withSchema: schema,
                components: components,
                inParent: parent
            ).fullyQualifiedSwiftName
            XCTAssertEqual(typeName, actual, file: file, line: line)
        }
        try assertTypeName("someString", .reference(.component(named: "SomeString")), "Components.Schemas.SomeString")
        try assertTypeName("maybeString", .reference(.component(named: "MaybeString")), "Components.Schemas.MaybeString")
        try assertTypeName("optionalSomeString", .reference(.component(named: "SomeString"), required: false), "Components.Schemas.SomeString?")
        try assertTypeName("optionalMaybeString", .reference(.component(named: "MaybeString"), required: false), "Components.Schemas.MaybeString")
    }

    func testContentSwiftName() throws {
        let nameMaker = makeTranslator().typeAssigner.contentSwiftName
        let cases: [(String, String)] = [

            // Short names.
            ("application/json", "json"), ("application/x-www-form-urlencoded", "urlEncodedForm"),
            ("multipart/form-data", "multipartForm"), ("text/plain", "plainText"), ("*/*", "any"),
            ("application/xml", "xml"), ("application/octet-stream", "binary"), ("text/html", "html"),
            ("application/yaml", "yaml"), ("text/csv", "csv"), ("image/png", "png"), ("application/pdf", "pdf"),
            ("image/jpeg", "jpeg"),

            // Generic names.
            ("application/myformat+json", "application_myformat_plus_json"), ("foo/bar", "foo_bar"),

            // Names with a parameter.
            ("application/foo", "application_foo"),
            ("application/foo; bar=baz; boo=foo", "application_foo_bar_baz_boo_foo"),
            ("application/foo; bar = baz", "application_foo_bar_baz"),
        ]
        for (string, name) in cases {
            let contentType = try XCTUnwrap(ContentType(string: string))
            XCTAssertEqual(nameMaker(contentType), name, "Case \(string) failed")
        }
    }
}
