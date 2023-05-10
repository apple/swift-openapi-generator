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
        let identifier = content.contentType.identifier
        let associatedType = try TypeAssigner.typeUsage(
            usingNamingHint: identifier,
            withSchema: content.schema,
            inParent: parent
        )
        return .init(content: content, typeUsage: associatedType)
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
        if let (contentKey, contentValue) = map.first(where: { $0.key.isJSON }),
            let contentType = ContentType(contentKey.typeAndSubtype)
        {
            diagnostics.emitUnsupportedIfNotNil(
                contentValue.encoding,
                "Custom encoding for JSON content",
                foundIn: "\(foundIn), content \(contentKey.rawValue)"
            )
            return .init(
                contentType: contentType,
                schema: contentValue.schema
            )
        } else if let (contentKey, _) = map.first(where: { $0.key.isText }),
            let contentType = ContentType(contentKey.typeAndSubtype)
        {
            return .init(
                contentType: contentType,
                schema: .b(.string)
            )
        } else if !excludeBinary,
            let (contentKey, _) = map.first(where: { $0.key.isBinary }),
            let contentType = ContentType(contentKey.typeAndSubtype)
        {
            return .init(
                contentType: contentType,
                schema: .b(.string(format: .binary))
            )
        } else {
            diagnostics.emitUnsupported(
                "Unsupported content",
                foundIn: foundIn
            )
            return nil
        }
    }
}
