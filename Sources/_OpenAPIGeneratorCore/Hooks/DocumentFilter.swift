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

@preconcurrency import OpenAPIKit

/// Rules used to filter an OpenAPI document.
///
/// - Todo: Add endpoint support
public struct DocumentFilter: Codable, Sendable {

    /// Operations tagged with these tags will be included in the filter.
    public var tags: [String]?

    /// These paths will be included in the filter.
    public var paths: [OpenAPI.Path]?

    /// These (additional) schemas will be included in the filter.
    ///
    /// These schemas are included in  addition to the transitive closure of schema dependencies of
    /// the paths included in the filter.
    public var schemas: [String]?

    /// Create a new DocumentFilter.
    ///
    /// - Parameters:
    ///   - operations: Paths that contain operations with IDs will be included in the filter.
    ///   - tags: Operations tagged with these tags will be included in the filter.
    ///   - paths: These paths will be included in the filter.
    ///   - schemas: These (additional) schemas will be included in the filter.
    public init(
        tags: [String] = [],
        paths: [OpenAPI.Path] = [],
        schemas: [String] = []
    ) {
        self.tags = tags
        self.paths = paths
        self.schemas = schemas
    }

    /// Filter an OpenAPI document.
    ///
    /// - Parameter document: The OpenAPI document to filter.
    /// - Returns: The filtered document.
    public func filter(_ document: OpenAPI.Document) throws -> OpenAPI.Document {
        var builder = FilteredDocumentBuilder(document: document)
        for tag in tags ?? [] {
            try builder.requireOperations(tagged: tag)
        }
        for path in paths ?? [] {
            try builder.requirePath(path)
        }
        for schema in schemas ?? [] {
            try builder.requireSchema(schema)
        }
        return try builder.filter()
    }
}