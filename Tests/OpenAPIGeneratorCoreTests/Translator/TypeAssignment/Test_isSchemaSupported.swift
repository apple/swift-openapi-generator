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

        // allOf with two schemas
        .all(of: [
            .object(properties: [
                "Foo": .string
            ]),
            .reference(.component(named: "MyObj")),
        ]),

        // oneOf with two schemas
        .one(of: [
            .object(properties: [
                "Foo": .string
            ]),
            .reference(.component(named: "MyObj")),
        ]),

        // anyOf with two schemas
        .any(of: [
            .object(properties: [
                "Foo": .string
            ]),
            .reference(.component(named: "MyObj")),
        ]),
    ]
    func testSupportedTypes() throws {
        let translator = self.translator
        for schema in Self.supportedTypes {
            XCTAssertTrue(
                try translator.isSchemaSupported(schema),
                "Expected schema to be supported: \(schema)"
            )
        }
    }

    static let unsupportedTypes: [JSONSchema] = [
        // a not
        .not(.string)
    ]
    func testUnsupportedTypes() throws {
        let translator = self.translator
        for schema in Self.unsupportedTypes {
            XCTAssertFalse(
                try translator.isSchemaSupported(schema),
                "Expected schema to be unsupported: \(schema)"
            )
        }
    }
}
