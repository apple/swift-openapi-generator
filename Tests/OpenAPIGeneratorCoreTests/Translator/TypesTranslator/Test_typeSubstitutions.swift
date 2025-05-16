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

class Test_typeSubstitutions: Test_Core {

    func testSchemaString() throws {
        func _test(
            schema schemaString: String,
            expectedType: ExistingTypeDescription,
            file: StaticString = #file,
            line: UInt = #line
        ) throws {
            let typeName = TypeName(swiftKeyPath: ["Foo"])

            let schema = try loadSchemaFromYAML(schemaString)
            let collector = AccumulatingDiagnosticCollector()
            let translator = makeTranslator(diagnostics: collector)
            let translated = try translator.translateSchema(typeName: typeName, schema: schema, overrides: .none)
            if translated.count != 1 {
                XCTFail("Expected only a single translated schema, got: \(translated.count)", file: file, line: line)
                return
            }
            XCTAssertTrue(translated.count == 1, "Should have one translated schema")
            guard case let .typealias(typeAliasDescription) = translated.first?.strippingTopComment else {
                XCTFail("Expected typealias description got", file: file, line: line)
                return
            }
            XCTAssertEqual(typeAliasDescription.name, "Foo", file: file, line: line)
            XCTAssertEqual(typeAliasDescription.existingType, expectedType, file: file, line: line)
        }
        try _test(
            schema: #"""
                type: string
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """#,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
        try _test(
            schema: """
                type: array
                items:
                  type: integer
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
        try _test(
            schema: """
                type: string
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
        try _test(
            schema: """
                type: array
                items:
                  type: integer
                  x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .array(.member(["MyLibrary", "MyCustomType"]))
        )
        // TODO: Investigate if vendor-extensions are allowed in anyOf, allOf, oneOf
        try _test(
            schema: """
                anyOf:
                - type: string
                - type: integer
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
        try _test(
            schema: """
                allOf:
                - type: object
                  properties:
                    foo:
                      type: string
                - type: object
                  properties:
                    bar:
                      type: string
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
        try _test(
            schema: """
                oneOf:
                - type: object
                  properties:
                    foo:
                      type: string
                - type: object
                  properties:
                    bar:
                      type: string
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
    }
    func testSimpleInlinePropertiesReplacements() throws {
        func _testInlineProperty(
            schema schemaString: String,
            expectedType: ExistingTypeDescription,
            file: StaticString = #file,
            line: UInt = #line
        ) throws {
            let typeName = TypeName(swiftKeyPath: ["Foo"])

            let propertySchema = try YAMLDecoder().decode(JSONSchema.self, from: schemaString).requiredSchemaObject()
            let schema = JSONSchema.object(properties: ["property": propertySchema])
            let collector = AccumulatingDiagnosticCollector()
            let translator = makeTranslator(diagnostics: collector)
            let translated = try translator.translateSchema(typeName: typeName, schema: schema, overrides: .none)
            if translated.count != 1 {
                XCTFail("Expected only a single translated schema, got: \(translated.count)", file: file, line: line)
                return
            }
            guard case let .struct(structDescription) = translated.first?.strippingTopComment else {
                throw GenericError(message: "Expected struct")
            }
            let variables: [VariableDescription] = structDescription.members.compactMap { member in
                guard case let .variable(variableDescription) = member.strippingTopComment else { return nil }
                return variableDescription
            }
            if variables.count != 1 {
                XCTFail("Expected only a single variable, got: \(variables.count)", file: file, line: line)
                return
            }
            XCTAssertEqual(variables[0].type, expectedType, file: file, line: line)
        }
        try _testInlineProperty(
            schema: """
                type: array
                items:
                  type: integer
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
        try _testInlineProperty(
            schema: """
                type: string
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
        try _testInlineProperty(
            schema: """
                type: array
                items:
                  type: integer
                  x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .array(.member(["MyLibrary", "MyCustomType"]))
        )
        // TODO: Investigate if vendor-extensions are allowed in anyOf, allOf, oneOf
        try _testInlineProperty(
            schema: """
                anyOf:
                - type: string
                - type: integer
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
        try _testInlineProperty(
            schema: """
                allOf:
                - type: object
                  properties:
                    foo:
                      type: string
                - type: object
                  properties:
                    bar:
                      type: string
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
        try _testInlineProperty(
            schema: """
                oneOf:
                - type: object
                  properties:
                    foo:
                      type: string
                - type: object
                  properties:
                    bar:
                      type: string
                x-swift-open-api-replace-type: MyLibrary.MyCustomType
                """,
            expectedType: .member(["MyLibrary", "MyCustomType"])
        )
    }
}
