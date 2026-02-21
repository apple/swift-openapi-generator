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
@testable import _OpenAPIGeneratorCore

final class Test_GraphAlgorithms: XCTestCase {

    // MARK: - Tarjan SCC

    func testTarjanSCC_noCycles() {
        // A -> B -> C (linear chain, no cycles)
        let graph: [String: Set<String>] = [
            "A": ["B"],
            "B": ["C"],
            "C": [],
        ]
        let result = GraphAlgorithms.tarjanSCC(graph: graph)

        XCTAssertEqual(result.components.count, 3)
        for component in result.components {
            XCTAssertEqual(component.count, 1)
        }
    }

    func testTarjanSCC_singleCycle() {
        // A -> B -> C -> A (all in one SCC)
        let graph: [String: Set<String>] = [
            "A": ["B"],
            "B": ["C"],
            "C": ["A"],
        ]
        let result = GraphAlgorithms.tarjanSCC(graph: graph)

        XCTAssertEqual(result.components.count, 1)
        XCTAssertEqual(result.components[0].sorted(), ["A", "B", "C"])
    }

    func testTarjanSCC_diamond_noCycles() {
        // A -> B, A -> C, B -> D, C -> D
        let graph: [String: Set<String>] = [
            "A": ["B", "C"],
            "B": ["D"],
            "C": ["D"],
            "D": [],
        ]
        let result = GraphAlgorithms.tarjanSCC(graph: graph)

        XCTAssertEqual(result.components.count, 4)
        for component in result.components {
            XCTAssertEqual(component.count, 1)
        }
    }

    func testTarjanSCC_mixed() {
        // A -> B -> C -> B (cycle in B,C), A -> D (no cycle)
        let graph: [String: Set<String>] = [
            "A": ["B", "D"],
            "B": ["C"],
            "C": ["B"],
            "D": [],
        ]
        let result = GraphAlgorithms.tarjanSCC(graph: graph)

        XCTAssertEqual(result.components.count, 3)
        let cycleComponent = result.components.first { $0.count > 1 }
        XCTAssertEqual(cycleComponent?.sorted(), ["B", "C"])
    }

    func testTarjanSCC_emptyGraph() {
        let graph: [String: Set<String>] = [:]
        let result = GraphAlgorithms.tarjanSCC(graph: graph)

        XCTAssertEqual(result.components.count, 0)
    }

    func testTarjanSCC_isolatedNodes() {
        let graph: [String: Set<String>] = [
            "A": [],
            "B": [],
            "C": [],
        ]
        let result = GraphAlgorithms.tarjanSCC(graph: graph)

        XCTAssertEqual(result.components.count, 3)
        for component in result.components {
            XCTAssertEqual(component.count, 1)
        }
    }

    // MARK: - Topological Sort

    func testTopologicalSort_linearChain() {
        // 0 <- 1 <- 2
        let predecessors: [[Int]] = [[], [0], [1]]
        let result = GraphAlgorithms.topologicalSort(predecessors: predecessors)

        XCTAssertEqual(result, [0, 1, 2])
    }

    func testTopologicalSort_diamond() {
        // 0 -> 1, 0 -> 2, 1 -> 3, 2 -> 3
        let predecessors: [[Int]] = [[], [0], [0], [1, 2]]
        let result = GraphAlgorithms.topologicalSort(predecessors: predecessors)

        XCTAssertEqual(result.first, 0)
        XCTAssertEqual(result.last, 3)
        XCTAssertTrue(result.firstIndex(of: 1)! < result.firstIndex(of: 3)!)
        XCTAssertTrue(result.firstIndex(of: 2)! < result.firstIndex(of: 3)!)
    }

