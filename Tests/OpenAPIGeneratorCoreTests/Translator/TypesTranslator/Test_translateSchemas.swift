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
import Yams
@testable import _OpenAPIGeneratorCore

class Test_translateSchemas: Test_Core {

    func testSchemaWarningsForwardedToGeneratorDiagnostics() throws {
        let typeName = TypeName(swiftKeyPath: ["Foo"])

        let schemaWithWarnings = try loadSchemaFromYAML(
            #"""
            type: string
            items:
              type: integer
            """#
        )

        let cases: [(JSONSchema, [String])] = [
            (.string, []),

            (
                schemaWithWarnings,
                [
                    "warning: Schema warning: Problem encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: string. Specifically, attributes for these other types: [\"array\"]. [context: codingPath=, contextString=, subjectName=OpenAPI Schema]"
                ]
            ),
        ]

        for (schema, diagnosticDescriptions) in cases {
            let collector = AccumulatingDiagnosticCollector()
            let translator = makeTranslator(diagnostics: collector)
            _ = try translator.translateSchema(typeName: typeName, schema: schema, overrides: .none)
            XCTAssertEqual(collector.diagnostics.map(\.description), diagnosticDescriptions)
        }
    }

    func testDuplicateGeneratedNameEmitsErrorInsteadOfCrashing() throws {
        // Two distinct OpenAPI schema names that the idiomatic naming strategy
        // collapses to the same Swift type name ("NullTime"). Previously this
        // trapped in `Dictionary(uniqueKeysWithValues:)` while boxing recursive
        // types; now it should surface as a clear error diagnostic instead.
        let components = OpenAPI.Components(schemas: [
            "NullTime": .object(properties: ["value": .string]), "nullTime": .object(properties: ["value": .string]),
        ])
        let collector = AccumulatingDiagnosticCollector()
        let translator = makeTranslator(components: components, diagnostics: collector, namingStrategy: .idiomatic)
        _ = try translator.translateSchemas(components.schemas, multipartSchemaNames: [])
        let errors = collector.diagnostics.filter { $0.severity == .error }
        XCTAssertEqual(errors.count, 1)
        let error = try XCTUnwrap(errors.first)
        XCTAssertEqual(error.context["name"], "NullTime")
        XCTAssertTrue(
            error.message.contains("map to the same generated Swift type name 'NullTime'"),
            "Unexpected error message: \(error.message)"
        )
    }

    func testMultipleDuplicateGeneratedNamesAreReportedInASingleError() throws {
        // Two independent pairs of OpenAPI schema names each collapse to the
        // same Swift type name ("FullName" and "NullTime"). A single error
        // should list both colliding names rather than stopping at the first.
        let components = OpenAPI.Components(schemas: [
            "NullTime": .object(properties: ["value": .string]), "nullTime": .object(properties: ["value": .string]),
            "FullName": .object(properties: ["value": .string]), "fullName": .object(properties: ["value": .string]),
        ])
        let collector = AccumulatingDiagnosticCollector()
        let translator = makeTranslator(components: components, diagnostics: collector, namingStrategy: .idiomatic)
        _ = try translator.translateSchemas(components.schemas, multipartSchemaNames: [])
        let errors = collector.diagnostics.filter { $0.severity == .error }
        XCTAssertEqual(errors.count, 1)
        let error = try XCTUnwrap(errors.first)
        XCTAssertEqual(error.context["names"], "'FullName', 'NullTime'")
        XCTAssertTrue(
            error.message.contains("map to the same generated Swift type names 'FullName', 'NullTime'"),
            "Unexpected error message: \(error.message)"
        )
    }

    func testDistinctGeneratedNamesEmitNoErrorWithIdiomaticNaming() throws {
        // Two schema names that the idiomatic naming strategy maps to distinct
        // Swift type names must not trigger the duplicate-name error.
        let components = OpenAPI.Components(schemas: [
            "null_time": .object(properties: ["value": .string]), "other_time": .object(properties: ["value": .string]),
        ])
        let collector = AccumulatingDiagnosticCollector()
        let translator = makeTranslator(components: components, diagnostics: collector, namingStrategy: .idiomatic)
        _ = try translator.translateSchemas(components.schemas, multipartSchemaNames: [])
        XCTAssertTrue(
            collector.diagnostics.filter { $0.severity == .error }.isEmpty,
            "Expected no error diagnostics, got: \(collector.diagnostics.map(\.description))"
        )
    }
}
