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
import OpenAPIKit
import XCTest
@testable import _OpenAPIGeneratorCore

final class Test_SchemaDependencyGraph: XCTestCase {

    func testDependenciesAndStronglyConnectedComponentsProduceNaturalLayers() {
        let schemas: OpenAPI.ComponentDictionary<JSONSchema> = [
            "A": .string, "B": .object(properties: ["a": .reference(.component(named: "A"))]),
            "C": .object(properties: ["b": .reference(.component(named: "B")), "d": .reference(.component(named: "D"))]
            ), "D": .object(properties: ["c": .reference(.component(named: "C"))]),
        ]

        let graph = SchemaDependencyGraph.build(from: schemas)

        XCTAssertEqual(graph.edges["B"], ["A"])
        XCTAssertEqual(graph.edges["C"], ["B", "D"])
        XCTAssertTrue(graph.stronglyConnectedComponents.contains(["C", "D"]))
        XCTAssertEqual(graph.naturalLayerBySchema, ["A": 0, "B": 1, "C": 2, "D": 2])
        for (schema, dependencies) in graph.edges {
            for dependency in dependencies {
                XCTAssertLessThanOrEqual(graph.naturalLayerBySchema[dependency]!, graph.naturalLayerBySchema[schema]!)
            }
        }
    }

    func testDeepGraphFoldsProportionallyWithoutForwardDependencies() {
        let graph = SchemaDependencyGraph.build(from: Self.chain(length: 5))
        let mapped = graph.mappedLayers(requestedLayerCount: 3)

        XCTAssertEqual(mapped, ["S0": 0, "S1": 0, "S2": 1, "S3": 1, "S4": 2])
        for (schema, dependencies) in graph.edges {
            for dependency in dependencies { XCTAssertLessThanOrEqual(mapped[dependency]!, mapped[schema]!) }
        }
    }

    func testShallowGraphDoesNotPadEmptyLayers() {
        let graph = SchemaDependencyGraph.build(from: Self.chain(length: 2))
        XCTAssertEqual(graph.mappedLayers(requestedLayerCount: 5), ["S0": 0, "S1": 1])
        XCTAssertEqual(Set(graph.mappedLayers(requestedLayerCount: 5).values), [0, 1])
    }

    func testGraphConstructionIsDeterministic() {
        let schemas = Self.chain(length: 20)
        let first = SchemaDependencyGraph.build(from: schemas)
        let second = SchemaDependencyGraph.build(from: schemas)

        XCTAssertEqual(first.edges, second.edges)
        XCTAssertEqual(first.stronglyConnectedComponents, second.stronglyConnectedComponents)
        XCTAssertEqual(first.naturalLayerBySchema, second.naturalLayerBySchema)
    }

    private static func chain(length: Int) -> OpenAPI.ComponentDictionary<JSONSchema> {
        var schemas: OpenAPI.ComponentDictionary<JSONSchema> = [:]
        for index in 0..<length {
            schemas[OpenAPI.ComponentKey(rawValue: "S\(index)")!] =
                index == 0 ? .string : .object(properties: ["previous": .reference(.component(named: "S\(index - 1)"))])
        }
        return schemas
    }
}
