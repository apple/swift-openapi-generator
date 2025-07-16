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

/// Information about the kind of the part.
struct MultipartPartInfo: Hashable {

    /// The serialization strategy used by this part, derived from the schema and content type.
    enum SerializationStrategy: Hashable {

        /// A primitive strategy, for example used for raw strings.
        case primitive

        /// A complex strategy, for example used for JSON objects.
        case complex

        /// A binary strategy, used for raw byte payloads.
        case binary

        /// The content type most appropriate for the serialization strategy.
        var contentType: ContentType {
            // https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#special-considerations-for-multipart-content
            // > If the property is a primitive, or an array of primitive values, the default Content-Type is text/plain
            // > If the property is complex, or an array of complex values, the default Content-Type is application/json
            // > If the property is a type: string with a contentEncoding, the default Content-Type is application/octet-stream
            switch self {
            case .primitive: return .textPlain
            case .complex: return .applicationJSON
            case .binary: return .applicationOctetStream
            }
        }
    }

    /// The repetition kind of the part, whether it only appears once or multiple times.
    enum RepetitionKind: Hashable {

        /// A single kind, cannot be repeated.
        case single

        /// An array kind, allows the part name to appear more than once.
        case array
    }

    /// The source of the content type information.
    enum ContentTypeSource: Hashable {

        /// An explicit source, where the OpenAPI document contains a content type in the encoding map.
        case explicit(ContentType)

        /// An implicit source, where the content type is inferred from the serialization strategy.
        case infer(SerializationStrategy)

        /// The content type computed from the source.
        var contentType: ContentType {
            switch self {
            case .explicit(let contentType): return contentType
            case .infer(let serializationStrategy): return serializationStrategy.contentType
            }
        }
    }

    /// The repetition kind of the part.
    var repetition: RepetitionKind

    /// The source of content type information.
    var contentTypeSource: ContentTypeSource

    /// The content type used by this part.
    var contentType: ContentType { contentTypeSource.contentType }
}

/// The requirements derived from the OpenAPI document.
struct MultipartRequirements {

    /// A Boolean value indicating whether unknown part names are allowed.
    var allowsUnknownParts: Bool

    /// A set of known part names that must appear exactly once.
    var requiredExactlyOncePartNames: Set<String>

    /// A set of known part names that must appear at least once.
    var requiredAtLeastOncePartNames: Set<String>

    /// A set of known part names that can appear at most once.
    var atMostOncePartNames: Set<String>

    /// A set of known part names that can appear any number of times.
    var zeroOrMoreTimesPartNames: Set<String>
}

/// Utilities for asking questions about multipart content.
extension FileTranslator {

    /// Parses multipart content information from the provided schema.
    /// - Parameters:
    ///   - typeName: The name of the multipart type.
    ///   - schema: The top level schema of the multipart content.
    ///   - encoding: The encoding mapping refining the information from the schema.
    /// - Returns: A multipart content value, or nil if the provided schema is not valid multipart content.
    /// - Throws: An error if the schema is malformed or a reference cannot be followed.
    func parseMultipartContent(
        typeName: TypeName,
        schema: UnresolvedSchema?,
        encoding: OrderedDictionary<String, OpenAPI.Content.Encoding>?
    ) throws -> MultipartContent? {
        var referenceStack: ReferenceStack = .empty
        guard let topLevelObject = try flattenedTopLevelMultipartObject(schema, referenceStack: &referenceStack) else {
            return nil
        }
        var parts: [MultipartSchemaTypedContent] = try topLevelObject.properties.compactMap {
            (key, value) -> MultipartSchemaTypedContent? in
            let swiftSafeName = context.safeNameGenerator.swiftTypeName(for: key)
            let typeName = typeName.appending(
                swiftComponent: swiftSafeName + Constants.Global.inlineTypeSuffix,
                jsonComponent: key
            )
            let partEncoding = encoding?[key]
            guard
                let (info, resolvedSchema) = try parseMultipartPartInfo(
                    schema: value,
                    encoding: partEncoding,
                    foundIn: typeName.description
                )
            else { return nil }
            return .documentedTyped(
                .init(
                    originalName: key,
                    typeName: typeName,
                    partInfo: info,
                    schema: resolvedSchema,
                    headers: partEncoding?.headers
                )
            )
        }
        let additionalPropertiesStrategy = MultipartAdditionalPropertiesStrategy(topLevelObject.additionalProperties)
        switch additionalPropertiesStrategy {
        case .disallowed: break
        case .allowed: parts.append(.undocumented)
        case .typed(let schema):
            guard
                let (info, resolvedSchema) = try parseMultipartPartInfo(
                    schema: schema,
                    encoding: nil,
                    foundIn: typeName.description
                )
            else {
                throw GenericError(
                    message: "Failed to parse multipart info for additionalProperties in \(typeName.description)."
                )
            }
            let partTypeUsage = try typeAssigner.typeUsage(
                usingNamingHint: Constants.AdditionalProperties.variableName,
                withSchema: .b(resolvedSchema),
                components: components,
                inParent: typeName
            )!
            // The unwrap is safe, the method only returns nil when the input schema is nil.
            let partTypeName = partTypeUsage.typeName
            parts.append(.otherDynamicallyNamed(.init(typeName: partTypeName, partInfo: info, schema: resolvedSchema)))
        case .any: parts.append(.otherRaw)
        }
        let requirements = try parseMultipartRequirements(
            parts: parts,
            additionalPropertiesStrategy: additionalPropertiesStrategy
        )
        return .init(
            typeName: typeName,
            parts: parts,
            additionalPropertiesStrategy: additionalPropertiesStrategy,
            requirements: requirements
        )
    }

