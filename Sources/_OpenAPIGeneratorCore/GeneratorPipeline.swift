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
import Foundation
import Yams

/// A sequence of steps that combined represents the full end-to-end
/// functionality of the generator.
///
/// The input is an in-memory OpenAPI document, and the output is an
/// in-memory generated Swift file. Which file is generated (types, client,
/// or server) is controlled by the generator configuration, in the translation
/// stage.
///
/// The pipeline goes through several stages, similar to a compiler:
/// 1. Parsing: RawInput -> ParsedInput, which converts a raw OpenAPI file
/// into type-safe OpenAPIKit types.
/// 2. Translation: ParsedInput -> TranslatedOutput, which converts an OpenAPI
/// document into a structure Swift representation of the requested generated
/// file, for one of: types, client, or server. This stage contains most of the
/// OpenAPI to Swift generation code.
/// 3. Rendering: TranslatedOutput -> RenderedOutput, which converts a
/// structured Swift representation into a raw Swift file.
struct GeneratorPipeline {

    // Note: Until we have variadic generics we need to have a fixed number
    // of type parameters, but this is fine because have all the concrete
    // types for the stage boundaries already defined.

    /// A raw input into the parsing stage, usually read from disk.
    typealias RawInput = InMemoryInputFile

    /// An output of the parsing stage and an input into the translation stage.
    typealias ParsedInput = ParsedOpenAPIRepresentation

    /// An output of the translation stage and an input of the rendering stage.
    typealias TranslatedOutput = StructuredSwiftRepresentation

    /// An output of the rendering phase, usually written to disk.
    typealias RenderedOutput = RenderedSwiftRepresentation

    /// The parsing stage.
    var parseOpenAPIFileStage: GeneratorPipelineStage<RawInput, ParsedInput>

    /// The translation phase.
    var translateOpenAPIToStructuredSwiftStage: GeneratorPipelineStage<ParsedInput, TranslatedOutput>

    /// The rendering phase.
    var renderSwiftFilesStage: GeneratorPipelineStage<TranslatedOutput, RenderedOutput>

    /// Runs the full pipeline.
    ///
    /// Throws an error when encountering a non-recoverable issue.
    ///
    /// When possible, use ``DiagnosticCollector`` instead to emit
    /// recoverable diagnostics, such as unsupported features.
    /// - Parameter input: The input of the parsing stage.
    /// - Returns: The output of the rendering stage.
    /// - Throws: An error if a non-recoverable issue occurs during pipeline execution.
    func run(_ input: RawInput) throws -> RenderedOutput {
        try renderSwiftFilesStage.run(translateOpenAPIToStructuredSwiftStage.run(parseOpenAPIFileStage.run(input)))
    }
}

/// Runs the generator logic with the specified inputs.
/// - Parameters:
///   - input: The raw file contents of the OpenAPI document.
///   - config: A set of configuration values for the generator.
///   - diagnostics: A collector to which the generator emits diagnostics.
/// - Throws: When encountering a non-recoverable error. For recoverable
/// issues, emits issues into the diagnostics collector.
/// - Returns: The raw contents of the generated Swift file.
public func runGenerator(input: InMemoryInputFile, config: Config, diagnostics: any DiagnosticCollector) throws
    -> InMemoryOutputFile
{ try makeGeneratorPipeline(config: config, diagnostics: diagnostics).run(input) }

