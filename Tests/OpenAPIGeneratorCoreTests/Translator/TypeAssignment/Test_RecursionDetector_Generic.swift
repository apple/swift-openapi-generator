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
import OpenAPIKit
import Foundation
import Testing
@testable import _OpenAPIGeneratorCore

private struct TestNode: TypeNode, ExpressibleByStringLiteral {
    typealias NameType = String
    var name: String
    var isBoxable: Bool
    var edges: [String]

    init(name: String, isBoxable: Bool, edges: [String]) {
        self.name = name
        self.isBoxable = isBoxable
        self.edges = edges
    }

    init(stringLiteral value: StringLiteralType) {
        // A > B,C,D for boxable
        // A! > B,C,D for unboxable
        let comps = value.split(separator: ">", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        precondition(comps.count == 2, "Invalid syntax")
        let edges = comps[1].split(separator: ",").map(String.init)
        let nameComp = comps[0]
        let isBoxable = !nameComp.hasSuffix("!")
        let name: String
        if isBoxable { name = String(nameComp) } else { name = String(nameComp.dropLast()) }
        self.init(name: name, isBoxable: isBoxable, edges: edges)
    }
}

private struct TestContainer: TypeNodeContainer {
    typealias Node = TestNode

    struct MissingNodeError: Error { var name: String }

    var nodes: [String: TestNode]

    func lookup(_ name: String) throws -> TestNode {
        guard let node = nodes[name] else { throw MissingNodeError(name: name) }
        return node
    }
}

@Suite("Recursion Detector Generic Tests")
struct Test_RecursionDetectorGenericTests {
    
    private func _test(
        rootNodes: [String],
        putIntoContainer nodesForContainer: [TestNode],
        expected expectedRecursed: Set<String>
    ) throws {
        precondition(Set(rootNodes).count == nodesForContainer.count, "Not all nodes are mentioned in rootNodes")
        let container = TestContainer(nodes: Dictionary(uniqueKeysWithValues: nodesForContainer.map { ($0.name, $0) }))
        let recursedNodes = try RecursionDetector.computeBoxedTypes(
            rootNodes: rootNodes.map { try container.lookup($0) },
            container: container
        )
        
        #expect(recursedNodes == expectedRecursed)
    }

    @Test("Empty input produces expected empty result")
    func testEmpty() throws {
        try _test(rootNodes: [], putIntoContainer: [], expected: [])
    }

    @Test("Single node generates expected members")
    func testSingleNode() throws {
        try _test(rootNodes: ["A"], putIntoContainer: ["A >"], expected: [])
    }

    @Test("Multiple nodes without edges generate empty result")
    func testMultipleNodesNoEdges() throws {
        try _test(rootNodes: ["A", "B", "C"], putIntoContainer: ["A >", "B >", "C >"], expected: [])
    }

    @Test("No cycles detected in linear node chain")
    func testNoCycle() throws {
        try _test(rootNodes: ["A", "B", "C", "D"], putIntoContainer: ["A > B", "B > C", "C > D", "D >"], expected: [])
    }

    @Test("No cycle and double edge are avoided")
    func testNoCycleAndDoubleEdge() throws {
        try _test(
            rootNodes: ["A", "B", "C", "D"],
            putIntoContainer: ["A > B", "B > C,D", "C > D", "D >"],
            expected: []
        )
    }

    @Test("Self loop generates expected members")
    func testSelfLoop() throws {
        try _test(rootNodes: ["A"], putIntoContainer: ["A > A"], expected: ["A"])
    }

    @Test("Simple cycle generates expected result")
    func testSimpleCycle() throws {
        try _test(rootNodes: ["A", "B"], putIntoContainer: ["A > B", "B > A"], expected: ["A"])
    }

    @Test("Longer cycle starting from A resolves correctly")
    func testLongerCycleStartA() throws {
        try _test(rootNodes: ["A", "C", "B"], putIntoContainer: ["A > B", "B > C", "C > A"], expected: ["A"])
    }

    @Test("Longer cycle starting with C generates expected members")
    func testLongerCycleStartC() throws {
        try _test(rootNodes: ["C", "A", "B"], putIntoContainer: ["A > B", "B > C", "C > A"], expected: ["C"])
    }

    @Test("Longer cycle starting with A is not boxable")
    func testLongerCycleStartAButNotBoxable() throws {
        try _test(rootNodes: ["A", "C", "B"], putIntoContainer: ["A! > B", "B > C", "C > A"], expected: ["B"])
    }

    @Test("Multiple cycles generate expected root nodes")
    func testMultipleCycles() throws {
        try _test(
            rootNodes: ["A", "C", "B", "D"],
            putIntoContainer: ["A > B", "B > A", "C > D", "D > C"],
            expected: ["A", "C"]
        )
    }

    @Test("Multiple overlapping cycles are handled correctly")
    func testMultipleCyclesOverlapping() throws {
        try _test(
            rootNodes: ["C", "A", "B", "D"],
            putIntoContainer: ["A > B", "B > C", "C > A,D", "D > C"],
            expected: ["C"]
        )
    }

    @Test("Multiple cycles generate expected nodes")
    func testMultipleCycles3() throws {
        try _test(
            rootNodes: ["A", "B", "C", "D"],
            putIntoContainer: ["A > C", "B > D,A", "C > B,D", "D > B,C"],
            expected: ["A", "B", "C"]
        )
    }

    @Test("Nested relationships are correctly resolved to expected root nodes")
    func testNested() throws {
        try _test(
            rootNodes: ["A", "C", "B", "D"],
            putIntoContainer: ["A > B", "B > C", "C > B,D", "D > C"],
            expected: ["B", "C"]
        )
    }

    @Test("Disconnected container nodes produce expected output")
    func testDisconnected() throws {
        try _test(
            rootNodes: ["A", "C", "B", "D"],
            putIntoContainer: ["A > B", "B > A", "C > D", "D >"],
            expected: ["A"]
        )
    }

    @Test("Cycle with leading node generates expected members")
    func testCycleWithLeadingNode() throws {
        try _test(
            rootNodes: ["A", "B", "C", "D"],
            putIntoContainer: ["A > B", "B > C", "C > D", "D > B"],
            expected: ["B"]
        )
    }

    @Test("Different cycles for same node")
    func testDifferentCyclesForSameNode() throws {
        try _test(rootNodes: ["C", "A", "B"], putIntoContainer: ["A > B", "B > C,A", "C > A"], expected: ["C", "A"])
    }
}