    /// Parses multipart content information from the provided schema.
    /// - Parameter content: The schema content from which to parse multipart information.
    /// - Returns: A multipart content value, or nil if the provided schema is not valid multipart content.
    /// - Throws: An error if the schema is malformed or a reference cannot be followed.
    func parseMultipartContent(_ content: TypedSchemaContent) throws -> MultipartContent? {
        let schemaContent = content.content
        precondition(schemaContent.contentType.isMultipart, "Unexpected content type passed to translateMultipartBody")
        // Safe - we never produce nil for multipart.
        let typeUsage = content.typeUsage!
        let typeName = typeUsage.typeName
        let schema = schemaContent.schema
        let encoding = schemaContent.encoding
        return try parseMultipartContent(typeName: typeName, schema: schema, encoding: encoding)
    }

    /// Computes the requirements for the provided parts and additional properties strategy.
    /// - Parameters:
    ///   - parts: The multipart parts.
    ///   - additionalPropertiesStrategy: The strategy used for handling additional properties.
    /// - Returns: The multipart requirements.
    /// - Throws: An error if the schema is malformed or a reference cannot be followed.
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
                let schema = part.schema
                let isRequired = try !typeMatcher.isOptional(schema, components: components)
                switch (part.partInfo.repetition, isRequired) {
                case (.single, true): requiredExactlyOncePartNames.insert(name)
                case (.single, false): atMostOncePartNames.insert(name)
                case (.array, true): requiredAtLeastOncePartNames.insert(name)
                case (.array, false): zeroOrMoreTimesPartNames.insert(name)
                }
            case .otherDynamicallyNamed, .otherRaw, .undocumented: break
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

