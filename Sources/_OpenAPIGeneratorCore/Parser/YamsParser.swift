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
import Yams
import OpenAPIKit30
import Foundation

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

        let versionedDocument = try decoder.decode(
            OpenAPIVersionedDocument.self,
            from: openapiData
        )

        guard let openAPIVersion = versionedDocument.openapi else {
            throw OpenAPIMissingVersionError()
        }
        switch openAPIVersion {
        case "3.0.0", "3.0.1", "3.0.2", "3.0.3":
            break
        default:
            throw OpenAPIVersionError(versionString: "openapi: \(openAPIVersion)")
        }

        return try decoder.decode(
            OpenAPI.Document.self,
            from: input.contents
        )
    }
}
