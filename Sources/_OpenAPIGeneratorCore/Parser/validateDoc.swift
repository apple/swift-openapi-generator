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

/// Extracts content types from a ParsedOpenAPIRepresentation.
///
/// - Parameter doc: The OpenAPI document representation.
/// - Returns: An array of strings representing content types extracted from requests and responses.
func extractContentTypes(from doc: ParsedOpenAPIRepresentation) -> [String] {
    let contentTypes: [String] = doc.paths.values.flatMap { pathValue -> [OpenAPI.ContentType.RawValue] in
        guard case .b(let pathItem) = pathValue else { return [] }

        let requestBodyContentTypes: [String] = pathItem.endpoints.map { $0.operation.requestBody }
            .compactMap { (eitherRequest: Either<OpenAPI.Reference<OpenAPI.Request>, OpenAPI.Request>?) in
                guard case .b(let actualRequest) = eitherRequest else { return nil }
                return actualRequest.content.keys.first?.rawValue
            }

        let responseContentTypes: [String] = pathItem.endpoints.map { $0.operation.responses.values }
            .flatMap { (response: [Either<OpenAPI.Reference<OpenAPI.Response>, OpenAPI.Response>]) in
                response.compactMap { (eitherResponse: Either<OpenAPI.Reference<OpenAPI.Response>, OpenAPI.Response>) in
                    guard case .b(let actualResponse) = eitherResponse else { return nil }
                    return actualResponse.content.keys.first?.rawValue
                }
            }

        return requestBodyContentTypes + responseContentTypes
    }

    return contentTypes
}

/// Validates an array of content types.
///
/// - Parameter contentTypes: An array of strings representing content types.
/// - Throws: A Diagnostic error if any content type is invalid.
func validateContentTypes(_ contentTypes: [String]) throws {
    let mediaTypePattern = "^[a-zA-Z]+/[a-zA-Z][a-zA-Z-]*$"
    let regex = try! NSRegularExpression(pattern: mediaTypePattern)

    func isValidContentType(_ contentType: String) -> Bool {
        let range = NSRange(location: 0, length: contentType.utf16.count)
        return regex.firstMatch(in: contentType, range: range) != nil
    }

    for contentType in contentTypes {
        guard isValidContentType(contentType) else {
            throw Diagnostic.error(
                message:
                    "Invalid content type string: '\(contentType)' must have 2 components separated by a slash '<type>/<subtype>'.\n"
            )
        }
    }
}

/// Runs validation steps on the incoming OpenAPI document.
/// - Parameters:
///   - doc: The OpenAPI document to validate.
///   - config: The generator config.
/// - Returns: An array of diagnostic messages representing validation warnings.
/// - Throws: An error if a fatal issue is found.
func validateDoc(_ doc: ParsedOpenAPIRepresentation, config: Config) throws -> [Diagnostic] {
    // Run OpenAPIKit's built-in validation.
    // Pass `false` to `strict`, however, because we don't
    // want to turn schema loading warnings into errors.
    // We already propagate the warnings to the generator's
    // diagnostics, so they get surfaced to the user.
    // But the warnings are often too strict and should not
    // block the generator from running.
    // Validation errors continue to be fatal, such as
    // structural issues, like non-unique operationIds, etc.
    let contentTypes = extractContentTypes(from: doc)
    try validateContentTypes(contentTypes)

    let warnings = try doc.validate(using: Validator().validating(.operationsContainResponses), strict: false)
    let diagnostics: [Diagnostic] = warnings.map { warning in
        .warning(
            message: "Validation warning: \(warning.description)",
            context: [
                "codingPath": warning.codingPathString ?? "<none>", "contextString": warning.contextString ?? "<none>",
                "subjectName": warning.subjectName ?? "<none>",
            ]
        )
    }
    return diagnostics
}
