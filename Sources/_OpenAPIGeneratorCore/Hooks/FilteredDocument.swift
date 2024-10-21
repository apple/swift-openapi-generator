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
@preconcurrency import OpenAPIKit

/// Filter the paths and components of an OpenAPI document.
///
/// The builder starts with an empty filter, which will return the underlying document, but empty
/// paths and components maps.
///
/// Desired paths and/or named schemas are included by calling the `requireXXX` methods.
///
/// When adding a path to the filter, the transitive closure of all referenced components are also
/// included in the filtered document.
struct FilteredDocumentBuilder {

    /// The underlying OpenAPI document to filter.
    private(set) var document: OpenAPI.Document

    private(set) var requiredPaths: Set<OpenAPI.Path>
    private(set) var requiredPathItemReferences: Set<OpenAPI.Reference<OpenAPI.PathItem>>
    private(set) var requiredSchemaReferences: Set<OpenAPI.Reference<JSONSchema>>
    private(set) var requiredParameterReferences: Set<OpenAPI.Reference<OpenAPI.Parameter>>
    private(set) var requiredHeaderReferences: Set<OpenAPI.Reference<OpenAPI.Header>>
    private(set) var requiredResponseReferences: Set<OpenAPI.Reference<OpenAPI.Response>>
    private(set) var requiredCallbacksReferences: Set<OpenAPI.Reference<OpenAPI.Callbacks>>
    private(set) var requiredExampleReferences: Set<OpenAPI.Reference<OpenAPI.Example>>
    private(set) var requiredLinkReferences: Set<OpenAPI.Reference<OpenAPI.Link>>
    private(set) var requiredRequestReferences: Set<OpenAPI.Reference<OpenAPI.Request>>
    private(set) var requiredEndpoints: [OpenAPI.Path: Set<OpenAPI.HttpMethod>]

    /// Create a new FilteredDocumentBuilder.
    ///
    /// - Parameter document: The underlying OpenAPI document to filter.
    init(document: OpenAPI.Document) {
        self.document = document
        self.requiredPaths = []
        self.requiredPathItemReferences = []
        self.requiredSchemaReferences = []
        self.requiredParameterReferences = []
        self.requiredHeaderReferences = []
        self.requiredResponseReferences = []
        self.requiredCallbacksReferences = []
        self.requiredExampleReferences = []
        self.requiredLinkReferences = []
        self.requiredRequestReferences = []
        self.requiredEndpoints = [:]
    }

    /// Filter the underlying document based on the rules provided.
    ///
    /// - Returns: The filtered OpenAPI document.
    /// - Throws: If any dependencies of the requested document components cannot be resolved.
    func filter() throws -> OpenAPI.Document {
        let originalDocument = document
        let originalComponents = originalDocument.components
        var components = OpenAPI.Components.noComponents
        for (key, value) in originalComponents.schemas {
            let reference = OpenAPI.Reference<JSONSchema>.component(named: key.rawValue)
            guard requiredSchemaReferences.contains(reference) else { continue }
            components.schemas[key] = value
        }
        for (key, value) in originalComponents.pathItems {
            let reference = OpenAPI.Reference<OpenAPI.PathItem>.component(named: key.rawValue)
            guard requiredPathItemReferences.contains(reference) else { continue }
            components.pathItems[key] = value
        }
        for (key, value) in originalComponents.parameters {
            let reference = OpenAPI.Reference<OpenAPI.Parameter>.component(named: key.rawValue)
            guard requiredParameterReferences.contains(reference) else { continue }
            components.parameters[key] = value
        }
        for (key, value) in originalComponents.headers {
            let reference = OpenAPI.Reference<OpenAPI.Header>.component(named: key.rawValue)
            guard requiredHeaderReferences.contains(reference) else { continue }
            components.headers[key] = value
        }
        for (key, value) in originalComponents.responses {
            let reference = OpenAPI.Reference<OpenAPI.Response>.component(named: key.rawValue)
            guard requiredResponseReferences.contains(reference) else { continue }
            components.responses[key] = value
        }
        for (key, value) in originalComponents.callbacks {
            let reference = OpenAPI.Reference<OpenAPI.Callbacks>.component(named: key.rawValue)
            guard requiredCallbacksReferences.contains(reference) else { continue }
            components.callbacks[key] = value
        }
        for (key, value) in originalComponents.examples {
            let reference = OpenAPI.Reference<OpenAPI.Example>.component(named: key.rawValue)
            guard requiredExampleReferences.contains(reference) else { continue }
            components.examples[key] = value
        }
        for (key, value) in originalComponents.links {
            let reference = OpenAPI.Reference<OpenAPI.Link>.component(named: key.rawValue)
            guard requiredLinkReferences.contains(reference) else { continue }
            components.links[key] = value
        }
        for (key, value) in originalComponents.requestBodies {
            let reference = OpenAPI.Reference<OpenAPI.Request>.component(named: key.rawValue)
            guard requiredRequestReferences.contains(reference) else { continue }
            components.requestBodies[key] = value
        }
        var filteredDocument = document.filteringPaths { path in
            if requiredPaths.contains(path) { return true }
            if let methods = requiredEndpoints[path], !methods.isEmpty { return true }
            return false
        }
        let filteredPaths = filteredDocument.paths
        for (path, pathItem) in filteredPaths {
            guard let methods = requiredEndpoints[path] else { continue }
            switch pathItem {
            case .a(let reference):
                components.pathItems[try reference.internalComponentKey] = try document.components.lookup(reference)
                    .filteringEndpoints { methods.contains($0.method) }
            case .b(let pathItem):
                filteredDocument.paths[path] = .b(pathItem.filteringEndpoints { methods.contains($0.method) })
            }
        }
        filteredDocument.components = components
        return filteredDocument
    }

