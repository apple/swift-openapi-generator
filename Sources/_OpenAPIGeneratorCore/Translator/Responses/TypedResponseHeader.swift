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

    /// A set of configuration values that inform translation.
    var context: TranslatorContext
}

extension TypedResponseHeader {

    /// The name of the header sanitized to be a valid Swift identifier.
    var variableName: String { context.safeNameGenerator.swiftMemberName(for: name) }

    /// A Boolean value that indicates whether the response header can
    /// be omitted in the HTTP response.
    var isOptional: Bool { !header.required }
}

extension TypedResponseHeader: CustomStringConvertible {
    var description: String { typeUsage.description + "/header:\(name)" }
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
    /// - Throws: An error if there's an issue processing or generating typed response
    ///           headers, such as unsupported header types or invalid definitions.
    func typedResponseHeaders(from response: OpenAPI.Response, inParent parent: TypeName) throws
        -> [TypedResponseHeader]
    { try typedResponseHeaders(from: response.headers, inParent: parent) }

    /// Returns the response headers declared by the specified response.
    ///
    /// Skips any unsupported response headers.
    /// - Parameters:
    ///   - headers: The OpenAPI headers.
    ///   - parent: The Swift type name of the parent type of the headers.
    /// - Returns: A list of response headers; can be empty if no response
    /// headers are specified in the OpenAPI document, or if all headers are
    /// unsupported.
    /// - Throws: An error if there's an issue processing or generating typed response
    ///           headers, such as unsupported header types or invalid definitions.
    func typedResponseHeaders(from headers: OpenAPI.Header.Map?, inParent parent: TypeName) throws
        -> [TypedResponseHeader]
    {
        guard let headers else { return [] }
        return try headers.compactMap { name, header in
            try typedResponseHeader(from: header, named: name, inParent: parent)
        }
    }

    /// Returns a typed response header for the provided unresolved header.
    /// - Parameters:
    ///   - unresolvedResponseHeader: The header specified in the OpenAPI document.
    ///   - name: The name of the header.
    ///   - parent: The Swift type name of the parent type of the headers.
    /// - Returns: Typed response header if supported, nil otherwise.
    /// - Throws: An error if there's an issue processing or generating the typed response
    ///           header, such as unsupported header types, invalid definitions, or schema
    ///           validation failures.
    func typedResponseHeader(
        from unresolvedResponseHeader: UnresolvedResponseHeader,
        named name: String,
        inParent parent: TypeName
    ) throws -> TypedResponseHeader? {

        // Collect the header
        let header: OpenAPI.Header
        switch unresolvedResponseHeader {
        case let .a(ref): header = try components.lookup(ref)
        case let .b(_header): header = _header
        }

        let foundIn = "\(parent.description)/\(name)"

        let schema: UnresolvedSchema
        let codingStrategy: CodingStrategy

        switch header.schemaOrContent {
        case let .a(schemaContext):
            schema = schemaContext.schema
            codingStrategy = .uri
        case let .b(contentMap):
            guard let typedContent = try bestSingleTypedContent(contentMap, excludeBinary: true, inParent: parent)
            else { return nil }
            schema = typedContent.content.schema ?? .b(.fragment)
            codingStrategy = typedContent.content.contentType.codingStrategy
        }

        // Check if schema is supported
        guard try validateSchemaIsSupported(schema, foundIn: foundIn) else { return nil }

        let type: TypeUsage
        switch unresolvedResponseHeader {
        case let .a(ref): type = try typeAssigner.typeName(for: ref).asUsage
        case .b:
            switch schema {
            case let .a(reference): type = try typeAssigner.typeName(for: reference).asUsage
            case let .b(schema):
                type = try typeAssigner.typeUsage(
                    forParameterNamed: name,
                    withSchema: schema,
                    components: components,
                    inParent: parent
                )
            }
        }
        let isOptional = try !header.required || typeMatcher.isOptional(schema, components: components)
        let usage = type.withOptional(isOptional)
        return .init(
            header: header,
            name: name,
            schema: schema,
            typeUsage: usage,
            codingStrategy: codingStrategy,
            context: context
        )
    }
}

/// An unresolved OpenAPI response header.
///
/// Can be either a reference or an inline response header.
typealias UnresolvedResponseHeader = Either<OpenAPI.Reference<OpenAPI.Header>, OpenAPI.Header>
