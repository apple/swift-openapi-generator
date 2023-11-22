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

struct MultipartPartInfo: Hashable {
    
    enum SerializationStrategy: Hashable {
        case primitive
        case complex
        case binary
        
        var contentType: ContentType {
            // https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#special-considerations-for-multipart-content
            // > If the property is a primitive, or an array of primitive values, the default Content-Type is text/plain
            // > If the property is complex, or an array of complex values, the default Content-Type is application/json
            // > If the property is a type: string with a contentEncoding, the default Content-Type is application/octet-stream
            switch self {
            case .primitive:
                return .textPlain
            case .complex:
                return .applicationJSON
            case .binary:
                return .applicationOctetStream
            }
        }
    }
    
    enum RepetitionKind: Hashable {
        case single
        case array
    }
    
    enum ContentTypeSource: Hashable {
        case explicit(ContentType)
        case infer(SerializationStrategy)
        
        var contentType: ContentType {
            switch self {
            case .explicit(let contentType):
                return contentType
            case .infer(let serializationStrategy):
                return serializationStrategy.contentType
            }
        }
    }
    
    var repetition: RepetitionKind
    var contentTypeSource: ContentTypeSource
    
    var contentType: ContentType {
        contentTypeSource.contentType
    }
}

struct MultipartRequirements {
    var allowsUnknownParts: Bool
    var requiredExactlyOncePartNames: Set<String>
    var requiredAtLeastOncePartNames: Set<String>
    var atMostOncePartNames: Set<String>
    var zeroOrMoreTimesPartNames: Set<String>
}

/// Utilities for asking questions about multipart content.
extension FileTranslator {
    
    func parseMultipartContent(_ content: TypedSchemaContent) throws -> MultipartContent? {
        let schemaContent = content.content
        precondition(schemaContent.contentType.isMultipart, "Unexpected content type passed to translateMultipartBody")
        let topLevelSchema = schemaContent.schema ?? .b(.fragment)
        let typeUsage = content.typeUsage! /* TODO: remove bang */
        let typeName = typeUsage.typeName
        var referenceStack: ReferenceStack = .empty
        guard let topLevelObject = try flattenedTopLevelMultipartObject(topLevelSchema, referenceStack: &referenceStack) else {
            return nil
        }
        let encoding = schemaContent.encoding
        var parts = try topLevelObject.properties.compactMap { (key, value) in
            let swiftSafeName = swiftSafeName(for: key)
            let typeName = typeName.appending(
                swiftComponent: swiftSafeName + Constants.Global.inlineTypeSuffix,
                jsonComponent: key
            )
            return try parseMultipartContentIfSupported(
                key: key,
                typeName: typeName,
                schema: value,
                encoding: encoding?[key]
            )
        }
        let additionalPropertiesStrategy = parseMultipartAdditionalPropertiesStrategy(topLevelObject.additionalProperties)
        switch additionalPropertiesStrategy {
        case .disallowed:
            break
        case .allowed:
            parts.append(.undocumented)
        case .typed(_):
            fatalError("not yet supported")
        case .any:
            parts.append(.otherRaw)
        }
        let requirements = try parseMultipartRequirements(parts: parts, additionalPropertiesStrategy: additionalPropertiesStrategy)
        return .init(
            typeName: typeName,
            parts: parts,
            additionalPropertiesStrategy: additionalPropertiesStrategy,
            requirements: requirements
        )
    }
    
