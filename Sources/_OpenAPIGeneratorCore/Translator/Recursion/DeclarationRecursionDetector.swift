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
        
        var decl: Declaration
                
        private init(name: NameType, isBoxable: Bool, edges: [NameType], decl: Declaration) {
            self.name = name
            self.isBoxable = isBoxable
            self.edges = edges
            self.decl = decl
        }
        
        init?(_ decl: Declaration) {
            guard let name = decl.name else {
                return nil
            }
            self.init(
                name: name,
                isBoxable: decl.isBoxable,
                edges: decl.schemaComponentNamesOfUnbreakableReferences,
                decl: decl
            )
        }
    }
    
    struct Container: TypeNodeContainer {
        typealias Node = DeclarationRecursionDetector.Node
        
        enum ContainerError: Swift.Error {
            case nodeNotFound(Node.NameType)
        }
        
        var lookupMap: [String: Node]
        
        func lookup(_ name: String) throws -> DeclarationRecursionDetector.Node {
            guard let node = lookupMap[name] else {
                throw ContainerError.nodeNotFound(name)
            }
            return node
        }
    }
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

extension Declaration {
    
    var name: String? {
        switch self {
        case .struct(let desc):
            return desc.name
        case .enum(let desc):
            return desc.name
        case .typealias(let desc):
            return desc.name
        case .commentable(_, let decl), .deprecated(_, let decl):
            return decl.name
        case .variable, .extension, .protocol, .function, .enumCase:
            return nil
        }
    }
    
    var isBoxable: Bool {
        switch self {
        case .struct, .enum:
            return true
        case .commentable(_, let decl), .deprecated(_, let decl):
            return decl.isBoxable
        case .typealias, .variable, .extension, .protocol, .function, .enumCase:
            return false
        }
    }
    
    // TODO: Explain (does not follow through arrays/dicts since those break refs)
    var schemaComponentNamesOfUnbreakableReferences: [String] {
        switch self {
        case .struct(let desc):
            return desc
                .members
                .compactMap { (member) -> [String]? in
                    guard case .variable = member.strippingTopComment else {
                        return nil
                    }
                    return member
                        .schemaComponentNamesOfUnbreakableReferences
                }
                .flatMap { $0 }
        case .enum(let desc):
            return desc
                .members
                .compactMap { (member) -> [String]? in
                    guard case .enumCase = member.strippingTopComment else {
                        return nil
                    }
                    return member
                        .schemaComponentNamesOfUnbreakableReferences
                }
                .flatMap { $0 }
        case .commentable(_, let decl), .deprecated(_, let decl):
            return decl
                .schemaComponentNamesOfUnbreakableReferences
        case .typealias(let desc):
            return desc
                .existingType
                .referencedSchemaComponentName
                .map { [$0] } ?? []
        case .variable(let desc):
            return desc.type?.referencedSchemaComponentName.map { [$0] } ?? []
        case .enumCase(let desc):
            switch desc.kind {
            case .nameWithAssociatedValues(let values):
                return values.compactMap { $0.type.referencedSchemaComponentName }
            default:
                return []
            }
        case .extension, .protocol, .function:
            return []
        }
    }
}

fileprivate extension Array where Element == String {
    var nameIfTopLevelSchemaComponent: String? {
        let components = self
        guard
            components.count == 3,
            components.starts(with: Constants.Components.Schemas.components)
        else {
            return nil
        }
        return components[2]
    }
}

extension ExistingTypeDescription {
    
    var referencedSchemaComponentName: String? {
        switch self {
        case .member(let components):
            return components.nameIfTopLevelSchemaComponent
        case .array(let desc), .dictionaryValue(let desc), .any(let desc), .optional(let desc):
            return desc.referencedSchemaComponentName
        }
    }
}
