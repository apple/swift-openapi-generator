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
import Foundation
import OpenAPIKit30
import Yams

/// A parser that uses the Yams library to parse the provided
/// raw file into an OpenAPI document.
struct YamsParser: ParserProtocol {
    func parseOpenAPI(
        _ input: InMemoryInputFile,
        config: Config,
        diagnostics: any DiagnosticCollector
    ) throws -> ParsedOpenAPIRepresentation {
        let decoder = YAMLDecoder()
        let openapiData = input.contents

        struct OpenAPIVersionedDocument: Decodable {
            var openapi: String?
        }

        let versionedDocument: OpenAPIVersionedDocument
        do {
            versionedDocument = try decoder.decode(
                OpenAPIVersionedDocument.self,
                from: openapiData
            )
        } catch DecodingError.dataCorrupted(let errorContext) {
            try checkParsingError(context: errorContext, input: input)
            throw DecodingError.dataCorrupted(errorContext)
        }

        guard let openAPIVersion = versionedDocument.openapi else {
            throw Diagnostic.openAPIMissingVersionError(location: .init(filePath: input.absolutePath.path))
        }
        switch openAPIVersion {
        case "3.0.0", "3.0.1", "3.0.2", "3.0.3":
            break
        default:
            throw Diagnostic.openAPIVersionError(
                versionString: "openapi: \(openAPIVersion)",
                location: .init(filePath: input.absolutePath.path)
            )
        }

        do {
            return try decoder.decode(
                OpenAPI.Document.self,
                from: input.contents
            )
        } catch DecodingError.dataCorrupted(let errorContext) {
            try checkParsingError(context: errorContext, input: input)
            throw DecodingError.dataCorrupted(errorContext)
        }
    }

    /// Detect specific YAML parsing errors to throw nicely formatted diagnostics for IDEs
    /// - Parameters:
    ///   - context: The error context that triggered the `DecodingError`.
    ///   - input: The input file that was being worked on when the error was triggered.
    /// - Throws: Will throw a `Diagnostic` if the decoding error is a common parsing error.
    private func checkParsingError(
        context: DecodingError.Context,
        input: InMemoryInputFile
    ) throws {
        if let yamlError = context.underlyingError as? YamlError {
            if case .parser(let yamlContext, let yamlProblem, let yamlMark, _) = yamlError {
                throw Diagnostic.error(
                    message: "\(yamlProblem) \(yamlContext?.description ?? "")",
                    location: .init(filePath: input.absolutePath.path, lineNumber: yamlMark.line - 1)
                )
            } else if case .scanner(let yamlContext, let yamlProblem, let yamlMark, _) = yamlError {
                throw Diagnostic.error(
                    message: "\(yamlProblem) \(yamlContext?.description ?? "")",
                    location: .init(filePath: input.absolutePath.path, lineNumber: yamlMark.line - 1)
                )
            }
        } else if let openAPIError = context.underlyingError as? (any OpenAPIError) {
            throw Diagnostic.error(
                message: openAPIError.localizedDescription,
                location: .init(filePath: input.absolutePath.path)
            )
        }
    }
}

extension Diagnostic {
    /// Use when the document is an unsupported version.
    /// - Parameters:
    ///   - versionString: The OpenAPI version number that was parsed from the document.
    ///   - location: Describes the input file being worked on when the error occurred.
    /// - Returns: An error diagnostic.
    static func openAPIVersionError(versionString: String, location: Location) -> Diagnostic {
        return error(
            message:
                "Unsupported document version: \(versionString). Please provide a document with OpenAPI versions in the 3.0.x set.",
            location: location
        )
    }

    /// Use when the YAML document is completely missing the `openapi` version key.
    /// - Parameter location: Describes the input file being worked on when the error occurred
    /// - Returns: An error diagnostic.
    static func openAPIMissingVersionError(location: Location) -> Diagnostic {
        return error(
            message:
                "No openapi key found, please provide a valid OpenAPI document with OpenAPI versions in the 3.0.x set.",
            location: location
        )
    }
}