    /// Include a path (and all its component dependencies).
    ///
    /// The path is added to the filter, along with the transitive closure of all components
    /// referenced within the corresponding path item.
    ///
    /// - Parameter path: The path to be included in the filter.
    /// - Throws: If the path does not exist in original OpenAPI document.
    mutating func includePath(_ path: OpenAPI.Path) throws {
        guard let pathItem = document.paths[path] else { throw FilteredDocumentBuilderError.pathDoesNotExist(path) }
        guard requiredPaths.insert(path).inserted else { return }
        try includePathItem(pathItem)
    }

    /// Include operations that have a given tag (and all their component dependencies).
    ///
    /// Because tags are applied to operations (cf. paths), this may result in paths within filtered
    /// document with a subset of the operations defined in the original document.
    ///
    /// - Parameter tag: The tag to use to include operations (and their paths).
    /// - Throws: If the tag does not exist in original OpenAPI document.
    mutating func includeOperations(tagged tag: String) throws {
        guard document.allTags.contains(tag) else { throw FilteredDocumentBuilderError.tagDoesNotExist(tag) }
        try includeOperations { endpoint in endpoint.operation.tags?.contains(tag) ?? false }
    }

    /// Include operations that have a given tag (and all their component dependencies).
    ///
    /// Because tags are applied to operations (cf. paths), this may result in paths within filtered
    /// document with a subset of the operations defined in the original document.
    ///
    /// - Parameter tag: The tag by which to include operations (and their paths).
    /// - Throws: If the tag does not exist in original OpenAPI document.
    mutating func includeOperations(tagged tag: OpenAPI.Tag) throws { try includeOperations(tagged: tag.name) }

    /// Include the operation with a given ID (and all its component dependencies).
    ///
    /// This may result in paths within filtered document with a subset of the operations defined
    /// in the original document.
    ///
    /// - Parameter operationID: The operation to include (and its path).
    /// - Throws: If the operation does not exist in original OpenAPI document.
    mutating func includeOperation(operationID: String) throws {
        guard document.allOperationIds.contains(operationID) else {
            throw FilteredDocumentBuilderError.operationDoesNotExist(operationID: operationID)
        }
        try includeOperations { endpoint in endpoint.operation.operationId == operationID }
    }

    /// Include schema (and all its schema dependencies).
    ///
    /// The schema is added to the filter, along with the transitive closure of all other schemas
    /// it references.
    ///
    /// - Parameter name: The key in the `#/components/schemas` map in the OpenAPI document.
    /// - Throws: If the named schema does not exist in original OpenAPI document.
    mutating func includeSchema(_ name: String) throws {
        try includeSchema(.a(OpenAPI.Reference<JSONSchema>.component(named: name)))
    }
}

enum FilteredDocumentBuilderError: Error, LocalizedError {
    case pathDoesNotExist(OpenAPI.Path)
    case tagDoesNotExist(String)
    case operationDoesNotExist(operationID: String)
    case cannotResolveInternalReference(String)

