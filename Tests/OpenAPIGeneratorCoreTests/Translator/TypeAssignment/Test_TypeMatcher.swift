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

final class Test_TypeMatcher: Test_Core {

    /// Setup method called before the invocation of each test method in the class.
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    static let builtinTypes: [(JSONSchema, String)] = [
        (.string, "Swift.String"), (.string(contentEncoding: .binary), "OpenAPIRuntime.HTTPBody"),
        (.string(contentEncoding: .base64), "OpenAPIRuntime.Base64EncodedData"),
        (.string(.init(format: .date), .init()), "Swift.String"),
        (.string(.init(format: .dateTime), .init()), "Foundation.Date"),

        (.integer, "Swift.Int"), (.integer(.init(format: .int32), .init()), "Swift.Int32"),
        (.integer(.init(format: .int64), .init()), "Swift.Int64"),

        (.number, "Swift.Double"), (.number(.init(format: .float), .init()), "Swift.Float"),
        (.number(.init(format: .double), .init()), "Swift.Double"),

        (.boolean, "Swift.Bool"),

        (.fragment, "OpenAPIRuntime.OpenAPIValueContainer"),

        // array with a single level of nesting that contains a builtin
        (.array(.init(), .init(items: .string)), "[Swift.String]"),

        // Only an object without any properties is mapped this way
        (.object, "OpenAPIRuntime.OpenAPIObjectContainer"),

        // an array with double nested string
        (.array(.init(), .init(items: .array(.init(), .init(items: .string)))), "[[Swift.String]]"),
    ]
    func testBuiltinTypes() {
        for (schema, name) in Self.builtinTypes {
            XCTAssertEqual(typeMatcher.tryMatchBuiltinType(for: schema.value)?.fullyQualifiedSwiftName, name)
        }
    }

    static let nonBuiltinTypes: [JSONSchema] = [
        // a string enum
        .string(allowedValues: [AnyCodable("Foo")]),
        // an int enum
        .integer(allowedValues: [AnyCodable(1)]),

        // an object with at least one property
        .object(properties: ["Foo": .string]),

        // an empty object with any non-nil additional properties value
        .object(additionalProperties: .boolean(true)), .object(additionalProperties: .boolean(false)),
        .object(additionalProperties: .schema(.integer)),

        // allOf with two schemas
        .all(of: [.object(properties: ["Foo": .string]), .reference(.component(named: "Bar"))]),

        // oneOf with two schemas
        .one(of: [.object(properties: ["Foo": .string]), .reference(.component(named: "Bar"))]),

        // anyOf with two schemas
        .any(of: [.object(properties: ["Foo": .string]), .reference(.component(named: "Bar"))]),

        // a reference
        .reference(.component(named: "Foo")),

        // an array with a non-builtin type
        .array(.init(), .init(items: .reference(.component(named: "Foo")))),

        // double-nested array with non-builtin type
        .array(.init(), .init(items: .array(.init(), .init(items: .reference(.component(named: "Foo")))))),

        // a not
        .not(.string),

        // an allof
        .all(of: []),

        // an anyof
        .any(of: []),

        // a oneof
        .one(of: []),
    ]
    func testNonBuiltinTypes() {
        for schema in Self.nonBuiltinTypes {
            XCTAssertNil(
                typeMatcher.tryMatchBuiltinType(for: schema.value),
                "Type is expected to not match a builtin type: \(schema)"
            )
        }
    }

    static let referenceableTypes: [(JSONSchema, String)] =
        builtinTypes + [
            // soundness check – calls out to builtin types
            (.string, "Swift.String"),

            // reference
            (.reference(.component(named: "Foo")), "Components.Schemas.Foo"),

            // an array of referenceable types
            (.array(.init(), .init(items: .reference(.component(named: "Foo")))), "[Components.Schemas.Foo]"),
        ]
    func testReferenceableTypes() {
        for (schema, name) in Self.referenceableTypes {
            try XCTAssertEqual(
                XCTUnwrap(
                    typeMatcher.tryMatchReferenceableType(for: schema, components: components),
                    "Expected schema to be referenceable: \(schema)"
                )
                .fullyQualifiedSwiftName,
                name
            )
            XCTAssertTrue(typeMatcher.isReferenceable(schema))
            XCTAssertFalse(typeMatcher.isInlinable(schema))
        }
    }

