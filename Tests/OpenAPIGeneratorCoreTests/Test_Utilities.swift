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
import Foundation
import Yams
import OpenAPIKit
@testable import _OpenAPIGeneratorCore


/// A collection of helper utilities for Core translation testing.
///
/// This module provides standardized methods to configure and instantiate
/// `TypesFileTranslator` with common configurations. Import this file in
/// your test suites to reuse these helpers without creating instances.
struct TestFixtures {
    
    // MARK: - Helper Methods
    
    /// Creates a `TypesFileTranslator` with default or custom configuration.
    static func makeTranslator(
        components: OpenAPI.Components = .noComponents,
        diagnostics: any DiagnosticCollector = PrintingDiagnosticCollector(),
        namingStrategy: NamingStrategy = .defensive,
        nameOverrides: [String: String] = [:],
        schemaOverrides: [String: String] = [:],
        featureFlags: FeatureFlags = []
    ) -> TypesFileTranslator {
        makeTypesTranslator(
            components: components,
            diagnostics: diagnostics,
            namingStrategy: namingStrategy,
            nameOverrides: nameOverrides,
            schemaOverrides: schemaOverrides,
            featureFlags: featureFlags
        )
    }
    
    /// Creates a `TypesFileTranslator` with a pre-built config.
    static func makeTypesTranslator(
        components: OpenAPI.Components = .noComponents,
        diagnostics: any DiagnosticCollector = PrintingDiagnosticCollector(),
        namingStrategy: NamingStrategy = .defensive,
        nameOverrides: [String: String] = [:],
        schemaOverrides: [String: String] = [:],
        featureFlags: FeatureFlags = []
    ) -> TypesFileTranslator {
        TypesFileTranslator(
            config: makeConfig(
                namingStrategy: namingStrategy,
                nameOverrides: nameOverrides,
                schemaOverrides: schemaOverrides,
                featureFlags: featureFlags
            ),
            diagnostics: diagnostics,
            components: components
        )
    }
    
    /// Creates a default `Config` for types generation.
    static func makeConfig(
        namingStrategy: NamingStrategy = .defensive,
        nameOverrides: [String: String] = [:],
        schemaOverrides: [String: String] = [:],
        featureFlags: FeatureFlags = []
    ) -> Config {
        .init(
            mode: .types,
            access: Config.defaultAccessModifier,
            namingStrategy: namingStrategy,
            nameOverrides: nameOverrides,
            typeOverrides: TypeOverrides(schemas: schemaOverrides),
            featureFlags: featureFlags
        )
    }
    
    /// Decodes a JSONSchema from a YAML string.
    static func loadSchemaFromYAML(_ yamlString: String) throws -> JSONSchema {
        try YAMLDecoder().decode(JSONSchema.self, from: yamlString)
    }
    
    /// A predefined test TypeName for use in assertions.
    static var testTypeName: TypeName { .init(swiftKeyPath: ["Foo"]) }
    
    // MARK: - Convenience Properties
    
    /// Returns a TypeAssigner using default configuration.
    static var typeAssigner: TypeAssigner {
        makeTranslator().typeAssigner
    }
    
    /// Returns a TypeMatcher using default configuration.
    static var typeMatcher: TypeMatcher {
        makeTranslator().typeMatcher
    }
    
    /// Returns a TranslatorContext using default configuration.
    static var context: TranslatorContext {
        makeTranslator().context
    }
    
    /// Creates a PropertyBlueprint with the given name and type usage.
    static func makeProperty(originalName: String, typeUsage: TypeUsage) -> PropertyBlueprint {
        .init(originalName: originalName, typeUsage: typeUsage, context: context)
    }
}


/// Generates a detailed diff message for test failures when two YAML-encoded values differ.
///
/// Compares the line-by-line content of the two strings to identify the first point of divergence.
/// The resulting message includes both full values and highlights the specific line where they mismatch,
/// making it easier to debug equality assertions.
func generateDiffMessage(data1: String, data2: String) -> String {
    var messageLines: [String] = ["XCTAssertEqualCodable failed, values are not equal"]

    messageLines.append("=== Value 1 ===:\n\(data1.withLineNumberPrefixes)")
    messageLines.append("=== Value 2 ===:\n\(data2.withLineNumberPrefixes)")
    messageLines.append("=== Diff ===")

    let lines1 = data1.split(separator: "\n")
    let lines2 = data2.split(separator: "\n")

    for i in 0..<max(lines1.count, lines2.count) {
        if i < lines1.endIndex && i < lines2.endIndex {
            if lines1[i] == lines2[i] {
                continue
            } else {
                messageLines.append("First difference found at line \(i+1)")
                messageLines.append("< \(lines1[i])")
                messageLines.append("> \(lines2[i])")
            }
        } else {
            messageLines.append("First difference found at line \(i+1)")
            if i == lines1.endIndex {
                messageLines.append("< [END OF FILE]")
                if i < lines2.endIndex {
                    messageLines.append("> \(lines2[i])")
                }
            } else {
                if i < lines1.endIndex {
                    messageLines.append("< \(lines1[i])")
                }
                messageLines.append("> [END OF FILE]")
            }
        }
        break
    }

    return messageLines.joined(separator: "\n")
}


