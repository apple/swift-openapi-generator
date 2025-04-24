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
                    "warning: Schema warning: Inconsistency encountered when parsing `OpenAPI Schema`: Found schema attributes not consistent with the type specified: string. Specifically, attributes for these other types: [\"array\"]. [context: codingPath=, contextString=, subjectName=OpenAPI Schema]"
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
    
    func testSchemaTypeSubstitution() throws {
        let typeName = TypeName(swiftKeyPath: ["Foo"])

        let schema = try loadSchemaFromYAML(
            #"""
            type: string
            x-swift-open-api-substitute-type: MyLibrary.MyCustomType
            """#
        )
        let collector = AccumulatingDiagnosticCollector()
        let translator = makeTranslator(diagnostics: collector)
        let translated = try translator.translateSchema(typeName: typeName, schema: schema, overrides: .none)

        XCTAssertEqual(
            collector.diagnostics.map(\.description),
            ["note: Substituting type Foo with MyLibrary.MyCustomType"]
        )
        XCTAssertTrue(translated.count == 1, "Should have one translated schema")
        guard case let .typealias(typeAliasDescription) = translated.first?.strippingTopComment else {
            XCTFail("Expected typealias description got")
            return
        }
        XCTAssertEqual(typeAliasDescription.name, "Foo")
        XCTAssertEqual(typeAliasDescription.existingType, .member(["MyLibrary", "MyCustomType"]))
    }
}
