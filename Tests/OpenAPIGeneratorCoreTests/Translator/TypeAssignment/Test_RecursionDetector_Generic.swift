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

class Test_RecursionDetector_Generic: Test_Core {

    func testEmpty() throws { try _test(rootNodes: [], putIntoContainer: [], expected: []) }

    func testSingleNode() throws { try _test(rootNodes: ["A"], putIntoContainer: ["A >"], expected: []) }

    func testMultipleNodesNoEdges() throws {
        try _test(rootNodes: ["A", "B", "C"], putIntoContainer: ["A >", "B >", "C >"], expected: [])
    }

    func testNoCycle() throws {
        try _test(rootNodes: ["A", "B", "C", "D"], putIntoContainer: ["A > B", "B > C", "C > D", "D >"], expected: [])
    }

    func testNoCycleAndDoubleEdge() throws {
        try _test(
            rootNodes: ["A", "B", "C", "D"],
            putIntoContainer: ["A > B", "B > C,D", "C > D", "D >"],
            expected: []
        )
    }

    func testSelfLoop() throws { try _test(rootNodes: ["A"], putIntoContainer: ["A > A"], expected: ["A"]) }

    func testSimpleCycle() throws {
        try _test(rootNodes: ["A", "B"], putIntoContainer: ["A > B", "B > A"], expected: ["A"])
    }

    func testLongerCycleStartA() throws {
        try _test(rootNodes: ["A", "C", "B"], putIntoContainer: ["A > B", "B > C", "C > A"], expected: ["A"])
    }

    func testLongerCycleStartC() throws {
        try _test(rootNodes: ["C", "A", "B"], putIntoContainer: ["A > B", "B > C", "C > A"], expected: ["C"])
    }

    func testLongerCycleStartAButNotBoxable() throws {
        try _test(rootNodes: ["A", "C", "B"], putIntoContainer: ["A! > B", "B > C", "C > A"], expected: ["B"])
    }

    func testMultipleCycles() throws {
        try _test(
            rootNodes: ["A", "C", "B", "D"],
            putIntoContainer: ["A > B", "B > A", "C > D", "D > C"],
            expected: ["A", "C"]
        )
    }

    func testMultipleCyclesOverlapping() throws {
        try _test(
            rootNodes: ["C", "A", "B", "D"],
            putIntoContainer: ["A > B", "B > C", "C > A,D", "D > C"],
            expected: ["C"]
        )
    }

    func testMultipleCycles3() throws {
        try _test(
            rootNodes: ["A", "B", "C", "D"],
            putIntoContainer: ["A > C", "B > D,A", "C > B,D", "D > B,C"],
            expected: ["A", "B", "C"]
        )
    }

    func testNested() throws {
        try _test(
            rootNodes: ["A", "C", "B", "D"],
            putIntoContainer: ["A > B", "B > C", "C > B,D", "D > C"],
            expected: ["B", "C"]
        )
    }

    func testDisconnected() throws {
        try _test(
            rootNodes: ["A", "C", "B", "D"],
            putIntoContainer: ["A > B", "B > A", "C > D", "D >"],
            expected: ["A"]
        )
    }

    func testCycleWithLeadingNode() throws {
        try _test(
            rootNodes: ["A", "B", "C", "D"],
            putIntoContainer: ["A > B", "B > C", "C > D", "D > B"],
            expected: ["B"]
        )
    }

    func testDifferentCyclesForSameNode() throws {
        try _test(rootNodes: ["C", "A", "B"], putIntoContainer: ["A > B", "B > C,A", "C > A"], expected: ["C", "A"])
    }

    // MARK: - Private

    private func _test(
        rootNodes: [String],
        putIntoContainer nodesForContainer: [TestNode],
        expected expectedRecursed: Set<String>,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        precondition(Set(rootNodes).count == nodesForContainer.count, "Not all nodes are mentioned in rootNodes")
        let container = TestContainer(nodes: Dictionary(uniqueKeysWithValues: nodesForContainer.map { ($0.name, $0) }))
        let recursedNodes = try RecursionDetector.computeBoxedTypes(
            rootNodes: rootNodes.map { try container.lookup($0) },
            container: container
        )
        XCTAssertEqual(recursedNodes, expectedRecursed, file: file, line: line)
    }
}

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