/// Asserts that two `Codable` values are equal by comparing their YAML representations.
///
/// This function encodes both values to YAML (with sorted keys) and compares the resulting
/// string representations. If the encoded outputs differ, it generates a diff message
/// to help identify the discrepancy. This is useful for testing data models where
/// structural equality matters more than direct `Equatable` conformance.
///
/// - Parameters:
///   - expression1: The first value to compare.
///   - expression2: The second value to compare.
///   - message: An optional custom message to display on failure.
///
/// - Note: Both values must conform to `Equatable` and `Encodable`. If encoding fails,
///   the assertion will record a failure with the encoding error details.
///
/// - Example:
///   ```swift
///   @Test func testModelsMatch() {
///       let model1 = MyModel(id: 1, name: "Test")
///       let model2 = MyModel(id: 1, name: "Test")
///       assertEqualCodable(model1, model2)
///   }
///   ```
///
/// - SeeAlso: ``generateDiffMessage(data1:data2:)``
func assertEqualCodable<T>(
    _ expression1: @autoclosure () -> T,
    _ expression2: @autoclosure () -> T,
    _ message: @autoclosure () -> String = ""
) where T: Equatable & Encodable {

    let value1 = expression1()
    let value2 = expression2()

    if value1 == value2 { return }

    let encoder = YAMLEncoder()
    encoder.options.sortKeys = true

    let data1: String
    let data2: String
    do {
        data1 = try encoder.encode(value1)
        data2 = try encoder.encode(value2)
    } catch {
        let errorMessage = Testing.Comment(stringLiteral: "Assertion failed: encoding to YAML")
        Issue.record(error, errorMessage)
        return
    }

    let diffMessage = generateDiffMessage(data1: data1, data2: data2)
    let errorMessage = Testing.Comment(stringLiteral: diffMessage.isEmpty ? message() : diffMessage)
    Issue.record(errorMessage)
}


/// Asserts that two arrays contain the same elements, regardless of order.
///
/// This function compares the contents of `expression1` and `expression2` after
/// sorting both arrays. It is useful for verifying that two collections contain
/// identical elements without requiring them to be in the same sequence.
///
/// - Parameters:
///   - expression1: The first collection to compare. Evaluated lazily.
///   - expression2: The second collection to compare. Evaluated lazily.
///   - message: An optional custom failure message. If not provided, a default
///     message is used.
///
/// - Note:
///   - Both arrays must contain elements conforming to `Comparable`.
///   - The function uses `#expect` from Swift's testing framework, so it is
///     intended for use within test cases.
///   - This comparison is order-insensitive: `[1, 2, 3]` and `[3, 1, 2]` are considered equal.
///
/// - Example:
///   ```swift
///   expectUnsortedEqual([1, 3, 2], [2, 1, 3])
///   expectUnsortedEqual([1, 2], [1, 2, 3], "Arrays should have the same elements")
///   ```
func expectUnsortedEqual<T>(
    _ expression1: @autoclosure () -> [T],
    _ expression2: @autoclosure () -> [T],
    _ message: @autoclosure () -> String = ""
) where T: Comparable {
    #expect(expression1().sorted() == expression2().sorted(), "\(message())")
}


/// Creates a `TypeName` instance by mapping a Swift fully qualified name to a JSON fully qualified name.
///
/// Both names are split by their respective separators (`. ` for Swift, `/` for JSON) and validated
/// to ensure they contain the same number of components. An optional JSON root marker (`#`) is
/// supported, is removed during validation, and does not require a corresponding Swift component.
///
/// - Parameter swiftFQName: The Swift fully qualified name (dot-separated).
/// - Parameter jsonFQName: The JSON fully qualified name (slash-separated).
/// - Returns: A `TypeName` constructed from the matched components.
/// - Throws: `TypeCreationError` if the component counts do not match or if the JSON name is empty.
func newTypeName(swiftFQName: String, jsonFQName: String) throws -> TypeName {
    var jsonComponents = jsonFQName.split(separator: "/").map(String.init)
    let swiftComponents = swiftFQName.split(separator: ".").map(String.init)
    
    guard !jsonComponents.isEmpty
    else { throw TypeCreationError(swift: swiftFQName, json: jsonFQName) }
    
    let hadJSONRoot = jsonComponents[0] == "#"
    if hadJSONRoot { jsonComponents.removeFirst() }
    
    struct TypeCreationError: Error, CustomStringConvertible, LocalizedError {
        var swift: String
        var json: String
        var description: String { "swift: \(swift), json: \(json)" }
        var errorDescription: String? { description }
    }
    
    guard swiftComponents.count == jsonComponents.count
    else { throw TypeCreationError(swift: swiftFQName, json: jsonFQName) }
    
    let jsonRoot: [TypeName.Component]
    if hadJSONRoot { jsonRoot = [.init(swift: nil, json: "#")] }
    else { jsonRoot = [] }
    
    return .init(components: jsonRoot + zip(swiftComponents, jsonComponents).map(TypeName.Component.init))
}


/// A concrete implementation of `DiagnosticCollector` that stores all emitted
/// diagnostics in a mutable array.
///
/// This collector is primarily intended for testing scenarios or batch
/// validation where all diagnostics need to be inspected after execution.
///
/// - Note: This class is **not thread-safe**. Concurrent modifications to
///   the `diagnostics` array may lead to undefined behavior.
final class AccumulatingDiagnosticCollector: DiagnosticCollector {
    private(set) var diagnostics: [Diagnostic] = []
    func emit(_ diagnostic: Diagnostic) { diagnostics.append(diagnostic) }
}
