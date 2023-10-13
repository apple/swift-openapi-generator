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
    
    enum RecursionError: Swift.Error, LocalizedError, CustomStringConvertible {
        
        case invalidRecursion(String)
        
        var description: String {
            switch self {
            case .invalidRecursion(let string):
                return "Invalid recursion found at type '\(string)'. This type cannot be constructed, cycles must contain at least one struct, not just typealiases."
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
    static func computeBoxedTypes<Node: TypeNode, Container: TypeNodeContainer>(
        rootNodes: [Node],
        container: Container
    ) throws -> Set<Node.NameType> where Container.Node == Node {

        // The current algorithm works as follows:
        // - Iterate over the types, in the order provided in the OpenAPI
        //   document.
        // - Walk all references and keep track of names already visited.
        // - If visiting a schema that is already in the stack, we found a cycle.
        // - In the cycle, first identify the set of types involved in it, and
        //   check if any of the types is already recorded as a recursive type.
        //   If so, no action needed and terminate this branch and continue with
        //   the next one.
        // - If no type in the cycle is already included in the set of recursive
        //   types, find the first boxable type starting from the current one
        //   ("causing" the recursion) following the cycle, and add it to this
        //   set, and then terminate this branch and continue.
        // - At the end, return the set of recursive types.

        var seen: Set<Node.NameType> = []
        var boxed: Set<Node.NameType> = []
        var stack: [Node] = []
        var stackSet: Set<Node.NameType> = []

        func visit(_ node: Node) throws {
            let name = node.name

            // Check if we've seen this node yet.
            if !seen.contains(name) {

                // Add to the stack.
                stack.append(node)
                stackSet.insert(name)
                defer {
                    stackSet.remove(name)
                    stack.removeLast()
                }

                // Not seen this node yet, so add it to seen, and then
                // visit its edges.
                seen.insert(name)
                for edge in node.edges {
                    try visit(container.lookup(edge))
                }
                return
            }

            // We have seen this node.

            // If the name is not in the stack, this is not a cycle.
            if !stackSet.contains(name) {
                return
            }

            // It is in the stack, so we just closed a cycle.

            // Identify the names involved in the cycle.
            // Right now, the stack must have the current node there twice.
            // Ignore everything before the first occurrence.
            
            let cycleNodes = stack.drop(while: { $0.name != name })
            let cycleNames = Set(cycleNodes.map(\.name))

            // Check if any of the names are already boxed.
            if cycleNames.contains(where: { boxed.contains($0) }) {
                // Found one, so we know this cycle will already be broken.
                // No need to add any other type, just return from this
                // visit.
                return
            }
            
            // We now choose which node will be marked as recursive.
            // Only consider boxable nodes, trying from the start of the cycle.
            guard let firstBoxable = cycleNodes.first(where: \.isBoxable) else {
                throw RecursionError.invalidRecursion(name.description)
            }

            // None of the types are boxed yet, so add the current node.
            boxed.insert(firstBoxable.name)
        }

        for node in rootNodes {
            try visit(node)
        }

        return boxed
    }

    /// Converts the OpenAPI types into wrappers that the recursion detector
    /// can work with.
    /// - Parameters:
    ///   - schemas: The root schemas in the OpenAPI document.
    ///   - components: The components from the OpenAPI document.
    /// - Returns: The converted root nodes and container.
//    static func convertedTypes(
//        schemas: OpenAPI.ComponentDictionary<JSONSchema>,
//        components: OpenAPI.Components
//    ) -> ([OpenAPIWrapperNode], OpenAPIWrapperContainer) {
//        let rootNodes = schemas.map(OpenAPIWrapperNode.init(key:value:))
//        let container = OpenAPIWrapperContainer(components: components)
//        return (rootNodes, container)
//    }

    /// A node for a pair of a Swift type name and a corresponding declaration.
//    struct SwiftWrapperNode: TypeNode, Equatable {
//
//        /// The type of the name is a string.
//        typealias NameType = TypeName
//
//        /// The name of the node.
//        var name: NameType
//
//        /// The names of nodes pointed to by this node.
//        var edges: [NameType]
//
//        /// Creates a new node from the provided node and edges.
//        /// - Parameters:
//        ///   - name: A name for the node.
//        ///   - edges: The edges for the node.
//        init(name: NameType, edges: [NameType]) {
//            self.name = name
//            self.edges = edges
//        }
//
//        /// Creates a new node from the provided type name and declaration.
//        ///
//        /// Asks the schema for referenced subschemas to discover edges.
//        /// - Parameters:
//        ///   - key: A key of the schema.
//        ///   - value: The schema.
////        init(typeName: TypeName, value: Declaration) {
////            self.init(
////                name: key,
////                edges: value.referencedSubschemas.compactMap(\.name)
////            )
////        }
//    }

//    /// A container for OpenAPI components.
//    struct SwiftWrapperContainer: TypeNodeContainer {
//
//        /// The type of the node is a Swift wrapper node.
//        typealias Node = SwiftWrapperNode
//
//        /// The OpenAPI components.
//        var components: OpenAPI.Components
//
//        /// Looks up a node for the provided name.
//        /// - Parameter name: A unique name of a node.
//        /// - Returns: The node found in the container.
//        /// - Throws: If no node was found for the name.
//        func lookup(_ name: String) throws -> Node {
//            let schema =
//                try components
//                .lookup(
//                    JSONReference<JSONSchema>
//                        .internal(
//                            .component(
//                                name: name
//                            )
//                        )
//                )
//            return .init(key: name, value: schema)
//        }
//    }
}
