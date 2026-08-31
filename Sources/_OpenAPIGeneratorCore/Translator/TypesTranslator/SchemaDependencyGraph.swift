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

/// A deterministic dependency graph of reusable schemas.
struct SchemaDependencyGraph {

    /// Schema-to-schema edges, where each value is a dependency of the key.
    var edges: [String: Set<String>]

    /// Strongly connected schema groups in deterministic discovery order.
    var stronglyConnectedComponents: [[String]]

    /// The natural dependency layer of each schema.
    var naturalLayerBySchema: [String: Int]

    /// The number of natural dependency layers.
    var naturalLayerCount: Int { (naturalLayerBySchema.values.max() ?? -1) + 1 }

    /// Builds the dependency graph from the schemas in the parsed and filtered document.
    static func build(from schemas: OpenAPI.ComponentDictionary<JSONSchema>) -> Self {
        let schemaNames = Set(schemas.map(\.key.rawValue))
        var edges: [String: Set<String>] = [:]
        for (key, schema) in schemas {
            var references = schemaReferences(in: schema)
            references.formIntersection(schemaNames)
            edges[key.rawValue] = references
        }

        let scc = stronglyConnectedComponents(in: edges)
        let componentBySchema = Dictionary(
            uniqueKeysWithValues: scc.enumerated().flatMap { component, schemas in schemas.map { ($0, component) } }
        )
        var componentDependencies = Array(repeating: Set<Int>(), count: scc.count)
        for (schema, references) in edges {
            guard let component = componentBySchema[schema] else { continue }
            for reference in references {
                guard let dependency = componentBySchema[reference], dependency != component else { continue }
                componentDependencies[component].insert(dependency)
            }
        }

        let componentLayers = dependencyLayers(for: componentDependencies)
        let naturalLayerBySchema = Dictionary(
            uniqueKeysWithValues: componentBySchema.map { schema, component in (schema, componentLayers[component]) }
        )
        return .init(edges: edges, stronglyConnectedComponents: scc, naturalLayerBySchema: naturalLayerBySchema)
    }

    /// Maps natural graph depth into at most the requested number of contiguous layers.
    func mappedLayers(requestedLayerCount: Int) -> [String: Int] {
        guard naturalLayerCount > requestedLayerCount else { return naturalLayerBySchema }
        return naturalLayerBySchema.mapValues { naturalLayer in naturalLayer * requestedLayerCount / naturalLayerCount }
    }

    /// Returns all schema references contained anywhere in a schema.
    static func schemaReferences(in schema: JSONSchema) -> Set<String> {
        var references: Set<String> = []
        collectSchemaReferences(in: schema, into: &references)
        return references
    }

    /// Returns all schema references used by a reusable parameter.
    static func schemaReferences(in parameter: OpenAPI.Parameter, components: OpenAPI.Components) -> Set<String> {
        var references: Set<String> = []
        collectSchemaOrContentReferences(parameter.schemaOrContent, components: components, into: &references)
        return references
    }

    /// Returns all schema references used by a reusable header.
    static func schemaReferences(in header: OpenAPI.Header, components: OpenAPI.Components) -> Set<String> {
        var references: Set<String> = []
        collectSchemaOrContentReferences(header.schemaOrContent, components: components, into: &references)
        return references
    }

    /// Returns all schema references used by a reusable request body.
    static func schemaReferences(in request: OpenAPI.Request, components: OpenAPI.Components) -> Set<String> {
        var references: Set<String> = []
        collectContentReferences(in: request.content, components: components, into: &references)
        return references
    }

    /// Returns all schema references used by a reusable response, including referenced headers.
    static func schemaReferences(in response: OpenAPI.Response, components: OpenAPI.Components) -> Set<String> {
        var references: Set<String> = []
        collectContentReferences(in: response.content, components: components, into: &references)
        for (_, unresolvedHeader) in response.headers ?? [:] {
            guard let header = resolve(unresolvedHeader, in: components) else { continue }
            collectSchemaOrContentReferences(header.schemaOrContent, components: components, into: &references)
        }
        return references
    }

    /// Returns all schema references used by an operation and its path-level parameters.
    static func schemaReferences(in description: OperationDescription) -> Set<String> {
        var references: Set<String> = []
        let components = description.components
        for unresolvedParameter in description.pathParameters + description.operation.parameters {
            guard let parameter = resolve(unresolvedParameter, in: components) else { continue }
            collectSchemaOrContentReferences(parameter.schemaOrContent, components: components, into: &references)
        }
        if let unresolvedRequest = description.operation.requestBody,
            let request = resolve(unresolvedRequest, in: components)
        {
            collectContentReferences(in: request.content, components: components, into: &references)
        }
        for (_, unresolvedResponse) in description.operation.responses {
            guard let response = resolve(unresolvedResponse, in: components) else { continue }
            references.formUnion(schemaReferences(in: response, components: components))
        }
        return references
    }

    private static func resolve<Component: ComponentDictionaryLocatable>(
        _ unresolved: Either<OpenAPI.Reference<Component>, Component>,
        in components: OpenAPI.Components
    ) -> Component? {
        switch unresolved {
        case .a(let reference): return try? components.lookup(reference)
        case .b(let component): return component
        }
    }

