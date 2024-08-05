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

/// Utilities for asking questions about OpenAPI.Content
extension FileTranslator {

    /// While we only support a single content at a time, choose the best one.
    ///
    /// Priority:
    /// 1. JSON
    /// 2. text
    /// 3. binary
    ///
    /// - Parameters:
    ///   - map: The content map from the OpenAPI document.
    ///   - excludeBinary: A Boolean value controlling whether binary content
    ///   type should be skipped, for example used when encoding headers.
    ///   - parent: The parent type of the chosen typed schema.
    /// - Returns: the detected content type + schema + type name, nil if no
    /// supported schema found or if empty.
    /// - Throws: An error if there's a problem while selecting the best content, validating
    ///           the schema, or assigning the associated type.
    func bestSingleTypedContent(_ map: OpenAPI.Content.Map, excludeBinary: Bool = false, inParent parent: TypeName)
        throws -> TypedSchemaContent?
    {
        guard let content = try bestSingleContent(map, excludeBinary: excludeBinary, foundIn: parent.description) else {
            return nil
        }
        guard try validateSchemaIsSupported(content.schema, foundIn: parent.description) else { return nil }
        let associatedType = try typeAssigner.typeUsage(withContent: content, components: components, inParent: parent)
        return .init(content: content, typeUsage: associatedType)
    }

    /// Extract the supported content types.
    /// - Parameters:
    ///   - map: The content map from the OpenAPI document.
    ///   - excludeBinary: A Boolean value controlling whether binary content
    ///   type should be skipped, for example used when encoding headers.
    ///   - isRequired: Whether the contents are in a required container.
    ///   - parent: The parent type of the chosen typed schema.
    /// - Returns: The supported content type + schema + type names.
    /// - Throws: An error if there's a problem while extracting or validating the supported
    ///           content types or assigning the associated types.
    func supportedTypedContents(
        _ map: OpenAPI.Content.Map,
        excludeBinary: Bool = false,
        isRequired: Bool,
        inParent parent: TypeName
    ) throws -> [TypedSchemaContent] {
        let contents = try supportedContents(
            map,
            excludeBinary: excludeBinary,
            isRequired: isRequired,
            foundIn: parent.description
        )
        return try contents.compactMap { content in
            guard try validateContentIsSupported(content, foundIn: parent.description) else { return nil }
            let associatedType = try typeAssigner.typeUsage(
                withContent: content,
                components: components,
                inParent: parent
            )
            return .init(content: content, typeUsage: associatedType)
        }
    }

    /// Extract the supported content types.
    /// - Parameters:
    ///   - contents: The content map from the OpenAPI document.
    ///   - excludeBinary: A Boolean value controlling whether binary content
    ///   type should be skipped, for example used when encoding headers.
    ///   - isRequired: Whether the contents are in a required container.
    ///   - foundIn: The location where this content is parsed.
    /// - Returns: the detected content type + schema, nil if no supported
    /// schema found or if empty.
    /// - Throws: If parsing of any of the contents throws.
    func supportedContents(
        _ contents: OpenAPI.Content.Map,
        excludeBinary: Bool = false,
        isRequired: Bool,
        foundIn: String
    ) throws -> [SchemaContent] {
        guard !contents.isEmpty else { return [] }
        return try contents.compactMap { key, value in
            try parseContentIfSupported(
                contentKey: key,
                contentValue: value,
                excludeBinary: excludeBinary,
                isRequired: isRequired,
                foundIn: foundIn + "/\(key.rawValue)"
            )
        }
    }

