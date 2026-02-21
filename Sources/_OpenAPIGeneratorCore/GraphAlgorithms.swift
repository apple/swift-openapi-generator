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
import HeapModule

enum GraphAlgorithms {

    // MARK: - Tarjan SCC (iterative for stack safety on large schemas)

    struct SCCResult: Sendable {
        var componentIdOf: [String: Int]
        var components: [[String]]
    }

    static func tarjanSCC(graph: [String: Set<String>]) -> SCCResult {
        let sortedGraph = graph.mapValues { $0.sorted() }
        var index = 0
        var sccStack: [String] = []
        var indices: [String: Int] = [:]
        var lowlinks: [String: Int] = [:]
        var onStack: Set<String> = []
        var components: [[String]] = []

        struct CallFrame {
            let node: String
            let neighbors: [String]
            var neighborIndex: Int
        }

        func strongConnect(startNode: String) {
            var callStack: [CallFrame] = []

            indices[startNode] = index
            lowlinks[startNode] = index
            index += 1
            sccStack.append(startNode)
            onStack.insert(startNode)

            let startNeighbors = sortedGraph[startNode] ?? []
            callStack.append(CallFrame(node: startNode, neighbors: startNeighbors, neighborIndex: 0))

            while !callStack.isEmpty {
                let currentIndex = callStack.count - 1
                let frame = callStack[currentIndex]
                let v = frame.node

                if frame.neighborIndex < frame.neighbors.count {
                    let w = frame.neighbors[frame.neighborIndex]
                    callStack[currentIndex].neighborIndex += 1

                    if indices[w] == nil {
                        indices[w] = index
                        lowlinks[w] = index
                        index += 1
                        sccStack.append(w)
                        onStack.insert(w)

                        let wNeighbors = sortedGraph[w] ?? []
                        callStack.append(CallFrame(node: w, neighbors: wNeighbors, neighborIndex: 0))
                    } else if onStack.contains(w) {
                        if let lowV = lowlinks[v], let idxW = indices[w] {
                            lowlinks[v] = min(lowV, idxW)
                        }
                    }
                } else {
                    callStack.removeLast()

                    if let parentIndex = callStack.indices.last {
                        let parent = callStack[parentIndex].node
                        if let lowParent = lowlinks[parent], let lowV = lowlinks[v] {
                            lowlinks[parent] = min(lowParent, lowV)
                        }
                    }

                    if lowlinks[v] == indices[v] {
                        var component: [String] = []
                        while true {
                            let w = sccStack.removeLast()
                            onStack.remove(w)
                            component.append(w)
                            if w == v { break }
                        }
                        components.append(component.sorted())
                    }
                }
            }
        }

        for v in graph.keys.sorted() where indices[v] == nil {
            strongConnect(startNode: v)
        }

        let componentIdOf = Dictionary(
            uniqueKeysWithValues: components.enumerated().flatMap { compId, members in
                members.map { ($0, compId) }
            }
        )

        return SCCResult(componentIdOf: componentIdOf, components: components)
    }

    // MARK: - Topological Sort

    static func topologicalSort(predecessors: [[Int]]) -> [Int] {
        let n = predecessors.count
        guard n > 0 else { return [] }

        var successors = Array(repeating: [Int](), count: n)
        var inDegree = Array(repeating: 0, count: n)
        for (v, preds) in predecessors.enumerated() {
            inDegree[v] = preds.count
            for u in preds {
                successors[u].append(v)
            }
        }

        var heap = Heap<Int>()
        for i in 0..<n where inDegree[i] == 0 {
            heap.insert(i)
        }

        var result: [Int] = []
        result.reserveCapacity(n)

        while let u = heap.popMin() {
            result.append(u)
            for v in successors[u] {
                inDegree[v] -= 1
                if inDegree[v] == 0 {
                    heap.insert(v)
                }
            }
        }

        return result
    }

    // MARK: - Condensation DAG

    static func buildCondensationDAG(
        graph: [String: Set<String>],
        scc: SCCResult
    ) -> [[Int]] {
        var dagPredecessors = Array(repeating: Set<Int>(), count: scc.components.count)

        for (u, neighbors) in graph {
            guard let cu = scc.componentIdOf[u] else { continue }
            for v in neighbors {
                if let cv = scc.componentIdOf[v], cu != cv {
                    dagPredecessors[cu].insert(cv)
                }
            }
        }

        return dagPredecessors.map { Array($0).sorted() }
    }

    // MARK: - Longest-Path Layering

    static func longestPathLayering(dagPredecessors: [[Int]]) -> [Int] {
        let topo = topologicalSort(predecessors: dagPredecessors)
        var layerOf = Array(repeating: 0, count: dagPredecessors.count)

        for u in topo {
            if let maxPredLayer = dagPredecessors[u].map({ layerOf[$0] }).max() {
                layerOf[u] = maxPredLayer + 1
            } else {
                layerOf[u] = 0
            }
        }

        return layerOf
    }

    // MARK: - LPT Bin-Packing

    typealias Island = [String]

    static func lptPacking(
        islands: [Island],
        binCount: Int,
        weight: (Island) -> Int
    ) -> [[Island]] {
        guard binCount > 0 else { return [] }

        var bins = Array(repeating: (weight: 0, items: [Island]()), count: binCount)

        let weightedIslands = islands.map { ($0, weight($0)) }
        let sortedIslands = weightedIslands.sorted { lhs, rhs in
            if lhs.1 != rhs.1 {
                return lhs.1 > rhs.1
            }
            return lhs.0.lexicographicallyPrecedes(rhs.0)
        }

        for (island, islandWeight) in sortedIslands {
            let binIndex = bins.indices.min(by: { bins[$0].weight < bins[$1].weight })!
            bins[binIndex].weight += islandWeight
            bins[binIndex].items.append(island)
        }

        return bins.map(\.items)
    }
}
