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

    func testDuplicateGeneratedSchemaNamesThrowErrorDiagnostic() throws {
        let schemas: OpenAPI.ComponentDictionary<JSONSchema> = ["NullTime": .string, "nullTime": .string]
        let diagnostics = ErrorThrowingDiagnosticCollector(upstream: StdErrPrintingDiagnosticCollector())
        let translator = makeTranslator(
            components: .init(schemas: schemas),
            diagnostics: diagnostics,
            namingStrategy: .idiomatic
        )

        XCTAssertThrowsError(try translator.translateSchemas(schemas, multipartSchemaNames: [])) { error in
            guard let diagnostic = error as? Diagnostic else { return XCTFail("Expected a Diagnostic, got \(error)") }
            XCTAssertEqual(diagnostic.severity, .error)
            XCTAssertEqual(diagnostic.context, ["names": "'NullTime'"])
        }
    }

    func testDuplicateGeneratedSchemaNamesDoNotTrapWithNonThrowingCollector() throws {
        let schemas: OpenAPI.ComponentDictionary<JSONSchema> = ["NullTime": .string, "nullTime": .string]
        let collector = AccumulatingDiagnosticCollector()
        let translator = makeTranslator(
            components: .init(schemas: schemas),
            diagnostics: collector,
            namingStrategy: .idiomatic
        )

        _ = try translator.translateSchemas(schemas, multipartSchemaNames: [])

        XCTAssertEqual(
            collector.diagnostics.map(\.description),
            [
                "error: Multiple schemas in '#/components/schemas' map to the same generated Swift type names "
                    + "'NullTime', which is not supported. Use the 'defensive' naming strategy or add "
                    + "'nameOverrides' entries so every schema generates a unique name. [context: names='NullTime']"
            ]
        )
    }

    func testMultipleDuplicateGeneratedSchemaNamesAreReportedDeterministically() throws {
        let schemas: OpenAPI.ComponentDictionary<JSONSchema> = [
            "Zulu": .string, "zulu": .string, "Alpha": .string, "alpha": .string,
        ]
        let collector = AccumulatingDiagnosticCollector()
        let translator = makeTranslator(
            components: .init(schemas: schemas),
            diagnostics: collector,
            namingStrategy: .idiomatic
        )

        _ = try translator.translateSchemas(schemas, multipartSchemaNames: [])

        XCTAssertEqual(collector.diagnostics.count, 1)
        XCTAssertEqual(collector.diagnostics.first?.context, ["names": "'Alpha', 'Zulu'"])
    }

    func testDuplicateNestedBasenamesInDifferentNamespacesAreValid() throws {
        let schemas: OpenAPI.ComponentDictionary<JSONSchema> = [
            "A": .object(properties: ["t": .object(properties: ["value": .string])]),
            "B": .object(properties: ["t": .object(properties: ["value": .string])]),
        ]
        let collector = AccumulatingDiagnosticCollector()
        let translator = makeTranslator(
            components: .init(schemas: schemas),
            diagnostics: collector,
            namingStrategy: .idiomatic
        )

        let declaration = try translator.translateSchemas(schemas, multipartSchemaNames: [])

        guard case .enum(let schemasNamespace) = declaration.strippingTopComment else {
            return XCTFail("Expected the Components.Schemas namespace")
        }
        let topLevelNames = schemasNamespace.members.compactMap(\.name).sorted()
        let nestedNames = schemasNamespace.members
            .flatMap { declaration -> [String] in
                guard case .struct(let description) = declaration.strippingTopComment else { return [] }
                return description.members.compactMap(\.name).map { "\(description.name).\($0)" }
            }
            .filter { $0.hasSuffix(".TPayload") }.sorted()

        XCTAssertEqual(topLevelNames, ["A", "B"])
        XCTAssertEqual(nestedNames, ["A.TPayload", "B.TPayload"])
        XCTAssertTrue(collector.diagnostics.isEmpty)
    }
}
