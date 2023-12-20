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

/// Validates all content types from an OpenAPI document represented by a ParsedOpenAPIRepresentation.
///
/// This function iterates through the paths, endpoints, and components of the OpenAPI document,
/// checking and reporting any invalid content types using the provided validation closure.
///
/// - Parameters:
///   - doc: The OpenAPI document representation.
///   - validate: A closure to validate each content type.
/// - Throws: An error with diagnostic information if any invalid content types are found.
func validateContentTypes(in doc: ParsedOpenAPIRepresentation, validate: (String) -> Bool) throws {
    for (path, pathValue) in doc.paths {
        guard case .b(let pathItem) = pathValue else { continue }
        for endpoint in pathItem.endpoints {

            if let eitherRequest = endpoint.operation.requestBody {
                if case .b(let actualRequest) = eitherRequest {
                    for contentType in actualRequest.content.keys {
                        if !validate(contentType.rawValue) {
                            throw Diagnostic.error(
                                message:
                                    "Invalid content type string: '\(contentType.rawValue)' found in requestBody at path '\(path.rawValue)'. Must have 2 components separated by a slash '<type>/<subtype>'.\n"
                            )
                        }
                    }
                }
            }

            for eitherResponse in endpoint.operation.responses.values {
                if case .b(let actualResponse) = eitherResponse {
                    for contentType in actualResponse.content.keys {
                        if !validate(contentType.rawValue) {
                            throw Diagnostic.error(
                                message:
                                    "Invalid content type string: '\(contentType.rawValue)' found in responses at path '\(path.rawValue)'. Must have 2 components separated by a slash '<type>/<subtype>'.\n"
                            )
                        }
                    }
                }
            }
        }
    }

    for component in doc.components.requestBodies.values {
        for contentType in component.content.keys {
            if !validate(contentType.rawValue) {
                throw Diagnostic.error(
                    message:
                        "Invalid content type string: '\(contentType.rawValue)' found in #/components/requestBodies. Must have 2 components separated by a slash '<type>/<subtype>'.\n"
                )
            }
        }
    }

    for component in doc.components.responses.values {
        for contentType in component.content.keys {
            if !validate(contentType.rawValue) {
                throw Diagnostic.error(
                    message:
                        "Invalid content type string: '\(contentType.rawValue)' found in #/components/responses. Must have 2 components separated by a slash '<type>/<subtype>'.\n"
                )
            }
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
    try validateContentTypes(in: doc) { contentType in
        (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
    }

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