/// Creates a new pipeline instance.
/// - Parameters:
///   - parser: An OpenAPI document parser.
///   - validator: A validator for parsed OpenAPI documents.
///   - translator: A translator from OpenAPI to Swift.
///   - renderer: A Swift code renderer.
///   - config: A set of configuration values for the generator.
///   - diagnostics: A collector to which the generator emits diagnostics.
/// - Returns: A configured generator pipeline that can be executed with
/// ``GeneratorPipeline/run(_:)``.
func makeGeneratorPipeline(
    parser: any ParserProtocol = YamsParser(),
    validator: @escaping (ParsedOpenAPIRepresentation, Config) throws -> [Diagnostic] = validateDoc,
    translator: any TranslatorProtocol = MultiplexTranslator(),
    renderer: any RendererProtocol = TextBasedRenderer.default,
    config: Config,
    diagnostics: any DiagnosticCollector
) -> GeneratorPipeline {
    let filterDoc = { (doc: OpenAPI.Document) -> OpenAPI.Document in
        guard let documentFilter = config.filter else { return doc }
        let filteredDoc: OpenAPI.Document = try documentFilter.filter(doc)
        return filteredDoc
    }
    let validateDoc = { (doc: OpenAPI.Document) -> OpenAPI.Document in
        let sanitizedDoc = sanitizeSchemaNulls(doc)
        let validationDiagnostics = try validator(sanitizedDoc, config)
        for diagnostic in validationDiagnostics { try diagnostics.emit(diagnostic) }
        return sanitizedDoc
    }
    return .init(
        parseOpenAPIFileStage: .init(
            preTransitionHooks: [],
            transition: { input in try parser.parseOpenAPI(input, config: config, diagnostics: diagnostics) },
            postTransitionHooks: [filterDoc, validateDoc]
        ),
        translateOpenAPIToStructuredSwiftStage: .init(
            preTransitionHooks: [],
            transition: { input in
                try translator.translate(parsedOpenAPI: input, config: config, diagnostics: diagnostics)
            },
            postTransitionHooks: []
        ),
        renderSwiftFilesStage: .init(
            preTransitionHooks: [],
            transition: { input in try renderer.render(structured: input, config: config, diagnostics: diagnostics) },
            postTransitionHooks: []
        )
    )
}

