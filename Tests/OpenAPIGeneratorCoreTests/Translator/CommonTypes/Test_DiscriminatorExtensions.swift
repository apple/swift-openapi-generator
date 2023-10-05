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
@testable import _OpenAPIGeneratorCore

final class Test_DiscriminatorExtensions: Test_Core {

    struct Output: Equatable, CustomStringConvertible {
        var rawNames: [String]
        var typeName: String

        var description: String {
            "rawNames: \(rawNames.joined(separator: ", ")), typeName: \(typeName)"
        }
    }

    func testMappedTypes() throws {
        let typeAssigner = makeTranslator().typeAssigner
        func _test(
            mapping: OrderedDictionary<String, String>?,
            schemaNames: [String],
            expectedOutputs: [Output],
            file: StaticString = #file,
            line: UInt = #line
        ) throws {
            let discriminator = OpenAPI.Discriminator(
                propertyName: "which",
                mapping: mapping
            )
            let types = try discriminator.allTypes(
                schemas: schemaNames.map { JSONReference<JSONSchema>.component(named: $0) },
                typeAssigner: typeAssigner
            )
            let actualOutputs = types.map { type in
                Output(rawNames: type.rawNames, typeName: type.typeName.shortSwiftName)
            }
            XCTAssertEqual(actualOutputs, expectedOutputs, file: file, line: line)
        }

        do {
            // no mapping
            try _test(
                mapping: nil,
                schemaNames: ["A", "B"],
                expectedOutputs: [
                    .init(rawNames: ["A", "#/components/schemas/A"], typeName: "A"),
                    .init(rawNames: ["B", "#/components/schemas/B"], typeName: "B"),
                ]
            )
        }

        do {
            // with mapping, all overlap
            try _test(
                mapping: [
                    "a": "#/components/schemas/A",
                    "b": "#/components/schemas/B",
                ],
                schemaNames: ["A", "B"],
                expectedOutputs: [
                    .init(rawNames: ["a"], typeName: "A"),
                    .init(rawNames: ["b"], typeName: "B"),
                ]
            )
        }

        do {
            // with mapping, some overlap, duplicate for A
            try _test(
                mapping: [
                    "a": "#/components/schemas/A",
                    "a2": "#/components/schemas/A",
                ],
                schemaNames: ["A", "B"],
                expectedOutputs: [
                    .init(rawNames: ["a"], typeName: "A"),
                    .init(rawNames: ["a2"], typeName: "A"),
                    .init(rawNames: ["B", "#/components/schemas/B"], typeName: "B"),
                ]
            )
        }
    }
}