    var errorDescription: String? {
        switch self {
        case .pathDoesNotExist(let path): return "Required path does not exist in OpenAPI document: \(path)"
        case .tagDoesNotExist(let tag): return "Required tag does not exist in OpenAPI document: \(tag)"
        case .operationDoesNotExist(let operationID):
            return "Required operation does not exist in OpenAPI document: \(operationID)"
        case .cannotResolveInternalReference(let reference):
            return "Cannot resolve reference; not local reference to component: \(reference)"
        }
    }
}

private extension FilteredDocumentBuilder {
    mutating func includePathItem(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.PathItem>, OpenAPI.PathItem>)
        throws
    {
        switch maybeReference {
        case .a(let reference):
            guard requiredPathItemReferences.insert(reference).inserted else { return }
            try includeComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value): try includeComponentsReferencedBy(value)
        }
    }

    mutating func includeSchema(_ maybeReference: Either<OpenAPI.Reference<JSONSchema>, JSONSchema>) throws {
        switch maybeReference {
        case .a(let reference):
            guard requiredSchemaReferences.insert(reference).inserted else { return }
            try includeComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value): try includeComponentsReferencedBy(value)
        }
    }

    mutating func includeParameter(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Parameter>, OpenAPI.Parameter>)
        throws
    {
        switch maybeReference {
        case .a(let reference):
            guard requiredParameterReferences.insert(reference).inserted else { return }
            try includeComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value): try includeComponentsReferencedBy(value)
        }
    }

    mutating func includeResponse(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Response>, OpenAPI.Response>)
        throws
    {
        switch maybeReference {
        case .a(let reference):
            guard requiredResponseReferences.insert(reference).inserted else { return }
            try includeComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value): try includeComponentsReferencedBy(value)
        }
    }

    mutating func includeHeader(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Header>, OpenAPI.Header>) throws {
        switch maybeReference {
        case .a(let reference):
            guard requiredHeaderReferences.insert(reference).inserted else { return }
            try includeComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value): try includeComponentsReferencedBy(value)
        }
    }

    mutating func includeLink(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Link>, OpenAPI.Link>) throws {
        switch maybeReference {
        case .a(let reference):
            guard requiredLinkReferences.insert(reference).inserted else { return }
            try includeComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value): try includeComponentsReferencedBy(value)
        }
    }

    mutating func includeCallbacks(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Callbacks>, OpenAPI.Callbacks>)
        throws
    {
        switch maybeReference {
        case .a(let reference):
            guard requiredCallbacksReferences.insert(reference).inserted else { return }
            try includeComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value): try includeComponentsReferencedBy(value)
        }
    }

    mutating func includeRequestBody(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Request>, OpenAPI.Request>)
        throws
    {
        switch maybeReference {
        case .a(let reference):
            guard requiredRequestReferences.insert(reference).inserted else { return }
            try includeComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value): try includeComponentsReferencedBy(value)
        }
    }

    mutating func includeExample(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Example>, OpenAPI.Example>) throws {
        switch maybeReference {
        case .a(let reference):
            guard requiredExampleReferences.insert(reference).inserted else { return }
            try includeComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value): try includeComponentsReferencedBy(value)
        }
    }

    mutating func includeOperations(where predicate: (OpenAPI.PathItem.Endpoint) -> Bool) throws {
        for (path, maybePathItemReference) in document.paths {
            let originalPathItem: OpenAPI.PathItem
            switch maybePathItemReference {
            case .a(let reference): originalPathItem = try document.components.lookup(reference)
            case .b(let pathItem): originalPathItem = pathItem
            }

            for endpoint in originalPathItem.endpoints {
                guard predicate(endpoint) else { continue }
                if requiredEndpoints[path] == nil { requiredEndpoints[path] = Set() }
                if requiredEndpoints[path]!.insert(endpoint.method).inserted {
                    for parameter in originalPathItem.parameters { try includeParameter(parameter) }
                    try includeComponentsReferencedBy(endpoint.operation)
                }
            }
        }
    }
}

private extension FilteredDocumentBuilder {

    mutating func includeComponentsReferencedBy(_ pathItem: OpenAPI.PathItem) throws {
        for endpoint in pathItem.endpoints { try includeComponentsReferencedBy(endpoint.operation) }
        for parameter in pathItem.parameters { try includeParameter(parameter) }
    }