extension JSONSchema {
    /// Recursively removes null type entries from anyOf and oneOf arrays in the schema
    /// When null is removed, it will set the schema context for that field as nullable to preserve semantics
    /// This approach may not be 100% correct but it enables functionality that would otherwise fail.
    ///
    /// Background: currently, there are challenges with supporting OpenAPI definitions like this:
    /// ```
    /// "phoneNumber": {
    ///   "description": "phone number",
    ///     "anyOf": [
    ///       { "$ref": "#/components/schemas/PhoneNumber" },
    ///       { "type": "null" }
    ///     ]
    /// }
    /// "phoneNumber2": {
    ///   "description": "phone number",
    ///     "oneOf": [
    ///       { "$ref": "#/components/schemas/PhoneNumber" },
    ///       { "type": "null" }
    ///     ]
    /// }
    /// "phoneNumber3": {
    ///   "description": "phone number",
    ///     "oneOf": [
    ///       { "$ref": "#/components/schemas/PhoneNumber" },
    ///       { "$ref": "#/components/schemas/PhoneNumber2" },
    ///       { "type": "null" }
    ///     ]
    /// }
    /// ```
    /// This code will effectively treat those definitions as the following while marking them as nullable.
    /// ```
    /// "phoneNumber": {
    ///   "description": "phone number",
    ///     "$ref": "#/components/schemas/PhoneNumber"
    /// }
    /// "phoneNumber2": {
    ///   "description": "phone number",
    ///     "$ref": "#/components/schemas/PhoneNumber"
    /// }
    /// "phoneNumber3": {
    ///   "description": "phone number",
    ///     "oneOf": [
    ///       { "$ref": "#/components/schemas/PhoneNumber" },
    ///       { "$ref": "#/components/schemas/PhoneNumber2" }
    ///     ]
    /// }
    /// ```
    func removingNullFromAnyOfAndOneOf() -> JSONSchema {
        switch self.value {
        case .object(let coreContext, let objectContext):
            // Handle object properties
            var newProperties = OrderedDictionary<String, JSONSchema>()
            for (key, value) in objectContext.properties { newProperties[key] = value.removingNullFromAnyOfAndOneOf() }
            // Handle additionalProperties if it exists
            let newAdditionalProperties: Either<Bool, JSONSchema>?
            if let additionalProps = objectContext.additionalProperties {
                switch additionalProps {
                case .a(let boolValue): newAdditionalProperties = .a(boolValue)
                case .b(let schema): newAdditionalProperties = .b(schema.removingNullFromAnyOfAndOneOf())
                }
            } else {
                newAdditionalProperties = nil
            }
            // Create new ObjectContext
            let newObjectContext = JSONSchema.ObjectContext(
                properties: newProperties,
                additionalProperties: newAdditionalProperties,
                maxProperties: objectContext.maxProperties,
                minProperties: objectContext.minProperties
            )
            return JSONSchema(schema: .object(coreContext, newObjectContext))
        case .array(let coreContext, let arrayContext):
            // Handle array items
            let newItems = arrayContext.items?.removingNullFromAnyOfAndOneOf()
            let newArrayContext = JSONSchema.ArrayContext(
                items: newItems,
                maxItems: arrayContext.maxItems,
                minItems: arrayContext.minItems,
                prefixItems: arrayContext.prefixItems?.map { $0.removingNullFromAnyOfAndOneOf() },
                uniqueItems: arrayContext.uniqueItems
            )
            return JSONSchema(schema: .array(coreContext, newArrayContext))
        case .all(of: let schemas, core: let coreContext):
            // Handle allOf
            let newSchemas = schemas.map { $0.removingNullFromAnyOfAndOneOf() }
            return JSONSchema(schema: .all(of: newSchemas, core: coreContext))
        case .one(of: let schemas, core: let coreContext):
            // Handle oneOf - apply same null removal logic as anyOf
            let filteredSchemas = schemas.compactMap { schema -> JSONSchema? in
                // Remove schemas that are just null types
                if case .null = schema.value { return nil }
                return schema.removingNullFromAnyOfAndOneOf()
            }
            // Check if we removed any null schemas
            let hadNullSchema = schemas.count > filteredSchemas.count
            // If we only have one schema left after filtering, return it directly (and make it nullable if we removed null)
            if filteredSchemas.count == 1 {
                let resultSchema = filteredSchemas[0]
                return hadNullSchema ? resultSchema.nullableSchemaObjectCopy() : resultSchema
            } else if filteredSchemas.isEmpty {
                // If all schemas were null, return a null schema (edge case)
                return JSONSchema(schema: .null(coreContext))
            } else {
                // Multiple schemas remain, keep as oneOf (and make nullable if we removed null)
                let resultSchema = JSONSchema(schema: .one(of: filteredSchemas, core: coreContext))
                return hadNullSchema ? resultSchema.nullableSchemaObjectCopy() : resultSchema
            }
        case .any(of: let schemas, core: let coreContext):
            // Handle anyOf - this is where we remove null types
            let filteredSchemas = schemas.compactMap { schema -> JSONSchema? in
                // Remove schemas that are just null types
                if case .null = schema.value { return nil }
                return schema.removingNullFromAnyOfAndOneOf()
            }
            // Check if we removed any null schemas
            let hadNullSchema = schemas.count > filteredSchemas.count
            // If we only have one schema left after filtering, return it directly (and make it nullable if we removed null)
            if filteredSchemas.count == 1 {
                let resultSchema = filteredSchemas[0]
                return hadNullSchema ? resultSchema.nullableSchemaObjectCopy() : resultSchema
            } else if filteredSchemas.isEmpty {
                // If all schemas were null, return a null schema (edge case)
                return JSONSchema(schema: .null(coreContext))
            } else {
                // Multiple schemas remain, keep as anyOf (and make nullable if we removed null)
                let resultSchema = JSONSchema(schema: .any(of: filteredSchemas, core: coreContext))
                return hadNullSchema ? resultSchema.nullableSchemaObjectCopy() : resultSchema
            }
        case .not(let schema, core: let coreContext):
            // Handle not
            return JSONSchema(schema: .not(schema.removingNullFromAnyOfAndOneOf(), core: coreContext))
        case .reference:
            // References remain unchanged
            return self
        default:
            // For primitive types (string, number, integer, boolean, null, fragment), return as-is
            return self
        }
    }
}

/// Extension for OpenAPI.ComponentDictionary<JSONSchema>
/// Need to constrain both the Key and Value types properly
extension OrderedDictionary where Key == OpenAPI.ComponentKey, Value == JSONSchema {
    /// Removes null types from anyOf arrays in all JSONSchemas in the component dictionary
    func removingNullFromAnyOfAndOneOf() -> OpenAPI.ComponentDictionary<JSONSchema> {
        self.mapValues { schema in schema.removingNullFromAnyOfAndOneOf() }
    }
}

/// uses `removingNullFromAnyOfAndOneOf()` to remove from an OpenAPI Document
func sanitizeSchemaNulls(_ doc: OpenAPI.Document) -> OpenAPI.Document {
    var doc = doc
    doc.components.schemas = doc.components.schemas.removingNullFromAnyOfAndOneOf()
    return doc
}

extension JSONSchema {
    /// this simply makes a copy changing on the value of nullable to true, it handles `.reference`
    /// directly or calls nullableSchemaObject()` located in `OpenAPIKit`
    public func nullableSchemaObjectCopy() -> JSONSchema {
        if case let .reference(schema, core) = value {
            return .init(schema: .reference(schema, core.nullableContext()))
        } else {
            return self.nullableSchemaObject()
        }
    }
}
