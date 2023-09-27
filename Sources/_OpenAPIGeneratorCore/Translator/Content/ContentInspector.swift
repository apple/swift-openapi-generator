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
    func bestSingleTypedContent(
        _ map: OpenAPI.Content.Map,
        excludeBinary: Bool = false,
        inParent parent: TypeName
    ) throws -> TypedSchemaContent? {
        guard
            let content = bestSingleContent(
                map,
                excludeBinary: excludeBinary,
                foundIn: parent.description
            )
        else {
            return nil
        }
        guard
            try validateSchemaIsSupported(
                content.schema,
                foundIn: parent.description
            )
        else {
            return nil
        }
        let identifier = contentSwiftName(content.contentType)
        let associatedType = try typeAssigner.typeUsage(
            usingNamingHint: identifier,
            withSchema: content.schema,
            components: components,
            inParent: parent
        )
        return .init(content: content, typeUsage: associatedType)
    }

    /// Extract the supported content types.
    /// - Parameters:
    ///   - map: The content map from the OpenAPI document.
    ///   - excludeBinary: A Boolean value controlling whether binary content
    ///   type should be skipped, for example used when encoding headers.
    ///   - parent: The parent type of the chosen typed schema.
    /// - Returns: The supported content type + schema + type names.
    func supportedTypedContents(
        _ map: OpenAPI.Content.Map,
        excludeBinary: Bool = false,
        inParent parent: TypeName
    ) throws -> [TypedSchemaContent] {
        let contents = supportedContents(
            map,
            excludeBinary: excludeBinary,
            foundIn: parent.description
        )
        return try contents.compactMap { content in
            guard
                try validateSchemaIsSupported(
                    content.schema,
                    foundIn: parent.description
                )
            else {
                return nil
            }
            let identifier = contentSwiftName(content.contentType)
            let associatedType = try typeAssigner.typeUsage(
                usingNamingHint: identifier,
                withSchema: content.schema,
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
    ///   - foundIn: The location where this content is parsed.
    /// - Returns: the detected content type + schema, nil if no supported
    /// schema found or if empty.
    func supportedContents(
        _ contents: OpenAPI.Content.Map,
        excludeBinary: Bool = false,
        foundIn: String
    ) -> [SchemaContent] {
        guard !contents.isEmpty else {
            return []
        }
        return
            contents
            .compactMap { key, value in
                parseContentIfSupported(
                    contentKey: key,
                    contentValue: value,
                    excludeBinary: excludeBinary,
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
    func bestSingleContent(
        _ map: OpenAPI.Content.Map,
        excludeBinary: Bool = false,
        foundIn: String
    ) -> SchemaContent? {
        guard !map.isEmpty else {
            return nil
        }
        if map.count > 1 {
            diagnostics.emitUnsupported(
                "Multiple content types",
                foundIn: foundIn
            )
        }
        let chosenContent: (SchemaContent, OpenAPI.Content)?
        if let (contentKey, contentValue) = map.first(where: { $0.key.isJSON }) {
            let contentType = contentKey.asGeneratorContentType
            chosenContent = (
                .init(
                    contentType: contentType,
                    schema: contentValue.schema
                ),
                contentValue
            )
        } else if !excludeBinary, let (contentKey, contentValue) = map.first(where: { $0.key.isBinary }) {
            let contentType = contentKey.asGeneratorContentType
            chosenContent = (
                .init(
                    contentType: contentType,
                    schema: .b(.string(format: .binary))
                ),
                contentValue
            )
        } else {
            diagnostics.emitUnsupported(
                "Unsupported content",
                foundIn: foundIn
            )
            chosenContent = nil
        }
        if let chosenContent {
            let contentType = chosenContent.0.contentType
            if contentType.lowercasedType == "multipart"
                || contentType.lowercasedTypeAndSubtype.contains("application/x-www-form-urlencoded")
            {
                diagnostics.emitUnsupportedIfNotNil(
                    chosenContent.1.encoding,
                    "Custom encoding for multipart/formEncoded content",
                    foundIn: "\(foundIn), content \(contentType.originallyCasedTypeAndSubtype)"
                )
            }
        }
        return chosenContent?.0
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
    ///   - foundIn: The location where this content is parsed.
    /// - Returns: The detected content type + schema, nil if unsupported.
    func parseContentIfSupported(
        contentKey: OpenAPI.ContentType,
        contentValue: OpenAPI.Content,
        excludeBinary: Bool = false,
        foundIn: String
    ) -> SchemaContent? {
        if contentKey.isJSON {
            let contentType = contentKey.asGeneratorContentType
            if contentType.lowercasedType == "multipart"
                || contentType.lowercasedTypeAndSubtype.contains("application/x-www-form-urlencoded")
            {
                diagnostics.emitUnsupportedIfNotNil(
                    contentValue.encoding,
                    "Custom encoding for multipart/formEncoded content",
                    foundIn: "\(foundIn), content \(contentType.originallyCasedTypeAndSubtype)"
                )
            }
            return .init(
                contentType: contentType,
                schema: contentValue.schema
            )
        }
        if contentKey.isUrlEncodedForm {
            let contentType = ContentType(contentKey.typeAndSubtype)
            return .init(
                contentType: contentType,
                schema: contentValue.schema
            )
        }
        if !excludeBinary, contentKey.isBinary {
            let contentType = contentKey.asGeneratorContentType
            return .init(
                contentType: contentType,
                schema: .b(.string(format: .binary))
            )
        }
        diagnostics.emitUnsupported(
            "Unsupported content",
            foundIn: foundIn
        )
        return nil
    }
}
