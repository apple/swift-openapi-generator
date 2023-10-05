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
public struct FilteredDocumentBuilder {

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
    public init(document: OpenAPI.Document) {
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
    public func filter() throws -> OpenAPI.Document {
        var components = OpenAPI.Components.noComponents
        for reference in requiredSchemaReferences {
            components.schemas[try reference.internalComponentKey] = try document.components.lookup(reference)
        }
        for reference in requiredPathItemReferences {
            components.pathItems[try reference.internalComponentKey] = try document.components.lookup(reference)
        }
        for reference in requiredParameterReferences {
            components.parameters[try reference.internalComponentKey] = try document.components.lookup(reference)
        }
        for reference in requiredHeaderReferences {
            components.headers[try reference.internalComponentKey] = try document.components.lookup(reference)
        }
        for reference in requiredResponseReferences {
            components.responses[try reference.internalComponentKey] = try document.components.lookup(reference)
        }
        for reference in requiredCallbacksReferences {
            components.callbacks[try reference.internalComponentKey] = try document.components.lookup(reference)
        }
        for reference in requiredExampleReferences {
            components.examples[try reference.internalComponentKey] = try document.components.lookup(reference)
        }
        for reference in requiredLinkReferences {
            components.links[try reference.internalComponentKey] = try document.components.lookup(reference)
        }
        for reference in requiredRequestReferences {
            components.requestBodies[try reference.internalComponentKey] = try document.components.lookup(reference)
        }
        var filteredDocument = document.filteringPaths(with: requiredPaths.contains(_:))
        for (path, methods) in requiredEndpoints {
            if filteredDocument.paths.contains(key: path) {
                continue
            }
            guard let maybeReference = document.paths[path] else {
                continue
            }
            switch maybeReference {
            case .a(let reference):
                components.pathItems[try reference.internalComponentKey] = try document.components.lookup(reference).filteringEndpoints { methods.contains($0.method) }
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
    public mutating func requirePath(_ path: OpenAPI.Path) throws {
        guard let pathItem = document.paths[path] else {
            throw FilteredDocumentBuilderError.pathDoesNotExist(path)
        }
        guard requiredPaths.insert(path).inserted else { return }
        try requirePathItem(pathItem)
    }

    /// Include operations that have a given tag (and all their component dependencies).
    ///
    /// Because tags are applied to operations (cf. paths), this may result in paths within filtered
    /// document with a subset of the operations defined in the original document.
    ///
    /// - Parameter tag: The tag to use to include operations (and their paths).
    public mutating func requireOperations(tagged tag: String) throws {
        guard document.allTags.contains(tag) else {
            throw FilteredDocumentBuilderError.tagDoesNotExist(tag)
        }
        try requireOperations { endpoint in endpoint.operation.tags?.contains(tag) ?? false }
    }

    /// Include operations that have a given tag (and all their component dependencies).
    ///
    /// Because tags are applied to operations (cf. paths), this may result in paths within filtered
    /// document with a subset of the operations defined in the original document.
    ///
    /// - Parameter tag: The tag by which to include operations (and their paths).
    public mutating func requireOperations(tagged tag: OpenAPI.Tag) throws {
        try requireOperations(tagged: tag.name)
    }

    /// Include paths with operations that have a given ID (and all their component dependencies).
    ///
    /// The paths are added to the filter, along with the transitive closure of all components
    /// referenced within the corresponding path items.
    ///
    /// - Parameter operationID: The operation to include (and its path).
    public mutating func requirePath(operationID: String) throws {
        guard document.allOperationIds.contains(operationID) else {
            throw FilteredDocumentBuilderError.operationDoesNotExist(operationID: operationID)
        }

        let path = document.paths.first { _, pathItem in
            document.components[pathItem]?.endpoints
                .contains {
                    $0.operation.operationId == operationID
                } ?? false
        }!
        .key

        try requirePath(path)
    }

    /// Include schema (and all its schema dependencies).
    ///
    /// The schema is added to the filter, along with the transitive closure of all other schemas
    /// it references.
    ///
    /// - Parameter name: The key in the `#/components/schemas` map in the OpenAPI document.
    public mutating func requireSchema(_ name: String) throws {
        try requireSchema(.a(OpenAPI.Reference<JSONSchema>.component(named: name)))
    }
}

enum FilteredDocumentBuilderError: Error, LocalizedError {
    case pathDoesNotExist(OpenAPI.Path)
    case tagDoesNotExist(String)
    case operationDoesNotExist(operationID: String)
    case cannotResolveInternalReference(String)

    var errorDescription: String? {
        switch self {
        case .pathDoesNotExist(let path):
            return "Required path does not exist in OpenAPI document: \(path)"
        case .tagDoesNotExist(let tag):
            return "Required tag does not exist in OpenAPI document: \(tag)"
        case .operationDoesNotExist(let operationID):
            return "Required operation does not exist in OpenAPI document: \(operationID)"
        case .cannotResolveInternalReference(let reference):
            return "Cannot resolve reference; not local reference to component: \(reference)"
        }
    }
}

private extension FilteredDocumentBuilder {
    mutating func requirePathItem(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.PathItem>, OpenAPI.PathItem>)
        throws
    {
        switch maybeReference {
        case .a(let reference):
            guard requiredPathItemReferences.insert(reference).inserted else { return }
            try addComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value):
            try addComponentsReferencedBy(value)
        }
    }

    mutating func requireSchema(_ maybeReference: Either<OpenAPI.Reference<JSONSchema>, JSONSchema>) throws {
        switch maybeReference {
        case .a(let reference):
            guard requiredSchemaReferences.insert(reference).inserted else { return }
            try addComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value):
            try addComponentsReferencedBy(value)
        }
    }

    mutating func requireParameter(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Parameter>, OpenAPI.Parameter>)
        throws
    {
        switch maybeReference {
        case .a(let reference):
            guard requiredParameterReferences.insert(reference).inserted else { return }
            try addComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value):
            try addComponentsReferencedBy(value)
        }
    }

    mutating func requireResponse(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Response>, OpenAPI.Response>)
        throws
    {
        switch maybeReference {
        case .a(let reference):
            guard requiredResponseReferences.insert(reference).inserted else { return }
            try addComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value):
            try addComponentsReferencedBy(value)
        }
    }

