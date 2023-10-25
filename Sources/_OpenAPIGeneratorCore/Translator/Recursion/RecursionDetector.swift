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

import Foundation

/// A uniquely named node which can point to other nodes.
protocol TypeNode {

    /// The type of the name.
    associatedtype NameType: Hashable & CustomStringConvertible

    /// A unique name.
    var name: NameType { get }

    /// Whether it can be boxed in a reference type to break cycles.
    var isBoxable: Bool { get }

    /// The names of nodes pointed to by this node.
    var edges: [NameType] { get }
}

/// A container of nodes that allows looking up nodes by a name.
protocol TypeNodeContainer {

    /// The type of the node.
    associatedtype Node: TypeNode

    /// Looks up a node for the provided name.
    /// - Parameter name: A unique name of a node.
    /// - Returns: The node found in the container.
    /// - Throws: If no node was found for the name.
    func lookup(_ name: Node.NameType) throws -> Node
}

/// A set of utility functions for recursive type support.
struct RecursionDetector {

    /// An error thrown by the recursion detector.
    enum RecursionError: Swift.Error, LocalizedError, CustomStringConvertible {

        /// The recursion is not allowed (for example, a ref pointing to itself.)
        case invalidRecursion(String)

        var description: String {
            switch self {
            case .invalidRecursion(let string):
                return
                    "Invalid recursion found at type '\(string)'. This type cannot be constructed, cycles must contain at least one struct, not just typealiases."
            }
        }
    }

    /// Computes the types that are involved in recursion.
    ///
    /// This is used to decide which types should have a reference type for
    /// internal storage, allowing to break infinite recursion and support
    /// recursive types.
    ///
    /// Note that this function encompasses the full algorithm, to allow future
    /// optimization without breaking the API.
    /// - Parameters:
    ///   - rootNodes: The named root nodes.
    ///   - container: The container capable of resolving a name to a node.
    /// - Returns: The types that cause recusion and should have a reference
    ///   type for internal storage.
    /// - Throws: If a referenced node is not found in the container.
    static func computeBoxedTypes<Node: TypeNode, Container: TypeNodeContainer>(rootNodes: [Node], container: Container)
        throws -> Set<Node.NameType> where Container.Node == Node
    {

        // The current algorithm works as follows:
        // - Iterate over the types, in the order provided in the OpenAPI
        //   document.
        // - Walk all references and keep track of names already visited.
        // - If visiting a schema that is already in the stack, we found a cycle.
        // - Find the first boxable type starting from the current one
        //   ("causing" the recursion) following the cycle, and add it to this
        //   set, and then terminate this branch and continue.
        // - At the end, return the set of recursive types.

        var seen: Set<Node.NameType> = []
        var boxed: Set<Node.NameType> = []
        var stack: [Node] = []
        var stackSet: Set<Node.NameType> = []

        func visit(_ node: Node) throws {
            let name = node.name
            let previousStackSet = stackSet

            // Add to the stack.
            stack.append(node)
            stackSet.insert(name)
            defer {
                stackSet.remove(name)
                stack.removeLast()
            }

            // Check if we've seen this node yet.
            if !seen.contains(name) {

                // Not seen this node yet, so add it to seen, and then
                // visit its edges.
                seen.insert(name)

                for edge in node.edges { try visit(container.lookup(edge)) }
                return
            }

            // We have seen this node.

            // If the name is not in the stack twice, this is not a cycle.
            if !previousStackSet.contains(name) { return }

            // It is in the stack twice, so we just closed a cycle.

            // Identify the names involved in the cycle.
            // Right now, the stack must have the current node there twice.
            // Ignore everything before the first occurrence.
            let cycleNodes = stack.drop(while: { $0.name != name })

            // We now choose which node will be marked as recursive.
            // Only consider boxable nodes, trying from the start of the cycle.
            guard let firstBoxable = cycleNodes.first(where: \.isBoxable) else {
                throw RecursionError.invalidRecursion(name.description)
            }

            let nameToAdd = firstBoxable.name

            // Check if we're already going to box this type, if so, we're done.
            if boxed.contains(nameToAdd) { return }

            // None of the types are boxed yet, so add the current node.
            boxed.insert(nameToAdd)
        }

        for node in rootNodes { try visit(node) }
        return boxed
    }
}
