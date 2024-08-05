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
        let validationDiagnostics = try validator(doc, config)
        for diagnostic in validationDiagnostics { try diagnostics.emit(diagnostic) }
        return doc
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