    mutating func requireHeader(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Header>, OpenAPI.Header>) throws {
        switch maybeReference {
        case .a(let reference):
            guard requiredHeaderReferences.insert(reference).inserted else { return }
            try addComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value):
            try addComponentsReferencedBy(value)
        }
    }

    mutating func requireLink(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Link>, OpenAPI.Link>) throws {
        switch maybeReference {
        case .a(let reference):
            guard requiredLinkReferences.insert(reference).inserted else { return }
            try addComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value):
            try addComponentsReferencedBy(value)
        }
    }

    mutating func requireCallbacks(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Callbacks>, OpenAPI.Callbacks>)
        throws
    {
        switch maybeReference {
        case .a(let reference):
            guard requiredCallbacksReferences.insert(reference).inserted else { return }
            try addComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value):
            try addComponentsReferencedBy(value)
        }
    }

    mutating func requireRequestBody(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Request>, OpenAPI.Request>)
        throws
    {
        switch maybeReference {
        case .a(let reference):
            guard requiredRequestReferences.insert(reference).inserted else { return }
            try addComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value):
            try addComponentsReferencedBy(value)
        }
    }

    mutating func requireExample(_ maybeReference: Either<OpenAPI.Reference<OpenAPI.Example>, OpenAPI.Example>) throws {
        switch maybeReference {
        case .a(let reference):
            guard requiredExampleReferences.insert(reference).inserted else { return }
            try addComponentsReferencedBy(try document.components.lookup(reference))
        case .b(let value):
            try addComponentsReferencedBy(value)
        }
    }

    mutating func requireOperations(where predicate: (OpenAPI.PathItem.Endpoint) -> Bool) throws {
        for (path, maybePathItemReference) in document.paths {
            let originalPathItem: OpenAPI.PathItem
            switch maybePathItemReference {
            case .a(let reference):
                originalPathItem = try document.components.lookup(reference)
            case .b(let pathItem):
                originalPathItem = pathItem
            }

            for endpoint in originalPathItem.endpoints {
                guard predicate(endpoint) else {
                    continue
                }
                if requiredEndpoints[path] == nil {
                    requiredEndpoints[path] = Set()
                }
                if requiredEndpoints[path]!.insert(endpoint.method).inserted {
                    try addComponentsReferencedBy(endpoint.operation)
                }
            }
        }
    }
}

private extension FilteredDocumentBuilder {

    mutating func addComponentsReferencedBy(_ pathItem: OpenAPI.PathItem) throws {
        for endpoint in pathItem.endpoints {
            try addComponentsReferencedBy(endpoint.operation)
        }
        for parameter in pathItem.parameters {
            try requireParameter(parameter)
        }
    }

