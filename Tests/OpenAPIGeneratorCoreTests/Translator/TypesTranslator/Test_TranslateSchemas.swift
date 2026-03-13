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
import Testing
import OpenAPIKit
import Yams
@testable import _OpenAPIGeneratorCore


@Suite("Traslation Schemas Tests")
struct TranslateSchemaTests {
    
    @Test("Schema warnings are forwarded to generator diagnostics")
    func testSchemaWarningsForwardedToGeneratorDiagnostics() throws {
        let typeName = TypeName(swiftKeyPath: ["Foo"])

        let schemaWithWarnings = try TestFixtures.loadSchemaFromYAML(
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
                    "warning: Schema warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: string. Specifically, attributes for these other types: [\"array\"]. [context: codingPath=, contextString=, subjectName=OpenAPI Schema]"
                ]
            ),
        ]

        for (schema, diagnosticDescriptions) in cases {
            let collector = AccumulatingDiagnosticCollector()
            
            let translator = TestFixtures.makeTranslator(diagnostics: collector)
            _ = try translator.translateSchema(typeName: typeName, schema: schema, overrides: .none)
            #expect(collector.diagnostics.map(\.description) == diagnosticDescriptions)
        }
    }
}
