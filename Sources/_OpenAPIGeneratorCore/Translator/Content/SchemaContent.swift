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

/// A type representing OpenAPI content that contains both a content type
/// and the optional JSON schema.
struct SchemaContent {

    /// The content type used to inform serialization.
    var contentType: ContentType

    /// The JSON schema describing the structured payload.
    ///
    /// Can be nil for unstructured JSON payloads, or for unstructured
    /// content types such as binary data.
    var schema: UnresolvedSchema?

    /// The optional encoding mapping for each of the properties in the object schema.
    ///
    /// Only used in multipart object schemas, ignored otherwise, as per the OpenAPI specification.
    var encoding: OrderedDictionary<String, OpenAPI.Content.Encoding>?
}

/// A type grouping schema content and its computed Swift type usage.
struct TypedSchemaContent {

    /// The schema content.
    var content: SchemaContent

    /// The computed type usage.
    var typeUsage: TypeUsage?

    /// The type usage representing the content.
    ///
    /// The content might not have a schema, in which case we treat
    /// the schema as a JSON fragment (any payload).
    var resolvedTypeUsage: TypeUsage { typeUsage ?? TypeName.valueContainer.asUsage }
}

/// An unresolved OpenAPI schema.
///
/// Can be either a reference or an inline schema.
typealias UnresolvedSchema = Either<OpenAPI.Reference<JSONSchema>, JSONSchema>
