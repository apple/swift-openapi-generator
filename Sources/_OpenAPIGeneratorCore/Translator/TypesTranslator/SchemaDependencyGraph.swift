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

struct SchemaDependencyGraph {
    /// Adjacency list used externally only in tests for verifying graph structure.
    var edges: [String: Set<String>]
    var scc: GraphAlgorithms.SCCResult
    var layerOf: [Int]

    var layerCount: Int {
        (layerOf.max() ?? -1) + 1
    }

    func layer(of schema: String) -> Int? {
        guard let compId = scc.componentIdOf[schema] else { return nil }
        return layerOf[compId]
    }

    static func build(from schemas: OpenAPI.ComponentDictionary<JSONSchema>) -> SchemaDependencyGraph {
        let schemaNames = Set(schemas.map(\.key.rawValue))
        var edges: [String: Set<String>] = [:]

        for (key, schema) in schemas {
            let schemaName = key.rawValue
            var dependencies = Set<String>()
            collectSchemaRefs(schema, into: &dependencies)
            dependencies.remove(schemaName)
            // Only keep dependencies that exist in the filtered schema set
            dependencies.formIntersection(schemaNames)
            edges[schemaName] = dependencies
        }

        let scc = GraphAlgorithms.tarjanSCC(graph: edges)
        let dagPredecessors = GraphAlgorithms.buildCondensationDAG(graph: edges, scc: scc)
        let layerOf = GraphAlgorithms.longestPathLayering(dagPredecessors: dagPredecessors)

        return SchemaDependencyGraph(edges: edges, scc: scc, layerOf: layerOf)
    }

    private static func resolve<T: ComponentDictionaryLocatable>(
        _ either: Either<OpenAPI.Reference<T>, T>,
        in components: OpenAPI.Components
    ) -> T? {
        switch either {
        case .a(let ref): try? components.lookup(ref)
        case .b(let value): value
        }
    }

    static func operationSchemaRefs(
        _ operation: OpenAPI.Operation,
        in components: OpenAPI.Components
    ) -> Set<String> {
        var refs = Set<String>()

        if let requestBody = operation.requestBody,
           let resolved = resolve(requestBody, in: components) {
            for (_, content) in resolved.content {
                collectContentSchemaRefs(content, into: &refs)
            }
        }

        for (_, responseRef) in operation.responses {
            if let resolved = resolve(responseRef, in: components) {
                for (_, content) in resolved.content {
                    collectContentSchemaRefs(content, into: &refs)
                }
                if let headers = resolved.headers {
                    for (_, headerRef) in headers {
                        if let header = resolve(headerRef, in: components) {
                            collectHeaderSchemaRefs(header, into: &refs)
                        }
                    }
                }
            }
        }

        for paramRef in operation.parameters {
            if let param = resolve(paramRef, in: components) {
                switch param.schemaOrContent {
                case .a(let schemaContext):
                    collectSchemaOrRefRefs(schemaContext.schema, into: &refs)
                case .b(let contentMap):
                    for (_, content) in contentMap {
                        collectContentSchemaRefs(content, into: &refs)
                    }
                }
            }
        }

        return refs
    }

    private static func collectSchemaOrRefRefs(
        _ schemaOrRef: Either<OpenAPI.Reference<JSONSchema>, JSONSchema>,
        into acc: inout Set<String>
    ) {
        switch schemaOrRef {
        case .a(let ref):
            if case .internal(let internalRef) = ref.jsonReference,
               case .component(name: let name) = internalRef {
                acc.insert(name)
            }
        case .b(let jsonSchema):
            collectSchemaRefs(jsonSchema, into: &acc)
        }
    }

    private static func collectContentSchemaRefs(_ content: OpenAPI.Content, into acc: inout Set<String>) {
        guard let schema = content.schema else { return }
        collectSchemaOrRefRefs(schema, into: &acc)
    }

    private static func collectHeaderSchemaRefs(_ header: OpenAPI.Header, into acc: inout Set<String>) {
        switch header.schemaOrContent {
        case .a(let schemaContext):
            collectSchemaOrRefRefs(schemaContext.schema, into: &acc)
        case .b(let contentMap):
            for (_, content) in contentMap {
                collectContentSchemaRefs(content, into: &acc)
            }
        }
    }

    private static func collectSchemaRefs(_ schema: JSONSchema, into acc: inout Set<String>) {
        switch schema.value {
        case .reference(let ref, _):
            if case .internal(let internalRef) = ref, case .component(name: let name) = internalRef {
                acc.insert(name)
            }

        case .object(_, let ctx):
            for (_, prop) in ctx.properties {
                collectSchemaRefs(prop, into: &acc)
            }
            if let additionalProps = ctx.additionalProperties {
                switch additionalProps {
                case .a: break
                case .b(let schema): collectSchemaRefs(schema, into: &acc)
                }
            }

        case .array(_, let ctx):
            if let items = ctx.items {
                collectSchemaRefs(items, into: &acc)
            }

        case .all(of: let schemas, _), .one(of: let schemas, _), .any(of: let schemas, _):
            for schema in schemas {
                collectSchemaRefs(schema, into: &acc)
            }

        case .not(let schema, _):
            collectSchemaRefs(schema, into: &acc)

        default:
            break
        }
    }
}