    mutating func addComponentsReferencedBy(_ operation: OpenAPI.Operation) throws {
        for parameter in operation.parameters {
            try requireParameter(parameter)
        }
        for response in operation.responses.values {
            try requireResponse(response)
        }
        if let requestBody = operation.requestBody {
            try requireRequestBody(requestBody)
        }
        for callbacks in operation.callbacks.values {
            try requireCallbacks(callbacks)
        }
    }

    mutating func addComponentsReferencedBy(_ request: OpenAPI.Request) throws {
        for content in request.content.values {
            try addComponentsReferencedBy(content)
        }
    }
    mutating func addComponentsReferencedBy(_ callbacks: OpenAPI.Callbacks) throws {
        for pathItem in callbacks.values {
            try requirePathItem(pathItem)
        }
    }

    mutating func addComponentsReferencedBy(_ schema: JSONSchema) throws {
        switch schema.value {

        case .reference(let reference, _):
            guard requiredSchemaReferences.insert(OpenAPI.Reference(reference)).inserted else { return }
            try addComponentsReferencedBy(document.components.lookup(reference))

        case .object(_, let object):
            for schema in object.properties.values {
                try addComponentsReferencedBy(schema)
            }
            if case .b(let schema) = object.additionalProperties {
                try addComponentsReferencedBy(schema)
            }

        case .array(_, let array):
            if let schema = array.items {
                try addComponentsReferencedBy(schema)
            }

        case .not(let schema, _):
            try addComponentsReferencedBy(schema)

        case .all(of: let schemas, _): fallthrough
        case .one(of: let schemas, _): fallthrough
        case .any(of: let schemas, _):
            for schema in schemas {
                try addComponentsReferencedBy(schema)
            }
        case .null, .boolean, .number, .integer, .string, .fragment: return
        }
    }

    mutating func addComponentsReferencedBy(_ parameter: OpenAPI.Parameter) throws {
        try addComponentsReferencedBy(parameter.schemaOrContent)
    }

    mutating func addComponentsReferencedBy(_ header: OpenAPI.Header) throws {
        try addComponentsReferencedBy(header.schemaOrContent)
    }

    mutating func addComponentsReferencedBy(
        _ schemaOrContent: Either<OpenAPI.Parameter.SchemaContext, OpenAPI.Content.Map>
    ) throws {
        switch schemaOrContent {
        case .a(let schemaContext):
            switch schemaContext.schema {
            case .a(let reference):
                guard requiredSchemaReferences.insert(reference).inserted else { return }
                try addComponentsReferencedBy(try document.components.lookup(reference))
            case .b(let schema):
                try addComponentsReferencedBy(schema)
            }
        case .b(let contentMap):
            for value in contentMap.values {
                switch value.schema {
                case .a(let reference):
                    guard requiredSchemaReferences.insert(reference).inserted else { return }
                    try addComponentsReferencedBy(try document.components.lookup(reference))
                case .b(let schema):
                    try addComponentsReferencedBy(schema)
                case .none:
                    continue
                }
            }
        }
    }

    mutating func addComponentsReferencedBy(_ response: OpenAPI.Response) throws {
        if let headers = response.headers {
            for header in headers.values {
                try requireHeader(header)
            }
        }
        for content in response.content.values {
            try addComponentsReferencedBy(content)
        }
        for link in response.links.values {
            try requireLink(link)
        }
    }

    mutating func addComponentsReferencedBy(_ content: OpenAPI.Content) throws {
        if let schema = content.schema {
            try requireSchema(schema)
        }
        if let encoding = content.encoding {
            for encoding in encoding.values {
                if let headers = encoding.headers {
                    for header in headers.values {
                        try requireHeader(header)
                    }
                }
            }
        }
        if let examples = content.examples {
            for example in examples.values {
                try requireExample(example)
            }
        }
    }

    mutating func addComponentsReferencedBy(_ content: OpenAPI.Link) throws {}

    mutating func addComponentsReferencedBy(_ content: OpenAPI.Example) throws {}
}

fileprivate extension OpenAPI.Reference {
    var internalComponentKey: OpenAPI.ComponentKey {
        get throws {
            guard case .internal(.component(name: let name)) = jsonReference else {
                throw FilteredDocumentBuilderError.cannotResolveInternalReference(absoluteString)
            }
            return OpenAPI.ComponentKey(rawValue: name)!
        }
    }
}

fileprivate extension OpenAPI.PathItem {
    func filteringEndpoints(_ isIncluded: (Endpoint) -> Bool) -> Self {
        var filteredPathItem = self
        for endpoint in filteredPathItem.endpoints {
            if !isIncluded(endpoint) {
                filteredPathItem.set(operation: nil, for: endpoint.method)
            }
        }
        return filteredPathItem
    }
}
