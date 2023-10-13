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

class Test_RecursionDetector_OpenAPI: Test_Core {

    //    func testConversion() throws {
    //        let schemas: OpenAPI.ComponentDictionary<JSONSchema> = [
    //            "A": .all(of: [.reference(.internal(.component(name: "B")))]),
    //            "B": .string,
    //        ]
    //        let components: OpenAPI.Components = .init(schemas: schemas)
    //
    //        let (rootNodes, container) = RecursionDetector.convertedTypes(
    //            schemas: schemas,
    //            components: components
    //        )
    //
    //        let lookedUp = try container.lookup("B")
    //        XCTAssertEqual(lookedUp.name, "B")
    //
    //        let expectedNodes: [RecursionDetector.OpenAPIWrapperNode] = [
    //            .init(name: "A", edges: ["B"]),
    //            .init(name: "B", edges: []),
    //        ]
    //        XCTAssertEqual(rootNodes, expectedNodes)
    //        XCTAssertEqual(container.components, components)
    //    }
    //
    //    func testEdges() throws {
    //        func _test(
    //            _ schema: JSONSchema,
    //            subschemaNames: [String],
    //            file: StaticString = #file,
    //            line: UInt = #line
    //        ) {
    //            let names = schema
    //                .referencedSubschemas
    //                .map(\.name!)
    //            XCTAssertEqual(names, subschemaNames, file: file, line: line)
    //        }
    //
    //        do {
    //            for schema in [
    //                .null(),
    //                .boolean,
    //                .number,
    //                .integer,
    //                .string,
    //                .fragment,
    //                .not(.string),
    //            ] as [JSONSchema] {
    //                _test(
    //                    schema,
    //                    subschemaNames: []
    //                )
    //            }
    //        }
    //
    //        do {
    //            let item = JSONSchema.object(
    //                properties: [
    //                    "a": .reference(.component(named: "A"))
    //                ],
    //                additionalProperties: .b(.reference(.component(named: "B")))
    //            )
    //            _test(
    //                item,
    //                subschemaNames: [
    //                    "A",
    //                    "B",
    //                ]
    //            )
    //        }
    //
    //        do {
    //            let item = JSONSchema.array(
    //                items: .reference(
    //                    .component(named: "A")
    //                )
    //            )
    //            _test(
    //                item,
    //                subschemaNames: [
    //                    "A"
    //                ]
    //            )
    //        }
    //        do {
    //            let item = JSONSchema.array(
    //                items: nil
    //            )
    //            _test(
    //                item,
    //                subschemaNames: []
    //            )
    //        }
    //
    //        do {
    //            let subschemas = [
    //                JSONSchema.reference(
    //                    .component(named: "A")
    //                )
    //            ]
    //            for schema in [
    //                .all(of: subschemas),
    //                .any(of: subschemas),
    //                .one(of: subschemas),
    //            ] as [JSONSchema] {
    //                _test(
    //                    schema,
    //                    subschemaNames: [
    //                        "A"
    //                    ]
    //                )
    //            }
    //        }
    //
    //        do {
    //            let item = JSONSchema.all(
    //                of: [
    //                    .object(
    //                        properties: [
    //                            "a": .reference(.component(named: "A"))
    //                        ]
    //                    )
    //                ]
    //            )
    //            _test(
    //                item,
    //                subschemaNames: [
    //                    "A"
    //                ]
    //            )
    //        }
    //
    //        do {
    //            let item = JSONSchema.not(
    //                .reference(
    //                    .component(named: "A")
    //                )
    //            )
    //            _test(
    //                item,
    //                subschemaNames: [
    //                    "A"
    //                ]
    //            )
    //        }
    //    }
}
