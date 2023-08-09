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

class Test_isSchemaSupported: XCTestCase {

    var translator: any FileTranslator {
        TypesFileTranslator(
            config: .init(mode: .types),
            diagnostics: PrintingDiagnosticCollector(),
            components: .init(schemas: [
                "Foo": .string,
                "MyObj": .object,
                "MyObj2": .object,
            ])
        )
    }

    static let supportedTypes: [JSONSchema] = [
        // a string enum
        .string(allowedValues: [
            AnyCodable("Foo")
        ]),

        // an object with at least one property
        .object(properties: [
            "Foo": .string
        ]),

        // a reference
        .reference(.component(named: "Foo")),

        // an array with a non-builtin type
        .array(
            .init(),
            .init(items: .reference(.component(named: "Foo")))
        ),

        // double-nested array with non-builtin type
        .array(
            .init(),
            .init(
                items:
                    .array(
                        .init(),
                        .init(items: .reference(.component(named: "Foo")))
                    )
            )
        ),

        // allOf with many schemas
        .all(of: [
            .object(properties: [
                "Foo": .string
            ]),
            .reference(.component(named: "MyObj")),
            .string,
            .array(items: .string),
        ]),

        // oneOf with a discriminator with two objectish schemas
        .one(
            of: .reference(.component(named: "MyObj")),
            .reference(.component(named: "MyObj2")),
            discriminator: .init(propertyName: "foo")
        ),

        // oneOf without a discriminator with various schemas
        .one(of: [
            .object(properties: [
                "Foo": .string
            ]),
            .reference(.component(named: "MyObj")),
            .string,
            .array(items: .string),
        ]),

        // anyOf with various schemas
        .any(of: [
            .object(properties: [
                "Foo": .string
            ]),
            .reference(.component(named: "MyObj")),
            .string,
            .array(items: .string),
        ]),
    ]
    func testSupportedTypes() throws {
        let translator = self.translator
        for schema in Self.supportedTypes {
            XCTAssertTrue(
                try translator.isSchemaSupported(schema) == .supported,
                "Expected schema to be supported: \(schema)"
            )
        }
    }

    static let unsupportedTypes: [(JSONSchema, IsSchemaSupportedResult.UnsupportedReason)] = [
        // a not
        (.not(.string), .schemaType),

        // an allOf without any subschemas
        (.all(of: []), .noSubschemas),

        // a oneOf with a discriminator with non-object-ish schemas
        (
            .one(of: .reference(.internal(.component(name: "Foo"))), discriminator: .init(propertyName: "foo")),
            .notObjectish
        ),

        // a oneOf with a discriminator with an inline subschema
        (.one(of: .object, discriminator: .init(propertyName: "foo")), .notRef),
    ]
    func testUnsupportedTypes() throws {
        let translator = self.translator
        for (schema, expectedReason) in Self.unsupportedTypes {
            guard case let .unsupported(reason, _) = try translator.isSchemaSupported(schema) else {
                XCTFail("Expected schema to be unsupported: \(schema)")
                return
            }
            XCTAssertEqual(reason, expectedReason)
        }
    }
}