    /// Parses information about an individual part's schema.
    ///
    /// The returned schema is the schema of the part element, so the top arrays are stripped here, and
    /// are allowed to be repeated.
    /// - Parameters:
    ///   - schema: The schema of the part.
    ///   - encoding: The encoding information for the schema.
    ///   - foundIn: The location where this part is parsed.
    /// - Returns: A tuple of the part info and resolved schema, or nil if the schema is not a valid part schema.
    /// - Throws: An error if the schema is malformed or a reference cannot be followed.
    func parseMultipartPartInfo(schema: JSONSchema, encoding: OpenAPI.Content.Encoding?, foundIn: String) throws -> (
        MultipartPartInfo, JSONSchema
    )? {
        func inferStringContent(_ context: JSONSchema.StringContext) throws -> MultipartPartInfo.ContentTypeSource {
            if let contentMediaType = context.contentMediaType {
                return try .explicit(contentMediaType.asGeneratorContentType)
            }
            switch context.contentEncoding {
            case .binary: return .infer(.binary)
            default: return .infer(.primitive)
            }
        }
        func inferAllOfAnyOfOneOf(_ schemas: [DereferencedJSONSchema]) throws -> MultipartPartInfo.ContentTypeSource? {
            // If all schemas are primitive, the allOf/anyOf/oneOf is also primitive.
            // These cannot be binary, so only primitive vs complex.
            for schema in schemas {
                guard let (_, kind) = try inferSchema(schema) else { return nil }
                guard case .infer(.primitive) = kind else { return kind }
            }
            return .infer(.primitive)
        }
        func inferSchema(_ schema: DereferencedJSONSchema) throws -> (
            MultipartPartInfo.RepetitionKind, MultipartPartInfo.ContentTypeSource
        )? {
            let repetitionKind: MultipartPartInfo.RepetitionKind
            let candidateSource: MultipartPartInfo.ContentTypeSource
            switch schema {
            case .null, .not: return nil
            case .boolean, .number, .integer:
                repetitionKind = .single
                candidateSource = .infer(.primitive)
            case .string(_, let context):
                repetitionKind = .single
                candidateSource = try inferStringContent(context)
            case .object, .fragment:
                repetitionKind = .single
                candidateSource = .infer(.complex)
            case .all(of: let schemas, _), .one(of: let schemas, _), .any(of: let schemas, _):
                repetitionKind = .single
                guard let value = try inferAllOfAnyOfOneOf(schemas) else { return nil }
                candidateSource = value
            case .array(_, let context):
                repetitionKind = .array
                if let items = context.items {
                    switch items {
                    case .null, .not: return nil
                    case .boolean, .number, .integer: candidateSource = .infer(.primitive)
                    case .string(_, let context): candidateSource = try inferStringContent(context)
                    case .object, .all, .one, .any, .fragment, .array: candidateSource = .infer(.complex)
                    }
                } else {
                    candidateSource = .infer(.complex)
                }
            }
            return (repetitionKind, candidateSource)
        }
        guard let (repetitionKind, candidateSource) = try inferSchema(schema.dereferenced(in: components)) else {
            return nil
        }
        let finalContentTypeSource: MultipartPartInfo.ContentTypeSource
        if let encoding, let contentType = encoding.contentTypes.first, encoding.contentTypes.count == 1 {
            finalContentTypeSource = try .explicit(contentType.asGeneratorContentType)
        } else {
            finalContentTypeSource = candidateSource
        }
        let contentType = finalContentTypeSource.contentType
        if finalContentTypeSource.contentType.isMultipart {
            try diagnostics.emitUnsupported("Multipart part cannot nest another multipart content.", foundIn: foundIn)
            return nil
        }
        let info = MultipartPartInfo(repetition: repetitionKind, contentTypeSource: finalContentTypeSource)
        if contentType.isBinary {
            let isOptional = try typeMatcher.isOptional(schema, components: components)
            let baseSchema: JSONSchema = .string(contentEncoding: .binary)
            let resolvedSchema: JSONSchema
            if isOptional { resolvedSchema = baseSchema.optionalSchemaObject() } else { resolvedSchema = baseSchema }
            return (info, resolvedSchema)
        } else if repetitionKind == .array {
            let isOptional = try typeMatcher.isOptional(schema, components: components)
            guard case .array(_, let context) = schema.value else {
                preconditionFailure("Array repetition should always use an array schema.")
            }
            let elementSchema: JSONSchema = context.items ?? .fragment
            let resolvedSchema: JSONSchema
            if isOptional {
                resolvedSchema = elementSchema.optionalSchemaObject()
            } else {
                resolvedSchema = elementSchema
            }
            return (info, resolvedSchema)
        }
        return (info, schema)
    }

    /// Parses the names of component schemas used by multipart request and response bodies.
    ///
    /// The result is used to inform how a schema is generated.
    /// - Parameters:
    ///   - paths: The paths section of the OpenAPI document.
    ///   - components: The components section of the OpenAPI document.
    /// - Returns: A set of component keys of the schemas used by multipart content.
    /// - Throws: An error if a reference cannot be followed.
    func parseSchemaNamesUsedInMultipart(paths: OpenAPI.PathItem.Map, components: OpenAPI.Components) throws -> Set<
        OpenAPI.ComponentKey
    > {
        var refs: Set<OpenAPI.ComponentKey> = []
        func visitContentMap(_ contentMap: OpenAPI.Content.Map) throws {
            for (key, value) in contentMap {
                guard try key.asGeneratorContentType.isMultipart else { continue }
                guard let schema = value.schema, case let .a(ref) = schema, let name = ref.name,
                    let componentKey = OpenAPI.ComponentKey(rawValue: name)
                else { continue }
                refs.insert(componentKey)
            }
        }
        func visitPath(_ path: OpenAPI.PathItem) throws {
            for endpoint in path.endpoints {
                let operation = endpoint.operation
                if let requestBodyEither = operation.requestBody {
                    let requestBody: OpenAPI.Request
                    switch requestBodyEither {
                    case .a(let ref): requestBody = try components.lookup(ref)
                    case .b(let value): requestBody = value
                    }
                    try visitContentMap(requestBody.content)
                }
                for responseOutcome in operation.responseOutcomes {
                    let response: OpenAPI.Response
                    switch responseOutcome.response {
                    case .a(let ref): response = try components.lookup(ref)
                    case .b(let value): response = value
                    }
                    try visitContentMap(response.content)
                }
            }
        }
        for (_, value) in paths {
            let pathItem: OpenAPI.PathItem
            switch value {
            case .a(let ref): pathItem = try components.lookup(ref)
            case .b(let value): pathItem = value
            }
            try visitPath(pathItem)
        }
        return refs
    }
}
