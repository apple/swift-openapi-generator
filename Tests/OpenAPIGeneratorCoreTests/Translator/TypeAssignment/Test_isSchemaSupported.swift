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
@preconcurrency import OpenAPIKit
@testable import _OpenAPIGeneratorCore

class Test_isSchemaSupported: XCTestCase {

    var translator: any FileTranslator {
        TypesFileTranslator(
            config: .init(mode: .types, access: Config.defaultAccessModifier),
            diagnostics: PrintingDiagnosticCollector(),
            components: .init(schemas: [
                "Foo": .string, "MyObj": .object, "MyObj2": .object,
                "MyNestedObjectishOneOf": .one(of: [.object(properties: ["foo": .string])]),
                "MyNestedAllOf": .all(of: [.object(properties: ["foo": .string])]),
                "MyNestedAnyOf": .any(of: [.object(properties: ["foo": .string])]),
            ])
        )
    }

    static let supportedTypes: [JSONSchema] = [
        // a string enum
        .string(allowedValues: [AnyCodable("Foo")]),

        // an int enum
        .integer(allowedValues: [AnyCodable(1)]),

        // an object with at least one property
        .object(properties: ["Foo": .string]),

        // a reference
        .reference(.component(named: "Foo")),

        // an array with a non-builtin type
        .array(.init(), .init(items: .reference(.component(named: "Foo")))),

        // double-nested array with non-builtin type
        .array(.init(), .init(items: .array(.init(), .init(items: .reference(.component(named: "Foo")))))),

        // allOf with many schemas
        .all(of: [
            .object(properties: ["Foo": .string]), .reference(.component(named: "MyObj")), .string,
            .array(items: .string),
        ]),

        // oneOf with a discriminator with a few objectish schemas and two (ignored) inline schemas
        .one(
            of: .reference(.component(named: "MyObj")),
            .reference(.component(named: "MyObj2")),
            .reference(.component(named: "MyNestedAllOf")),
            .reference(.component(named: "MyNestedAnyOf")),
            .reference(.component(named: "MyNestedObjectishOneOf")),

            .object,
            .boolean,
            discriminator: .init(propertyName: "foo")
        ),

        // oneOf without a discriminator with various schemas
        .one(of: [
            .object(properties: ["Foo": .string]), .reference(.component(named: "MyObj")), .string,
            .array(items: .string),
        ]),

        // anyOf with various schemas
        .any(of: [
            .object(properties: ["Foo": .string]), .reference(.component(named: "MyObj")), .string,
            .array(items: .string),
        ]),
    ]
    func testSupportedTypes() throws {
        let translator = self.translator
        for schema in Self.supportedTypes {
            var referenceStack = ReferenceStack.empty
            XCTAssertTrue(
                try translator.isSchemaSupported(schema, referenceStack: &referenceStack) == .supported,
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
    ]
    func testUnsupportedTypes() throws {
        let translator = self.translator
        for (schema, expectedReason) in Self.unsupportedTypes {
            var referenceStack = ReferenceStack.empty
            guard
                case let .unsupported(reason, _) = try translator.isSchemaSupported(
                    schema,
                    referenceStack: &referenceStack
                )
            else {
                XCTFail("Expected schema to be unsupported: \(schema)")
                return
            }
            XCTAssertEqual(reason, expectedReason)
        }
    }
}
