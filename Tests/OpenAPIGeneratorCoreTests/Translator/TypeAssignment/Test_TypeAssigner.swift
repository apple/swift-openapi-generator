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
import OpenAPIKit30
@testable import _OpenAPIGeneratorCore

class Test_TypeAssigner: Test_Core {

    func testTypeNameForReferences() throws {
        try XCTAssertEqual(
            TypeAssigner.typeName(for: JSONReference<JSONSchema>.component(named: "mumble")),
            newTypeName(
                swiftFQName: "Components.Schemas.mumble",
                jsonFQName: "#/components/schemas/mumble"
            )
        )
        try XCTAssertEqual(
            TypeAssigner.typeName(for: JSONReference<ResolvedParameter>.component(named: "mumble")),
            newTypeName(
                swiftFQName: "Components.Parameters.mumble",
                jsonFQName: "#/components/parameters/mumble"
            )
        )
        try XCTAssertEqual(
            TypeAssigner.typeName(for: JSONReference<OpenAPI.Header>.component(named: "mumble")),
            newTypeName(
                swiftFQName: "Components.Headers.mumble",
                jsonFQName: "#/components/headers/mumble"
            )

        )
        try XCTAssertEqual(
            TypeAssigner.typeName(for: JSONReference<ResolvedRequestBody>.component(named: "mumble")),
            newTypeName(
                swiftFQName: "Components.RequestBodies.mumble",
                jsonFQName: "#/components/requestBodies/mumble"
            )

        )
        try XCTAssertEqual(
            TypeAssigner.typeName(for: JSONReference<OpenAPI.Response>.component(named: "mumble")),
            newTypeName(
                swiftFQName: "Components.Responses.mumble",
                jsonFQName: "#/components/responses/mumble"
            )
        )
    }

    func testTypeNameForComponentKeys() {
        let expectedSchemaTypeNames: [OpenAPI.ComponentKey: String] = [
            // camel-casing behaviour
            "customtype": "customtype",
            "customType": "customType",
            "custom_type": "custom_type",
            "custom__type": "custom__type",
            "custom_type_": "custom_type_",
            // preserve leading underscores
            "_custom_type": "_custom_type",
            "__custom__type": "__custom__type",
            // sanitization
            "1customtype": "_1customtype",
            "custom.type": "custom_type",
            ".custom$type": "_custom_type",
            // keywords
            "enum": "_enum",
        ]
        for (componentKey, expectedSwiftTypeName) in expectedSchemaTypeNames {
            XCTAssertEqual(componentKey.shortSwiftName, expectedSwiftTypeName)
        }
    }

    func testTypeNameForComponentPairs() throws {
        let components = OpenAPI.Components(
            schemas: [
                "my_reusable_schema": .object
            ]
        )
        XCTAssertEqual(
            components.schemas.map(TypeAssigner.typeName(for:)),
            [
                try newTypeName(
                    swiftFQName: "Components.Schemas.my_reusable_schema",
                    jsonFQName: "#/components/schemas/my_reusable_schema"
                )
            ]
        )
    }

    func testTypeNameForNamedComponent() throws {
        let expected: [(String, TypeLocation, String)] = [
            (
                "Foo",
                .schemas,
                "Components.Schemas.Foo"
            )
        ]
        for (originalName, location, typeNameString) in expected {
            XCTAssertEqual(
                TypeAssigner
                    .typeName(
                        forComponentOriginallyNamed: originalName,
                        in: location
                    )
                    .fullyQualifiedSwiftName,
                typeNameString
            )
        }
    }

    func testTypeNameForObjectProperties() throws {
        let parent = TypeName(swiftKeyPath: ["MyType"])
        let expected: [(String, JSONSchema, String)] = [
            (
                "foo",
                .object(
                    .init(),
                    .init(properties: [
                        "bar": .string
                    ])
                ),
                "MyType.fooPayload"
            )
        ]
        for (originalName, schema, typeNameString) in expected {
            try XCTAssertEqual(
                TypeAssigner.typeUsage(
                    forObjectPropertyNamed: originalName,
                    withSchema: schema,
                    inParent: parent
                )
                .fullyQualifiedSwiftName,
                typeNameString
            )
        }
    }
}
