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

enum MultipartPartContentTypeKind {
    case unsupported
    case explicit(ContentType)
    case infer(UnderlyingKind)
    
    enum UnderlyingKind {
        case primitive
        case arrayOfPrimitive
        case complex
        case arrayOfComplex
        case binary
        case arrayOfBinary
    }
}

/// Utilities for asking questions about multipart content.
extension FileTranslator {
    
    func contentTypeForMultipartPart(schema: JSONSchema, encoding: OpenAPI.Content.Encoding?) throws -> MultipartPartContentTypeKind {
        if let encoding, let contentType = encoding.contentType {
            return try .explicit(contentType.asGeneratorContentType)
        }
        func inferStringContent(_ context: JSONSchema.StringContext) throws -> MultipartPartContentTypeKind {
            if let contentMediaType = context.contentMediaType {
                return try .explicit(contentMediaType.asGeneratorContentType)
            }
            switch context.contentEncoding {
            case .binary:
                return .infer(.binary)
            default:
                return .infer(.primitive)
            }
        }
        // https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#special-considerations-for-multipart-content
        // > If the property is a primitive, or an array of primitive values, the default Content-Type is text/plain
        // > If the property is complex, or an array of complex values, the default Content-Type is application/json
        // > If the property is a type: string with a contentEncoding, the default Content-Type is application/octet-stream
        switch try schema.dereferenced(in: components) {
        case .null, .not:
            return .unsupported
        case .boolean, .number, .integer:
            return .infer(.primitive)
        case .string(_, let context):
            return try inferStringContent(context)
        case .object, .all, .one, .any, .fragment:
            return .infer(.complex)
        case .array(_, let context):
            guard let items = context.items else {
                return .infer(.arrayOfComplex)
            }
            switch items {
            case .null, .not:
                return .unsupported
            case .boolean, .number, .integer:
                return .infer(.arrayOfPrimitive)
            case .string(_, let context):
                switch try inferStringContent(context) {
                case .unsupported, .infer(.arrayOfPrimitive), .infer(.arrayOfComplex), .infer(.arrayOfBinary):
                    return .unsupported
                case .explicit(let value):
                    return .explicit(value)
                case .infer(.primitive):
                    return .infer(.arrayOfPrimitive)
                case .infer(.complex):
                    return .infer(.arrayOfComplex)
                case .infer(.binary):
                    return .infer(.arrayOfBinary)
                }
            case .object, .all, .one, .any, .fragment, .array:
                return .infer(.arrayOfComplex)
            }
        }
    }
    
    func parseMultipartContentIfSupported(
        key: String,
        schema candidateSchema: JSONSchema,
        encoding: OpenAPI.Content.Encoding?,
        parent: TypeName
    ) throws -> MultipartSchemaTypedContent? {
        let contentKind = try contentTypeForMultipartPart(schema: candidateSchema, encoding: encoding)
        guard let (contentType, schema) = computeMultipartContentTypeAndSchema(
            contentKind,
            schema: candidateSchema,
            foundIn: parent.description
        ) else {
            return nil
        }
        
        let swiftSafeName = swiftSafeName(for: key)
        let typeName = parent.appending(
            swiftComponent: swiftSafeName + Constants.Global.inlineTypeSuffix,
            jsonComponent: key
        )
        return .init(
            originalName: key,
            caseKind: .documentedTyped(typeName),
            contentType: contentType,
            schema: schema,
            headers: encoding?.headers
        )
    }
    
    func computeMultipartContentTypeAndSchema(_ kind: MultipartPartContentTypeKind, schema: JSONSchema, foundIn: String) -> (ContentType, JSONSchema)? {
        switch kind {
        case .unsupported:
            diagnostics.emitUnsupported("Content type of a multipart part.", foundIn: foundIn)
            return nil
        case .explicit(let contentType):
            guard !contentType.isMultipart else {
                diagnostics.emitUnsupported("Multipart part cannot nest another multipart content.", foundIn: foundIn)
                return nil
            }
            if contentType.isBinary {
                return (contentType, .string(contentEncoding: .binary))
            } else {
                return (contentType, schema.requiredSchemaObject())
            }
        case .infer(let underlyingKind):
            switch underlyingKind {
            case .primitive, .arrayOfPrimitive:
                return (.textPlain, .string(contentEncoding: .binary))
            case .complex, .arrayOfComplex:
                return (.applicationJSON, schema.requiredSchemaObject())
            case .binary, .arrayOfBinary:
                return (.applicationOctetStream, .string(contentEncoding: .binary))
            }
        }
    }
}
