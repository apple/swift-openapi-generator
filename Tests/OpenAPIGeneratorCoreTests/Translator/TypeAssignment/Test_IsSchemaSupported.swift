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
@preconcurrency import OpenAPIKit
import Testing
@testable import _OpenAPIGeneratorCore

    
@Suite("Is Schema Supported Tests")
struct Test_IsSchemaSupported {

    var translator: any FileTranslator {
        TypesFileTranslator(
            config: .init(
                mode: .types,
                access: Config.defaultAccessModifier,
                namingStrategy: Config.defaultNamingStrategy
            ),
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
        .string(allowedValues: [AnyCodable("Foo")]),
        .integer(allowedValues: [AnyCodable(1)]),
        .object(properties: ["Foo": .string]),
        .reference(.component(named: "Foo")),
        .array(.init(), .init(items: .reference(.component(named: "Foo")))),
        .array(.init(), .init(items: .array(.init(), .init(items: .reference(.component(named: "Foo")))))),
        .all(of: [
            .object(properties: ["Foo": .string]), .reference(.component(named: "MyObj")), .string,
            .array(items: .string),
        ]),
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
        .one(of: [
            .object(properties: ["Foo": .string]), .reference(.component(named: "MyObj")), .string,
            .array(items: .string),
        ]),
        .any(of: [
            .object(properties: ["Foo": .string]), .reference(.component(named: "MyObj")), .string,
            .array(items: .string),
        ]),
    ]
    
    @Test("Schema is supported Tests")
    func testSupportedTypes() throws {
        let translator = self.translator
        for schema in Self.supportedTypes {
            var referenceStack = ReferenceStack.empty
            #expect(
                try translator.isSchemaSupported(schema, referenceStack: &referenceStack) == .supported,
                "Expected schema to be supported: (schema)"
            )
        }
    }

    static let unsupportedTypes: [(JSONSchema, IsSchemaSupportedResult.UnsupportedReason)] = [
        (.not(.string), .schemaType),
        (.all(of: []), .noSubschemas),
        (.one(of: .reference(.internal(.component(name: "Foo"))), discriminator: .init(propertyName: "foo")), .notObjectish),
    ]
    
    @Test("Schema is unsupported Tests")
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
                #expect(Bool(false), "Expected schema to be unsupported: (schema)")
                return
            }
            #expect(reason == expectedReason)
        }
    }
}