    mutating func includeComponentsReferencedBy(_ operation: OpenAPI.Operation) throws {
        for parameter in operation.parameters { try includeParameter(parameter) }
        for response in operation.responses.values { try includeResponse(response) }
        if let requestBody = operation.requestBody { try includeRequestBody(requestBody) }
        for callbacks in operation.callbacks.values { try includeCallbacks(callbacks) }
    }

    mutating func includeComponentsReferencedBy(_ request: OpenAPI.Request) throws {
        for content in request.content.values { try includeComponentsReferencedBy(content) }
    }
    mutating func includeComponentsReferencedBy(_ callbacks: OpenAPI.Callbacks) throws {
        for pathItem in callbacks.values { try includePathItem(pathItem) }
    }

    mutating func includeComponentsReferencedBy(_ schema: JSONSchema) throws {
        switch schema.value {

        case .reference(let reference, _):
            guard requiredSchemaReferences.insert(OpenAPI.Reference(reference)).inserted else { return }
            try includeComponentsReferencedBy(document.components.lookup(reference))

        case .object(_, let object):
            for schema in object.properties.values { try includeComponentsReferencedBy(schema) }
            if case .b(let schema) = object.additionalProperties { try includeComponentsReferencedBy(schema) }

        case .array(_, let array): if let schema = array.items { try includeComponentsReferencedBy(schema) }

        case .not(let schema, _): try includeComponentsReferencedBy(schema)

        case .all(of: let schemas, _), .one(of: let schemas, _), .any(of: let schemas, _):
            for schema in schemas { try includeComponentsReferencedBy(schema) }
        case .null, .boolean, .number, .integer, .string, .fragment: return
        }
    }

    mutating func includeComponentsReferencedBy(_ parameter: OpenAPI.Parameter) throws {
        try includeComponentsReferencedBy(parameter.schemaOrContent)
    }

    mutating func includeComponentsReferencedBy(_ header: OpenAPI.Header) throws {
        try includeComponentsReferencedBy(header.schemaOrContent)
    }

    mutating func includeComponentsReferencedBy(
        _ schemaOrContent: Either<OpenAPI.Parameter.SchemaContext, OpenAPI.Content.Map>
    ) throws {
        switch schemaOrContent {
        case .a(let schemaContext):
            switch schemaContext.schema {
            case .a(let reference):
                guard requiredSchemaReferences.insert(reference).inserted else { return }
                try includeComponentsReferencedBy(try document.components.lookup(reference))
            case .b(let schema): try includeComponentsReferencedBy(schema)
            }
        case .b(let contentMap):
            for value in contentMap.values {
                switch value.schema {
                case .a(let reference):
                    guard requiredSchemaReferences.insert(reference).inserted else { return }
                    try includeComponentsReferencedBy(try document.components.lookup(reference))
                case .b(let schema): try includeComponentsReferencedBy(schema)
                case .none: continue
                }
            }
        }
    }

    mutating func includeComponentsReferencedBy(_ response: OpenAPI.Response) throws {
        if let headers = response.headers { for header in headers.values { try includeHeader(header) } }
        for content in response.content.values { try includeComponentsReferencedBy(content) }
        for link in response.links.values { try includeLink(link) }
    }

    mutating func includeComponentsReferencedBy(_ content: OpenAPI.Content) throws {
        if let schema = content.schema { try includeSchema(schema) }
        if let encoding = content.encoding {
            for encoding in encoding.values {
                if let headers = encoding.headers { for header in headers.values { try includeHeader(header) } }
            }
        }
        if let examples = content.examples { for example in examples.values { try includeExample(example) } }
    }

    mutating func includeComponentsReferencedBy(_ content: OpenAPI.Link) throws {}

    mutating func includeComponentsReferencedBy(_ content: OpenAPI.Example) throws {}
}

fileprivate extension OpenAPI.Reference {
    var internalComponentKey: OpenAPI.ComponentKey {
        get throws {
            guard case .internal(.component(name: let name)) = jsonReference else {
                throw FilteredDocumentBuilderError.cannotResolveInternalReference(absoluteString)
            }
            return OpenAPI.ComponentKey(stringLiteral: name)
        }
    }
}

fileprivate extension OpenAPI.PathItem {
    func filteringEndpoints(_ isIncluded: (Endpoint) -> Bool) -> Self {
        var filteredPathItem = self
        for endpoint in filteredPathItem.endpoints {
            if !isIncluded(endpoint) { filteredPathItem.set(operation: nil, for: endpoint.method) }
        }
        return filteredPathItem
    }
}