    /// While we only support a single content at a time, choose the best one.
    ///
    /// Priority:
    /// 1. JSON
    /// 2. text
    /// 3. binary
    ///
    /// - Parameters:
    ///   - map: The content map from the OpenAPI document.
    ///   - excludeBinary: A Boolean value controlling whether binary content
    ///   type should be skipped, for example used when encoding headers.
    ///   - foundIn: The location where this content is parsed.
    /// - Returns: the detected content type + schema, nil if no supported
    /// schema found or if empty.
    /// - Throws: If a malformed content type string is encountered.
    func bestSingleContent(_ map: OpenAPI.Content.Map, excludeBinary: Bool = false, foundIn: String) throws
        -> SchemaContent?
    {
        guard !map.isEmpty else { return nil }
        if map.count > 1 { try diagnostics.emitUnsupported("Multiple content types", foundIn: foundIn) }
        let mapWithContentTypes = try map.map { key, content in try (type: key.asGeneratorContentType, value: content) }

        let chosenContent: (type: ContentType, schema: SchemaContent, content: OpenAPI.Content)?
        if let (contentType, contentValue) = mapWithContentTypes.first(where: { $0.type.isJSON }) {
            chosenContent = (contentType, .init(contentType: contentType, schema: contentValue.schema), contentValue)
        } else if !excludeBinary,
            let (contentType, contentValue) = mapWithContentTypes.first(where: { $0.type.isBinary })
        {
            chosenContent = (
                contentType, .init(contentType: contentType, schema: .b(.string(contentEncoding: .binary))),
                contentValue
            )
        } else {
            try diagnostics.emitUnsupported("Unsupported content", foundIn: foundIn)
            chosenContent = nil
        }
        if let chosenContent {
            let contentType = chosenContent.type
            if contentType.lowercasedType == "multipart"
                || contentType.lowercasedTypeAndSubtype.contains("application/x-www-form-urlencoded")
            {
                try diagnostics.emitUnsupportedIfNotNil(
                    chosenContent.content.encoding,
                    "Custom encoding for multipart/formEncoded content",
                    foundIn: "\(foundIn), content \(contentType.originallyCasedTypeAndSubtype)"
                )
            }
        }
        return chosenContent?.schema
    }

    /// Returns a wrapped version of the provided content if supported, returns
    /// nil otherwise.
    ///
    /// Priority of checking for known MIME types:
    /// 1. JSON
    /// 2. text
    /// 3. binary
    ///
    /// - Parameters:
    ///   - contentKey: The content key from the OpenAPI document.
    ///   - contentValue: The content value from the OpenAPI document.
    ///   - excludeBinary: A Boolean value controlling whether binary content
    ///   type should be skipped, for example used when encoding headers.
    ///   - isRequired: Whether the contents are in a required container.
    ///   - foundIn: The location where this content is parsed.
    /// - Returns: The detected content type + schema, nil if unsupported.
    /// - Throws: If a malformed content type string is encountered.
    func parseContentIfSupported(
        contentKey: OpenAPI.ContentType,
        contentValue: OpenAPI.Content,
        excludeBinary: Bool = false,
        isRequired: Bool,
        foundIn: String
    ) throws -> SchemaContent? {
        let contentType = try contentKey.asGeneratorContentType
        if contentType.lowercasedTypeAndSubtype.contains("application/x-www-form-urlencoded") {
            try diagnostics.emitUnsupportedIfNotNil(
                contentValue.encoding,
                "Custom encoding for formEncoded content",
                foundIn: "\(foundIn), content \(contentType.originallyCasedTypeAndSubtype)"
            )
        }
        if contentType.isJSON { return .init(contentType: contentType, schema: contentValue.schema) }
        if contentType.isUrlEncodedForm { return .init(contentType: contentType, schema: contentValue.schema) }
        if contentType.isMultipart {
            guard isRequired else {
                try diagnostics.emit(
                    .warning(
                        message:
                            "Multipart request bodies must always be required, but found an optional one - skipping. Mark as `required: true` to get this body generated.",
                        context: ["foundIn": foundIn]
                    )
                )
                return nil
            }
            return .init(contentType: contentType, schema: contentValue.schema, encoding: contentValue.encoding)
        }
        if !excludeBinary, contentType.isBinary {
            return .init(contentType: contentType, schema: .b(.string(contentEncoding: .binary)))
        }
        try diagnostics.emitUnsupported("Unsupported content", foundIn: foundIn)
        return nil
    }
}