    private static func collectSchemaOrContentReferences(
        _ schemaOrContent: Either<OpenAPI.Parameter.SchemaContext, OpenAPI.Content.Map>,
        components: OpenAPI.Components,
        into references: inout Set<String>
    ) {
        switch schemaOrContent {
        case .a(let context): collectSchemaOrReference(context.schema, into: &references)
        case .b(let content): collectContentReferences(in: content, components: components, into: &references)
        }
    }

    private static func collectContentReferences(
        in content: OpenAPI.Content.Map,
        components: OpenAPI.Components,
        into references: inout Set<String>
    ) {
        for (_, unresolvedValue) in content {
            guard let value = resolve(unresolvedValue, in: components) else { continue }
            if let schema = value.schema { collectSchemaReferences(in: schema, into: &references) }
            if let itemSchema = value.itemSchema { collectSchemaReferences(in: itemSchema, into: &references) }
        }
    }

    private static func collectSchemaOrReference(
        _ schema: Either<OpenAPI.Reference<JSONSchema>, JSONSchema>,
        into references: inout Set<String>
    ) {
        switch schema {
        case .a(let reference): collectReference(reference.jsonReference, into: &references)
        case .b(let schema): collectSchemaReferences(in: schema, into: &references)
        }
    }

    private static func collectSchemaReferences(in schema: JSONSchema, into references: inout Set<String>) {
        if let discriminator = schema.discriminator {
            let mappedReferences =
                (discriminator.mapping?.values.map { $0 } ?? []) + (discriminator.defaultMapping.map { [$0] } ?? [])
            for rawReference in mappedReferences {
                guard let reference = JSONReference<JSONSchema>.InternalReference(rawValue: rawReference) else {
                    continue
                }
                collectReference(.internal(reference), into: &references)
            }
        }

        switch schema.value {
        case .reference(let reference, _): collectReference(reference, into: &references)
        case .object(_, let context):
            for (_, property) in context.properties { collectSchemaReferences(in: property, into: &references) }
            if case .b(let schema)? = context.additionalProperties {
                collectSchemaReferences(in: schema, into: &references)
            }
        case .array(_, let context):
            if let items = context.items { collectSchemaReferences(in: items, into: &references) }
        case .all(of: let schemas, _), .any(of: let schemas, _), .one(of: let schemas, _):
            for schema in schemas { collectSchemaReferences(in: schema, into: &references) }
        case .not(let schema, _): collectSchemaReferences(in: schema, into: &references)
        default: break
        }
    }

    private static func collectReference(_ reference: JSONReference<JSONSchema>, into references: inout Set<String>) {
        guard case .internal(let internalReference) = reference, case .component(name: let name) = internalReference
        else { return }
        references.insert(name)
    }

    /// Iterative Tarjan SCC to avoid recursion depth limits on large specifications.
    private static func stronglyConnectedComponents(in graph: [String: Set<String>]) -> [[String]] {
        let sortedGraph = graph.mapValues { $0.sorted() }
        var nextIndex = 0
        var nodeStack: [String] = []
        var indices: [String: Int] = [:]
        var lowLinks: [String: Int] = [:]
        var nodesOnStack: Set<String> = []
        var components: [[String]] = []

        struct Frame {
            var node: String
            var neighbors: [String]
            var nextNeighbor: Int
        }

        for start in graph.keys.sorted() where indices[start] == nil {
            indices[start] = nextIndex
            lowLinks[start] = nextIndex
            nextIndex += 1
            nodeStack.append(start)
            nodesOnStack.insert(start)
            var frames = [Frame(node: start, neighbors: sortedGraph[start] ?? [], nextNeighbor: 0)]

            while !frames.isEmpty {
                let frameIndex = frames.count - 1
                let node = frames[frameIndex].node
                if frames[frameIndex].nextNeighbor < frames[frameIndex].neighbors.count {
                    let neighbor = frames[frameIndex].neighbors[frames[frameIndex].nextNeighbor]
                    frames[frameIndex].nextNeighbor += 1
                    if indices[neighbor] == nil {
                        indices[neighbor] = nextIndex
                        lowLinks[neighbor] = nextIndex
                        nextIndex += 1
                        nodeStack.append(neighbor)
                        nodesOnStack.insert(neighbor)
                        frames.append(Frame(node: neighbor, neighbors: sortedGraph[neighbor] ?? [], nextNeighbor: 0))
                    } else if nodesOnStack.contains(neighbor) {
                        lowLinks[node] = min(lowLinks[node]!, indices[neighbor]!)
                    }
                } else {
                    frames.removeLast()
                    if let parent = frames.last?.node { lowLinks[parent] = min(lowLinks[parent]!, lowLinks[node]!) }
                    if lowLinks[node] == indices[node] {
                        var component: [String] = []
                        while let member = nodeStack.popLast() {
                            nodesOnStack.remove(member)
                            component.append(member)
                            if member == node { break }
                        }
                        components.append(component.sorted())
                    }
                }
            }
        }
        return components
    }

    private static func dependencyLayers(for dependencies: [Set<Int>]) -> [Int] {
        var layers = Array(repeating: 0, count: dependencies.count)
        var unresolved = Set(dependencies.indices)
        while !unresolved.isEmpty {
            let ready =
                unresolved.filter { component in dependencies[component].allSatisfy { !unresolved.contains($0) } }
                .sorted()
            precondition(!ready.isEmpty, "The SCC condensation graph must be acyclic.")
            for component in ready {
                layers[component] = (dependencies[component].map { layers[$0] }.max() ?? -1) + 1
                unresolved.remove(component)
            }
        }
        return layers
    }
}
