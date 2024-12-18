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
import Foundation
import Yams
import OpenAPIKit
@testable import _OpenAPIGeneratorCore

class Test_Core: XCTestCase {

    /// Setup method called before the invocation of each test method in the class.
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    func makeTranslator(
        components: OpenAPI.Components = .noComponents,
        diagnostics: any DiagnosticCollector = PrintingDiagnosticCollector(),
        namingStrategy: NamingStrategy = .defensive,
        nameOverrides: [String: String] = [:],
        featureFlags: FeatureFlags = []
    ) -> TypesFileTranslator {
        makeTypesTranslator(
            components: components,
            diagnostics: diagnostics,
            namingStrategy: namingStrategy,
            nameOverrides: nameOverrides,
            featureFlags: featureFlags
        )
    }

    func makeTypesTranslator(
        components: OpenAPI.Components = .noComponents,
        diagnostics: any DiagnosticCollector = PrintingDiagnosticCollector(),
        namingStrategy: NamingStrategy = .defensive,
        nameOverrides: [String: String] = [:],
        featureFlags: FeatureFlags = []
    ) -> TypesFileTranslator {
        TypesFileTranslator(
            config: makeConfig(
                namingStrategy: namingStrategy,
                nameOverrides: nameOverrides,
                featureFlags: featureFlags
            ),
            diagnostics: diagnostics,
            components: components
        )
    }

    func makeConfig(
        namingStrategy: NamingStrategy = .defensive,
        nameOverrides: [String: String] = [:],
        featureFlags: FeatureFlags = []
    ) -> Config {
        .init(
            mode: .types,
            access: Config.defaultAccessModifier,
            namingStrategy: namingStrategy,
            nameOverrides: nameOverrides,
            featureFlags: featureFlags
        )
    }

    func loadSchemaFromYAML(_ yamlString: String) throws -> JSONSchema {
        try YAMLDecoder().decode(JSONSchema.self, from: yamlString)
    }

    static var testTypeName: TypeName { .init(swiftKeyPath: ["Foo"]) }

    var typeAssigner: TypeAssigner { makeTranslator().typeAssigner }

    var typeMatcher: TypeMatcher { makeTranslator().typeMatcher }

    var context: TranslatorContext { makeTranslator().context }

    func makeProperty(originalName: String, typeUsage: TypeUsage) -> PropertyBlueprint {
        .init(originalName: originalName, typeUsage: typeUsage, context: context)
    }
}

func XCTAssertEqualCodable<T>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) where T: Equatable & Encodable {

    let value1: T
    let value2: T
    do {
        value1 = try expression1()
        value2 = try expression2()
    } catch {
        XCTFail(
            "XCTAssertEqualCodable expression evaluation threw an error: \(error.localizedDescription)",
            file: file,
            line: line
        )
        return
    }

    // If objects aren't equal, convert both into Yaml and diff them in that representation
    if value1 == value2 { return }

    let encoder = YAMLEncoder()
    encoder.options.sortKeys = true

    let data1: String
    let data2: String
    do {
        data1 = try encoder.encode(value1)
        data2 = try encoder.encode(value2)
    } catch {
        XCTFail(
            "XCTAssertEqualCodable encoding to Yaml threw an error: \(error.localizedDescription)",
            file: file,
            line: line
        )
        return
    }

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
            // We hit the end of one of the sequences
            messageLines.append("First difference found at line \(i+1)")
            if i == lines1.endIndex {
                messageLines.append("< [END OF FILE]")
                messageLines.append("> \(lines2[2])")
            } else {
                messageLines.append("< \(lines1[i])")
                messageLines.append("> [END OF FILE]")
            }
        }
        break
    }
    XCTFail(messageLines.joined(separator: "\n"), file: file, line: line)
}

func XCTAssertUnsortedEqual<T>(
    _ expression1: @autoclosure () throws -> [T],
    _ expression2: @autoclosure () throws -> [T],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) where T: Comparable {
    XCTAssertEqual(try expression1().sorted(), try expression2().sorted(), message(), file: file, line: line)
}

/// Both names must have the same number of components, throws otherwise.
func newTypeName(swiftFQName: String, jsonFQName: String) throws -> TypeName {
    var jsonComponents = jsonFQName.split(separator: "/").map(String.init)
    let swiftComponents = swiftFQName.split(separator: ".").map(String.init)
    guard !jsonComponents.isEmpty else { throw TypeCreationError(swift: swiftFQName, json: jsonFQName) }
    let hadJSONRoot = jsonComponents[0] == "#"
    if hadJSONRoot { jsonComponents.removeFirst() }
    struct TypeCreationError: Error, CustomStringConvertible, LocalizedError {
        var swift: String
        var json: String
        var description: String { "swift: \(swift), json: \(json)" }
        var errorDescription: String? { description }
    }
    guard swiftComponents.count == jsonComponents.count else {
        throw TypeCreationError(swift: swiftFQName, json: jsonFQName)
    }
    let jsonRoot: [TypeName.Component]
    if hadJSONRoot { jsonRoot = [.init(swift: nil, json: "#")] } else { jsonRoot = [] }
    return .init(components: jsonRoot + zip(swiftComponents, jsonComponents).map(TypeName.Component.init))
}

/// A diagnostic collector that accumulates all received diagnostics into
/// an array.
final class AccumulatingDiagnosticCollector: DiagnosticCollector {

    private(set) var diagnostics: [Diagnostic] = []

    func emit(_ diagnostic: Diagnostic) { diagnostics.append(diagnostic) }
}