    func parseMultipartRequirements(
        parts: [MultipartSchemaTypedContent],
        additionalPropertiesStrategy: MultipartAdditionalPropertiesStrategy
    ) throws -> MultipartRequirements {
        var requiredExactlyOncePartNames: Set<String> = []
        var requiredAtLeastOncePartNames: Set<String> = []
        var atMostOncePartNames: Set<String> = []
        var zeroOrMoreTimesPartNames: Set<String> = []
        for part in parts {
            switch part {
            case .documentedTyped(let part):
                let name = part.originalName
                let isRequired = try !typeMatcher.isOptional(part.schema, components: components)
                switch (part.partInfo.repetition, isRequired) {
                case (.single, true):
                    requiredExactlyOncePartNames.insert(name)
                case (.single, false):
                    atMostOncePartNames.insert(name)
                case (.array, true):
                    requiredAtLeastOncePartNames.insert(name)
                case (.array, false):
                    zeroOrMoreTimesPartNames.insert(name)
                }
            case .otherDynamicallyNamed, .otherRaw, .undocumented:
                break
            }
        }
        return .init(
            allowsUnknownParts: additionalPropertiesStrategy != .disallowed,
            requiredExactlyOncePartNames: requiredExactlyOncePartNames,
            requiredAtLeastOncePartNames: requiredAtLeastOncePartNames,
            atMostOncePartNames: atMostOncePartNames,
            zeroOrMoreTimesPartNames: zeroOrMoreTimesPartNames
        )
    }
    
    /// The returned schema is the schema of the part element, so the top arrays are stripped here.
    func parseMultipartPartInfo(
        schema: JSONSchema,
        encoding: OpenAPI.Content.Encoding?,
        foundIn: String
    ) throws -> (MultipartPartInfo, JSONSchema)? {
        func inferStringContent(_ context: JSONSchema.StringContext) throws -> MultipartPartInfo.ContentTypeSource {
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
        let repetitionKind: MultipartPartInfo.RepetitionKind
        let candidateSource: MultipartPartInfo.ContentTypeSource
        switch try schema.dereferenced(in: components) {
        case .null, .not:
            return nil
        case .boolean, .number, .integer:
            repetitionKind = .single
            candidateSource = .infer(.primitive)
        case .string(_, let context):
            repetitionKind = .single
            candidateSource = try inferStringContent(context)
        case .object, .all, .one, .any, .fragment:
            repetitionKind = .single
            candidateSource = .infer(.complex)
        case .array(_, let context):
            repetitionKind = .array
            if let items = context.items {
                switch items {
                case .null, .not:
                    return nil
                case .boolean, .number, .integer:
                    candidateSource = .infer(.primitive)
                case .string(_, let context):
                    candidateSource = try inferStringContent(context)
                case .object, .all, .one, .any, .fragment, .array:
                    candidateSource = .infer(.complex)
                }
            } else {
                candidateSource = .infer(.complex)
            }
        }
        let finalContentTypeSource: MultipartPartInfo.ContentTypeSource
        if let encoding, let contentType = encoding.contentType {
            finalContentTypeSource = try .explicit(contentType.asGeneratorContentType)
        } else {
            finalContentTypeSource = candidateSource
        }
        let contentType = finalContentTypeSource.contentType
        if finalContentTypeSource.contentType.isMultipart {
            diagnostics.emitUnsupported("Multipart part cannot nest another multipart content.", foundIn: foundIn)
            return nil
        }
        let info = MultipartPartInfo(
            repetition: repetitionKind,
            contentTypeSource: finalContentTypeSource
        )
        if contentType.isBinary {
            let isArrayAndOptional = try repetitionKind == .array && typeMatcher.isOptional(schema, components: components)
            let baseSchema: JSONSchema = .string(contentEncoding: .binary)
            let resolvedSchema: JSONSchema
            if isArrayAndOptional {
                resolvedSchema = baseSchema.optionalSchemaObject()
            } else {
                resolvedSchema = baseSchema
            }
            return (info, resolvedSchema)
        }
        return (info, schema)
    }
    
    func parseMultipartContentIfSupported(
        key: String,
        typeName: TypeName,
        schema candidateSchema: JSONSchema,
        encoding: OpenAPI.Content.Encoding?
    ) throws -> MultipartSchemaTypedContent? {
        guard let (info, resolvedSchema) = try parseMultipartPartInfo(
            schema: candidateSchema,
            encoding: encoding,
            foundIn: typeName.description
        ) else {
            return nil
        }
        // TODO: Support additionalProperties + schema.
        return .documentedTyped(
            .init(
                originalName: key,
                typeName: typeName,
                partInfo: info,
                schema: resolvedSchema,
                headers: encoding?.headers
            )
        )
    }
}
