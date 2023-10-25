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

/// A set of specialized types for using the recursion detector for
/// declarations.
struct DeclarationRecursionDetector {

    /// A node for a pair of a Swift type name and a corresponding declaration.
    struct Node: TypeNode, Equatable {

        /// The type of the name is a string.
        typealias NameType = String

        /// The name of the node.
        var name: NameType

        /// Whether the type can be boxed.
        var isBoxable: Bool

        /// The names of nodes pointed to by this node.
        var edges: [NameType]

        /// The declaration represented by this node.
        var decl: Declaration

        /// Creates a new node.
        /// - Parameters:
        ///   - name: The name of the node.
        ///   - isBoxable: Whether the type can be boxed.
        ///   - edges: The names of nodes pointed to by this node.
        ///   - decl: The declaration represented by this node.
        private init(name: NameType, isBoxable: Bool, edges: [NameType], decl: Declaration) {
            self.name = name
            self.isBoxable = isBoxable
            self.edges = edges
            self.decl = decl
        }

        /// Creates a new node from the provided declaration.
        ///
        /// Returns nil when the declaration is missing a name.
        /// - Parameter decl: A declaration.
        init?(_ decl: Declaration) {
            guard let name = decl.name else { return nil }
            let edges = decl.schemaComponentNamesOfUnbreakableReferences
            self.init(name: name, isBoxable: decl.isBoxable, edges: edges, decl: decl)
        }
    }

    /// A container for declarations.
    struct Container: TypeNodeContainer {

        /// The type of the node.
        typealias Node = DeclarationRecursionDetector.Node

        /// An error thrown by the container.
        enum ContainerError: Swift.Error {

            /// The node for the provided name was not found.
            case nodeNotFound(Node.NameType)
        }

        /// The lookup map from the name to the node.
        var lookupMap: [String: Node]

        func lookup(_ name: String) throws -> DeclarationRecursionDetector.Node {
            guard let node = lookupMap[name] else { throw ContainerError.nodeNotFound(name) }
            return node
        }
    }
}

extension Declaration {

    /// A name of the declaration, if it has one.
    var name: String? {
        switch self {
        case .struct(let desc): return desc.name
        case .enum(let desc): return desc.name
        case .typealias(let desc): return desc.name
        case .commentable(_, let decl), .deprecated(_, let decl): return decl.name
        case .variable, .extension, .protocol, .function, .enumCase: return nil
        }
    }

    /// A Boolean value representing whether this declaration can be boxed.
    var isBoxable: Bool {
        switch self {
        case .struct, .enum: return true
        case .commentable(_, let decl), .deprecated(_, let decl): return decl.isBoxable
        case .typealias, .variable, .extension, .protocol, .function, .enumCase: return false
        }
    }

    /// An array of names that can be found in `#/components/schemas` in
    /// the OpenAPI document that represent references that can cause
    /// a reference cycle.
    var schemaComponentNamesOfUnbreakableReferences: [String] {
        switch self {
        case .struct(let desc):
            return desc.members
                .compactMap { (member) -> [String]? in
                    switch member.strippingTopComment {
                    case .variable,  // A reference to a reusable type.
                        .struct, .enum:  // An inline type.
                        return member.schemaComponentNamesOfUnbreakableReferences
                    default: return nil
                    }
                }
                .flatMap { $0 }
        case .enum(let desc):
            return desc.members
                .compactMap { (member) -> [String]? in
                    guard case .enumCase = member.strippingTopComment else { return nil }
                    return member.schemaComponentNamesOfUnbreakableReferences
                }
                .flatMap { $0 }
        case .commentable(_, let decl), .deprecated(_, let decl):
            return decl.schemaComponentNamesOfUnbreakableReferences
        case .typealias(let desc): return desc.existingType.referencedSchemaComponentName.map { [$0] } ?? []
        case .variable(let desc): return desc.type?.referencedSchemaComponentName.map { [$0] } ?? []
        case .enumCase(let desc):
            switch desc.kind {
            case .nameWithAssociatedValues(let values):
                return values.compactMap { $0.type.referencedSchemaComponentName }
            default: return []
            }
        case .extension, .protocol, .function: return []
        }
    }
}

fileprivate extension Array where Element == String {

    /// The name in the `Components.Schemas.` namespace.
    var nameIfTopLevelSchemaComponent: String? {
        let components = self
        guard components.count == 3, components.starts(with: Constants.Components.Schemas.components) else {
            return nil
        }
        return components[2]
    }
}

extension ExistingTypeDescription {

    /// The name in the `Components.Schemas.` namespace, if the type can appear
    /// there. Nil otherwise.
    var referencedSchemaComponentName: String? {
        switch self {
        case .member(let components): return components.nameIfTopLevelSchemaComponent
        case .array(let desc), .dictionaryValue(let desc), .any(let desc), .optional(let desc):
            return desc.referencedSchemaComponentName
        case .generic: return nil
        }
    }
}
