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
import OpenAPIKit
import OpenAPIKit30
import OpenAPIKitCompat
import Yams

/// A parser that uses the Yams library to parse the provided
/// raw file into an OpenAPI document.
public struct YamsParser: ParserProtocol {

    /// Extracts the top-level keys from a YAML string.
    ///
    /// - Parameter yamlString: The YAML string from which to extract keys.
    /// - Returns: An array of top-level keys as strings.
    /// - Throws: An error if there are any issues with parsing the YAML string.
    public static func extractTopLevelKeys(fromYAMLString yamlString: String) throws -> [String] {
        var yamlKeys = [String]()
        let parser = try Parser(yaml: yamlString)

        if let rootNode = try parser.singleRoot(),
            case let .mapping(mapping) = rootNode
        {
            for (key, _) in mapping {
                yamlKeys.append(key.string ?? "")
            }
        }
        return yamlKeys
    }

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
        do {
            let document: OpenAPIKit.OpenAPI.Document
            switch openAPIVersion {
            case "3.0.0", "3.0.1", "3.0.2", "3.0.3":
                let openAPI30Document = try decoder.decode(
                    OpenAPIKit30.OpenAPI.Document.self,
                    from: input.contents
                )
                document = openAPI30Document.convert(to: .v3_1_0)
            case "3.1.0":
                document = try decoder.decode(
                    OpenAPIKit.OpenAPI.Document.self,
                    from: input.contents
                )
            default:
                throw Diagnostic.openAPIVersionError(
                    versionString: "openapi: \(openAPIVersion)",
                    location: .init(filePath: input.absolutePath.path)
                )
            }
            return document
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
                "Unsupported document version: \(versionString). Please provide a document with OpenAPI versions in the 3.0.x or 3.1.x sets.",
            location: location
        )
    }

    /// Use when the YAML document is completely missing the `openapi` version key.
    /// - Parameter location: Describes the input file being worked on when the error occurred
    /// - Returns: An error diagnostic.
    static func openAPIMissingVersionError(location: Location) -> Diagnostic {
        return error(
            message:
                "No openapi key found, please provide a valid OpenAPI document with OpenAPI versions in the 3.0.x or 3.1.x sets.",
            location: location
        )
    }
}
