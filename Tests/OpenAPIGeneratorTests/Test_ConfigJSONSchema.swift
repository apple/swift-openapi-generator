//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import XCTest
import _OpenAPIGeneratorCore

// https://github.com/swiftlang/swift-package-manager/issues/6367
#if !os(Windows)
@testable import swift_openapi_generator

/// Checks that the published JSON Schema stays in sync with the config file the generator accepts.
final class Test_ConfigJSONSchema: XCTestCase {

    func testSchemaMatchesUserConfig() throws {
        let repoRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        let schemaURL = repoRoot.appendingPathComponent("Public/openapi-generator-config.schema.json")
        let schema = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: schemaURL)) as? [String: Any])
        let properties = try XCTUnwrap(schema["properties"] as? [String: [String: Any]])
        XCTAssertEqual(Set(properties.keys), _UserConfig.codingKeysRawValues)
        XCTAssertEqual(schema["required"] as? [String], ["generate"])
        XCTAssertEqual(schema["additionalProperties"] as? Bool, false)

        func enumValues(_ schema: Any?) -> Set<String>? {
            ((schema as? [String: Any])?["enum"] as? [String]).map(Set.init)
        }
        XCTAssertEqual(enumValues(properties["generate"]?["items"]), Set(GeneratorMode.allCases.map(\.rawValue)))
        XCTAssertEqual(enumValues(properties["featureFlags"]?["items"]), Set(FeatureFlag.allCases.map(\.rawValue)))
        XCTAssertEqual(enumValues(properties["accessModifier"]), Set(AccessModifier.allCases.map(\.rawValue)))
        XCTAssertEqual(enumValues(properties["namingStrategy"]), Set(NamingStrategy.allCases.map(\.rawValue)))

        func nestedKeys(_ key: String) -> Set<String>? {
            (properties[key]?["properties"] as? [String: Any]).map { Set($0.keys) }
        }
        // Property names match the coding keys because these types use synthesized Codable conformance.
        XCTAssertEqual(nestedKeys("filter"), propertyNames(of: DocumentFilter()))
        XCTAssertEqual(nestedKeys("typeOverrides"), propertyNames(of: _UserConfig.TypeOverrides(schemas: nil)))

        // A config with a value for every property in the schema must decode.
        let sample = try XCTUnwrap(sampleValue(for: schema) as? [String: Any])
        XCTAssertEqual(Set(sample.keys), _UserConfig.codingKeysRawValues)
        let data = try JSONSerialization.data(withJSONObject: sample)
        XCTAssertNoThrow(try JSONDecoder().decode(_UserConfig.self, from: data))
    }

    private func propertyNames(of value: Any) -> Set<String> {
        Set(Mirror(reflecting: value).children.compactMap(\.label))
    }

    /// Returns a value that is valid for the given schema.
    private func sampleValue(for schema: [String: Any]) -> Any? {
        if let values = schema["enum"] as? [String] { return values.first }
        switch schema["type"] as? String {
        case "string": return "value"
        case "array": return [(schema["items"] as? [String: Any]).flatMap(sampleValue(for:)) ?? NSNull()]
        case "object":
            if let properties = schema["properties"] as? [String: [String: Any]] {
                return properties.compactMapValues(sampleValue(for:))
            }
            return ["key": (schema["additionalProperties"] as? [String: Any]).flatMap(sampleValue(for:)) ?? NSNull()]
        default: return nil
        }
    }
}
#endif
