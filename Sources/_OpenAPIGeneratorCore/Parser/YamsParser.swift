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
import ArgumentParser
import Foundation
import OpenAPIKit30
import Yams

/// A parser that uses the Yams library to parse the provided
/// raw file into an OpenAPI document.
struct YamsParser: ParserProtocol {
    func parseOpenAPI(
        _ input: InMemoryInputFile,
        config: Config,
        diagnostics: DiagnosticCollector
    ) throws -> ParsedOpenAPIRepresentation {
        let decoder = YAMLDecoder()
        let openapiData = input.contents

        struct OpenAPIVersionedDocument: Decodable {
            var openapi: String?
        }

        struct OpenAPIVersionError: Error, CustomStringConvertible, LocalizedError {
            var versionString: String
            var description: String {
                "Unsupported document version: \(versionString). Please provide a document with OpenAPI versions in the 3.0.x set."
            }
        }

        struct OpenAPIMissingVersionError: Error, CustomStringConvertible, LocalizedError {
            var description: String {
                "No openapi key found, please provide a valid OpenAPI document with OpenAPI versions in the 3.0.x set."
            }
        }

        let versionedDocument: OpenAPIVersionedDocument
        do {
            versionedDocument = try decoder.decode(
                OpenAPIVersionedDocument.self,
                from: openapiData
            )
        } catch DecodingError.dataCorrupted(let errorContext) {
            try possibly_throw_parsing_error(context: errorContext, input: input, diagnostics: diagnostics)
            throw DecodingError.dataCorrupted(errorContext)
        }

        guard let openAPIVersion = versionedDocument.openapi else {
            throw OpenAPIMissingVersionError()
        }
        switch openAPIVersion {
        case "3.0.0", "3.0.1", "3.0.2", "3.0.3":
            break
        default:
            throw OpenAPIVersionError(versionString: "openapi: \(openAPIVersion)")
        }

        do {
            return try decoder.decode(
                OpenAPI.Document.self,
                from: input.contents
            )
        } catch DecodingError.dataCorrupted(let errorContext) {
            try possibly_throw_parsing_error(context: errorContext, input: input, diagnostics: diagnostics)
            throw DecodingError.dataCorrupted(errorContext)
        }
    }

    /// Detect specific YAML parsing errors to emit nicely formatted errors for IDEs
    private func possibly_throw_parsing_error(
        context: DecodingError.Context,
        input: InMemoryInputFile,
        diagnostics: DiagnosticCollector
    ) throws {
        if let yamlError = context.underlyingError as? YamlError {
            if case .parser(let yamlContext, let yamlProblem, let yamlMark, _) = yamlError {
                try throw_parsing_error(
                    context: yamlContext,
                    problem: yamlProblem,
                    lineNumber: yamlMark.line - 1,
                    input: input,
                    diagnostics
                )
            } else if case .scanner(let yamlContext, let yamlProblem, let yamlMark, _) = yamlError {
                try throw_parsing_error(
                    context: yamlContext,
                    problem: yamlProblem,
                    lineNumber: yamlMark.line - 1,
                    input: input,
                    diagnostics
                )
            }
        } else if let openAPIError = context.underlyingError as? OpenAPIError {
            var problem = Diagnostic.error(message: openAPIError.localizedDescription)
            problem.absoluteFilePath = input.absolutePath
            diagnostics.emit(problem)
            throw ExitCode.failure
        }
    }

    private func throw_parsing_error(
        context: YamlError.Context?,
        problem: String,
        lineNumber: Int,
        input: InMemoryInputFile,
        _ diagnostics: DiagnosticCollector
    ) throws {
        let text = "\(problem) \(context?.description ?? "")"

        var problem = Diagnostic.error(message: text)
        problem.absoluteFilePath = input.absolutePath
        problem.lineNumber = lineNumber
        diagnostics.emit(problem)

        throw ExitCode.failure
    }
}
