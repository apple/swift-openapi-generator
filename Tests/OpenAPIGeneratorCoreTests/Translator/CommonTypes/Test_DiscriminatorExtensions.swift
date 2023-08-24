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
import OpenAPIKit30
@testable import _OpenAPIGeneratorCore

final class Test_DiscriminatorExtensions: Test_Core {

    func testMappedTypes() throws {
        let types = _testTypes()

        do {
            let mapped = try _testMappedTypes(
                mapping: nil,
                types: types
            )
            XCTAssertEqual(types, mapped.map(\.typeName))
            XCTAssertEqual(
                [
                    "Foo",
                    "Bar",
                    "B$z",
                ],
                mapped.map(\.rawName)
            )
            XCTAssertEqual(
                [
                    "Foo",
                    "Bar",
                    "B_dollar_z",
                ],
                mapped.map(\.caseName)
            )
        }

        do {
            let mapped = try _testMappedTypes(
                mapping: [
                    "bar": "Bar",
                    "baz": "#/components/schemas/B$z",
                ],
                types: types
            )
            XCTAssertEqual(types, mapped.map(\.typeName))
            XCTAssertEqual(
                [
                    "Foo",
                    "bar",
                    "baz",
                ],
                mapped.map(\.rawName)
            )
            XCTAssertEqual(
                [
                    "Foo",
                    "Bar",
                    "B_dollar_z",
                ],
                mapped.map(\.caseName)
            )
        }
    }

    func _testMappedTypes(
        mapping: [String: String]?,
        types: [TypeName]
    ) throws -> [OneOfMappedType] {
        try OpenAPI
            .Discriminator(
                propertyName: "kind",
                mapping: mapping
            )
            .mappedTypes(types)
    }

    func _testTypes() -> [TypeName] {
        let typeShortNames: [String] = [
            "Foo",
            "Bar",
            "B$z",
        ]
        let types: [TypeName] = typeShortNames.map {
            typeAssigner.typeName(
                forComponentOriginallyNamed: $0,
                in: .schemas
            )
        }
        XCTAssertEqual(
            [
                "Components.Schemas.Foo",
                "Components.Schemas.Bar",
                "Components.Schemas.B_dollar_z",
            ],
            types.map(\.fullyQualifiedSwiftName)
        )
        XCTAssertEqual(
            [
                "#/components/schemas/Foo",
                "#/components/schemas/Bar",
                "#/components/schemas/B$z",
            ],
            types.compactMap(\.fullyQualifiedJSONPath)
        )
        return types
    }
}