    func testTopologicalSort_multipleRoots() {
        // 0 and 1 are independent roots, both -> 2
        let predecessors: [[Int]] = [[], [], [0, 1]]
        let result = GraphAlgorithms.topologicalSort(predecessors: predecessors)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.last, 2)
    }

    func testTopologicalSort_empty() {
        let result = GraphAlgorithms.topologicalSort(predecessors: [])

        XCTAssertEqual(result, [])
    }

    // MARK: - Longest-Path Layering

    func testLongestPathLayering_linearChain() {
        // 0 <- 1 <- 2
        let predecessors: [[Int]] = [[], [0], [1]]
        let layers = GraphAlgorithms.longestPathLayering(dagPredecessors: predecessors)

        XCTAssertEqual(layers, [0, 1, 2])
    }

    func testLongestPathLayering_diamond() {
        // 0 -> 1, 0 -> 2, 1 -> 3, 2 -> 3
        let predecessors: [[Int]] = [[], [0], [0], [1, 2]]
        let layers = GraphAlgorithms.longestPathLayering(dagPredecessors: predecessors)

        XCTAssertEqual(layers[0], 0)
        XCTAssertEqual(layers[1], 1)
        XCTAssertEqual(layers[2], 1)
        XCTAssertEqual(layers[3], 2)
    }

    func testLongestPathLayering_multipleRoots() {
        // 0 and 1 independent, 2 depends on both
        let predecessors: [[Int]] = [[], [], [0, 1]]
        let layers = GraphAlgorithms.longestPathLayering(dagPredecessors: predecessors)

        XCTAssertEqual(layers[0], 0)
        XCTAssertEqual(layers[1], 0)
        XCTAssertEqual(layers[2], 1)
    }

    func testLongestPathLayering_singleNode() {
        let predecessors: [[Int]] = [[]]
        let layers = GraphAlgorithms.longestPathLayering(dagPredecessors: predecessors)

        XCTAssertEqual(layers, [0])
    }

    // MARK: - LPT Bin Packing

    func testLPTPacking_balanced() {
        let islands: [GraphAlgorithms.Island] = [
            ["a", "b"],
            ["c", "d"],
            ["e", "f"],
            ["g", "h"],
        ]
        let bins = GraphAlgorithms.lptPacking(islands: islands, binCount: 2) { $0.count }

        XCTAssertEqual(bins.count, 2)
        let totalPerBin = bins.map { $0.flatMap { $0 }.count }
        XCTAssertEqual(totalPerBin[0], 4)
        XCTAssertEqual(totalPerBin[1], 4)
    }

    func testLPTPacking_skewed() {
        let islands: [GraphAlgorithms.Island] = [
            ["a", "b", "c", "d", "e"],
            ["f"],
            ["g"],
        ]
        let bins = GraphAlgorithms.lptPacking(islands: islands, binCount: 2) { $0.count }

        XCTAssertEqual(bins.count, 2)
        let totalPerBin = bins.map { $0.flatMap { $0 }.count }
        XCTAssertEqual(totalPerBin.sorted(), [2, 5])
    }

    func testLPTPacking_empty() {
        let bins = GraphAlgorithms.lptPacking(islands: [], binCount: 3) { $0.count }

        XCTAssertEqual(bins.count, 3)
        for bin in bins {
            XCTAssertTrue(bin.isEmpty)
        }
    }

    func testLPTPacking_singleItem() {
        let islands: [GraphAlgorithms.Island] = [
            ["a", "b", "c"],
        ]
        let bins = GraphAlgorithms.lptPacking(islands: islands, binCount: 3) { $0.count }

        XCTAssertEqual(bins.count, 3)
        let nonEmpty = bins.filter { !$0.isEmpty }
        XCTAssertEqual(nonEmpty.count, 1)
        XCTAssertEqual(nonEmpty[0].flatMap { $0 }.count, 3)
    }

    func testLPTPacking_zeroBins() {
        let islands: [GraphAlgorithms.Island] = [["a"]]
        let bins = GraphAlgorithms.lptPacking(islands: islands, binCount: 0) { $0.count }

        XCTAssertEqual(bins.count, 0)
    }

    func testLPTPacking_customWeight() {
        let islands: [GraphAlgorithms.Island] = [
            ["a"],
            ["b"],
            ["c"],
        ]
        let weights = ["a": 10, "b": 5, "c": 5]
        let bins = GraphAlgorithms.lptPacking(islands: islands, binCount: 2) { island in
            island.reduce(0) { $0 + (weights[$1] ?? 0) }
        }

        XCTAssertEqual(bins.count, 2)
        let binWeights = bins.map { bin in
            bin.flatMap { $0 }.reduce(0) { $0 + (weights[$1] ?? 0) }
        }
        XCTAssertEqual(binWeights.sorted(), [10, 10])
    }

    // MARK: - Condensation DAG

    func testCondensationDAG_withCycle() {
        // A -> B -> C -> B (cycle), A -> D
        let graph: [String: Set<String>] = [
            "A": ["B", "D"],
            "B": ["C"],
            "C": ["B"],
            "D": [],
        ]
        let scc = GraphAlgorithms.tarjanSCC(graph: graph)
        let dag = GraphAlgorithms.buildCondensationDAG(graph: graph, scc: scc)

        // Cycle {B,C} becomes single node, so 3 condensed nodes
        XCTAssertEqual(dag.count, 3)
        // Verify DAG has no self-loops
        for (i, preds) in dag.enumerated() {
            XCTAssertFalse(preds.contains(i))
        }
    }
}