    static let nonReferenceableTypes: [JSONSchema] = [
        // a soundness check – string enum
        .string(allowedValues: ["Foo"]),

        // an array with a nested enum
        .array(.init(), .init(items: .string(.init(allowedValues: ["a", "b"]), .init()))),
    ]
    func testNonReferenceableTypes() {
        for schema in Self.nonReferenceableTypes {
            XCTAssertNil(
                typeMatcher.tryMatchBuiltinType(for: schema.value),
                "Type is expected to not match a builtin type: \(schema)"
            )
            XCTAssertFalse(typeMatcher.isReferenceable(schema), "Expected schema not to be referenceable: \(schema)")
            XCTAssertTrue(typeMatcher.isInlinable(schema), "Expected schema to be inlinable: \(schema)")
        }
    }

    let components: OpenAPI.Components = .init(schemas: ["Foo": .string, "MyObj": .object])

    static let keyValuePairTypes: [JSONSchema] = [
        // an object with at least one property
        .object(properties: ["Foo": .string]),

        // a fragment
        .fragment,

        // allOf with two object schemas
        .all(of: [.object(properties: ["Foo": .string]), .reference(.component(named: "MyObj"))]),

        // oneOf with one object schema and one primitive
        .one(of: [.object(properties: ["Foo": .string]), .integer]),

        // anyOf with one object schema and one primitive
        .any(of: [.object(properties: ["Foo": .string]), .integer]),

        // a reference to an object
        .reference(.component(named: "MyObj")),
    ]
    func testKeyValuePairTypes() {
        for schema in Self.keyValuePairTypes {
            var referenceStack = ReferenceStack.empty
            XCTAssertTrue(
                try typeMatcher.isKeyValuePair(schema, referenceStack: &referenceStack, components: components),
                "Type is expected to be a key-value pair schema: \(schema)"
            )
        }
    }

    static let nonKeyValuePairTypes: [JSONSchema] = [
        // a string enum
        .string(allowedValues: [AnyCodable("Foo")]),

        // an int enum
        .integer(allowedValues: [AnyCodable(1)]),

        // allOf with one non-object schema
        .all(of: [.object(properties: ["Foo": .string]), .integer]),

        // oneOf with only non-object schemas
        .one(of: [.integer, .string]),

        // anyOf with only non-object schemas
        .any(of: [.integer, .string]),

        // a reference to a string
        .reference(.component(named: "Foo")),

        // an array with a non-builtin type
        .array(.init(), .init(items: .reference(.component(named: "Foo")))),

        // a not
        .not(.string),
    ]
    func testNonkeyValuePairTypes() {
        for schema in Self.nonKeyValuePairTypes {
            XCTAssertNil(
                typeMatcher.tryMatchBuiltinType(for: schema.value),
                "Type is expected to not match a builtin type: \(schema)"
            )
        }
    }

    static let optionalTestCases: [(JSONSchema, Bool)] = [

        // A required string.
        (.string, false), (.string(required: true, nullable: false), false),

        // An optional string.
        (.string(required: false, nullable: false), true), (.string(required: true, nullable: true), true),
        (.string(required: false, nullable: true), true),

        // A reference pointing to a required schema.
        (.reference(.component(named: "RequiredString")), false),
        (.reference(.component(named: "NullableString")), true),
    ]
    func testOptionalSchemas() throws {
        let components = OpenAPI.Components(schemas: [
            "RequiredString": .string, "NullableString": .string(nullable: true),
        ])
        for (schema, expectedIsOptional) in Self.optionalTestCases {
            let actualIsOptional = try typeMatcher.isOptional(schema, components: components)
            XCTAssertEqual(
                actualIsOptional,
                expectedIsOptional,
                "Schema optionaly mismatch: \(schema.prettyDescription), expected: \(expectedIsOptional), actual: \(actualIsOptional)"
            )
        }
    }

    static let multipartElementTypeReferenceIfReferenceableTypes:
        [(UnresolvedSchema?, OrderedDictionary<String, OpenAPI.Content.Encoding>?, String?)] = [
            (nil, nil, nil), (.b(.string), nil, nil), (.a(.component(named: "Foo")), nil, "Foo"),
            (.a(.component(named: "Foo")), ["foo": .init(contentType: .json)], nil),
        ]
    func testMultipartElementTypeReferenceIfReferenceableTypes() throws {
        for (schema, encoding, name) in Self.multipartElementTypeReferenceIfReferenceableTypes {
            let actualName = typeMatcher.multipartElementTypeReferenceIfReferenceable(
                schema: schema,
                encoding: encoding
            )?
            .name
            XCTAssertEqual(actualName, name)
        }
    }
}
