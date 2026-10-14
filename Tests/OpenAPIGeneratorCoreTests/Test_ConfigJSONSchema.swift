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
import Foundation
@testable import _OpenAPIGeneratorCore

/// Checks that the published JSON Schema stays in sync with the config file the generator accepts.
final class Test_ConfigJSONSchema: XCTestCase {

    func testSchemaMatchesUserConfig() throws {
        let schema = try loadSchema()
        let properties = try XCTUnwrap(schema["properties"] as? [String: [String: Any]])
        XCTAssertEqual(Set(properties.keys), _UserConfig.codingKeysRawValues)
        XCTAssertEqual(schema["required"] as? [String], ["generate"])
        XCTAssertEqual(schema["additionalProperties"] as? Bool, false)

        func allowedValues(_ schema: Any?) -> Set<String>? { constValues(of: schema).map(Set.init) }
        XCTAssertEqual(allowedValues(properties["generate"]?["items"]), Set(GeneratorMode.allCases.map(\.rawValue)))
        XCTAssertEqual(allowedValues(properties["featureFlags"]?["items"]), Set(FeatureFlag.allCases.map(\.rawValue)))
        XCTAssertEqual(allowedValues(properties["accessModifier"]), Set(AccessModifier.supportedValues.map(\.rawValue)))
        XCTAssertEqual(allowedValues(properties["namingStrategy"]), Set(NamingStrategy.allCases.map(\.rawValue)))
        XCTAssertEqual(properties["accessModifier"]?["default"] as? String, Config.defaultAccessModifier.rawValue)
        XCTAssertEqual(properties["namingStrategy"]?["default"] as? String, Config.defaultNamingStrategy.rawValue)

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

    func testSchemaExamplesAreValidConfigs() throws {
        let examples = try XCTUnwrap(loadSchema()["examples"] as? [[String: Any]])
        XCTAssertFalse(examples.isEmpty)
        for example in examples {
            // The generator rejects unknown keys, which decoding alone doesn't catch.
            XCTAssertTrue(_UserConfig.codingKeysRawValues.isSuperset(of: example.keys), "Unknown key in \(example)")
            let data = try JSONSerialization.data(withJSONObject: example)
            XCTAssertNoThrow(try JSONDecoder().decode(_UserConfig.self, from: data), "\(example)")
        }
    }

    private func loadSchema() throws -> [String: Any] {
        let repoRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        let schemaURL = repoRoot.appendingPathComponent("Public/openapi-generator-config.schema.json")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: schemaURL)) as? [String: Any])
    }

    private func propertyNames(of value: Any) -> Set<String> {
        Set(Mirror(reflecting: value).children.compactMap(\.label))
    }

    /// Returns the values of the `const` subschemas listed in the `oneOf` of the given schema.
    ///
    /// Returns nil if any subschema isn't a `const`, because that subschema could allow other values.
    private func constValues(of schema: Any?) -> [String]? {
        guard let subschemas = (schema as? [String: Any])?["oneOf"] as? [[String: Any]] else { return nil }
        let values = subschemas.compactMap { $0["const"] as? String }
        return values.count == subschemas.count ? values : nil
    }

    /// Returns a value that is valid for the given schema.
    private func sampleValue(for schema: [String: Any]) -> Any? {
        if let values = constValues(of: schema) { return values.first }
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
