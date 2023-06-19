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
import OpenAPIKit30

/// A container for an OpenAPI response header and its computed
/// Swift type usage.
struct TypedResponseHeader {

    /// The OpenAPI response header.
    var header: OpenAPI.Header

    /// The name of the header.
    var name: String

    /// The underlying schema.
    var schema: UnresolvedSchema

    /// The Swift type representing the response header.
    var typeUsage: TypeUsage

    /// The coding strategy appropriate for this parameter.
    var codingStrategy: CodingStrategy
}

extension TypedResponseHeader {

    /// The name of the header sanitized to be a valid Swift identifier.
    var variableName: String {
        name.asSwiftSafeName
    }

    /// A Boolean value that indicates whether the response header can
    /// be omitted in the HTTP response.
    var isOptional: Bool {
        !header.required
    }
}

extension TypedResponseHeader: CustomStringConvertible {
    var description: String {
        typeUsage.description + "/header:\(name)"
    }
}

extension FileTranslator {

    /// Returns the response headers declared by the specified response.
    ///
    /// Skips any unsupported response headers.
    /// - Parameters:
    ///   - response: The OpenAPI response.
    ///   - parent: The Swift type name of the parent type of the headers.
    /// - Returns: A list of response headers; can be empty if no response
    /// headers are specified in the OpenAPI document, or if all headers are
    /// unsupported.
    func typedResponseHeaders(
        from response: OpenAPI.Response,
        inParent parent: TypeName
    ) throws -> [TypedResponseHeader] {
        guard let headers = response.headers else {
            return []
        }
        return try headers.compactMap { name, header in
            try typedResponseHeader(
                from: header,
                named: name,
                inParent: parent
            )
        }
    }

    /// Returns a typed response header for the provided unresolved header.
    /// - Parameters:
    ///   - unresolvedHeader: The header specified in the OpenAPI document.
    ///   - name: The name of the header.
    ///   - parent: The Swift type name of the parent type of the headers.
    /// - Returns: Typed response header if supported, nil otherwise.
    func typedResponseHeader(
        from unresolvedHeader: UnresolvedHeader,
        named name: String,
        inParent parent: TypeName
    ) throws -> TypedResponseHeader? {

        // Collect the header
        let header: OpenAPI.Header
        switch unresolvedHeader {
        case let .a(ref):
            header = try components.lookup(ref)
        case let .b(_header):
            header = _header
        }

        let foundIn = "\(parent.description)/\(name)"

        let schema: UnresolvedSchema
        let codingStrategy: CodingStrategy

        switch header.schemaOrContent {
        case let .a(schemaContext):
            schema = schemaContext.schema
            codingStrategy = .text
        case let .b(contentMap):
            guard
                let typedContent = try bestSingleTypedContent(
                    contentMap,
                    excludeBinary: true,
                    inParent: parent
                )
            else {
                return nil
            }
            schema = typedContent.content.schema ?? .b(.fragment)
            codingStrategy =
                typedContent
                .content
                .contentType
                .codingStrategy
        }

        // Check if schema is supported
        guard
            try validateSchemaIsSupported(
                schema,
                foundIn: foundIn
            )
        else {
            return nil
        }

        let type: TypeUsage
        switch unresolvedHeader {
        case let .a(ref):
            type = try TypeAssigner.typeName(for: ref).asUsage
        case .b:
            switch schema {
            case let .a(reference):
                type = try TypeAssigner.typeName(for: reference).asUsage
            case let .b(schema):
                type = try TypeAssigner.typeUsage(
                    forParameterNamed: name,
                    withSchema: schema,
                    inParent: parent
                )
            }
        }
        let usage = type.withOptional(!header.required)
        return .init(
            header: header,
            name: name,
            schema: schema,
            typeUsage: usage,
            codingStrategy: codingStrategy
        )
    }
}

/// An unresolved OpenAPI response header.
///
/// Can be either a reference or an inline response header.
typealias UnresolvedHeader = Either<JSONReference<OpenAPI.Header>, OpenAPI.Header>
