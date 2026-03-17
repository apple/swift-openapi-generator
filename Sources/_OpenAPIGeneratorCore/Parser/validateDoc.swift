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
        guard let pathItem = pathValue.pathItemValue else { continue }
        for endpoint in pathItem.endpoints {

            if let eitherRequest = endpoint.operation.requestBody {
                if let actualRequest = eitherRequest.requestValue {
                    for contentType in actualRequest.content.keys {
                        if !validate(contentType.rawValue) {
                            throw Diagnostic.error(
                                message: "Invalid content type string.",
                                context: [
                                    "contentType": contentType.rawValue,
                                    "location": "\(path.rawValue)/\(endpoint.method.rawValue)/requestBody",
                                    "recoverySuggestion":
                                        "Must have 2 components separated by a slash '<type>/<subtype>'.",
                                ]
                            )
                        }
                    }
                }
            }

            for eitherResponse in endpoint.operation.responses.values {
                if let actualResponse = eitherResponse.responseValue {
                    for contentType in actualResponse.content.keys {
                        if !validate(contentType.rawValue) {
                            throw Diagnostic.error(
                                message: "Invalid content type string.",
                                context: [
                                    "contentType": contentType.rawValue,
                                    "location": "\(path.rawValue)/\(endpoint.method.rawValue)/responses",
                                    "recoverySuggestion":
                                        "Must have 2 components separated by a slash '<type>/<subtype>'.",
                                ]
                            )
                        }
                    }
                }
            }
        }
    }

    for (key, component) in doc.components.requestBodies {
        let component = try doc.components.assumeLookupOnce(component)
        for contentType in component.content.keys {
            if !validate(contentType.rawValue) {
                throw Diagnostic.error(
                    message: "Invalid content type string.",
                    context: [
                        "contentType": contentType.rawValue, "location": "#/components/requestBodies/\(key.rawValue)",
                        "recoverySuggestion": "Must have 2 components separated by a slash '<type>/<subtype>'.",
                    ]
                )
            }
        }
    }

    for (key, component) in doc.components.responses {
        let component = try doc.components.assumeLookupOnce(component)
        for contentType in component.content.keys {
            if !validate(contentType.rawValue) {
                throw Diagnostic.error(
                    message: "Invalid content type string.",
                    context: [
                        "contentType": contentType.rawValue, "location": "#/components/responses/\(key.rawValue)",
                        "recoverySuggestion": "Must have 2 components separated by a slash '<type>/<subtype>'.",
                    ]
                )
            }
        }
    }
}

/// Validates all type overrides from a Config are present in the components of a ParsedOpenAPIRepresentation.
///
/// This method iterates through the type overrides defined in the config and checks that for each of them a named schema is defined in the OpenAPI document.
///
/// - Parameters:
///   - doc: The OpenAPI document to validate.
///   - config: The generator config.
/// - Returns: An array of diagnostic messages representing type overrides for nonexistent schemas.
func validateTypeOverrides(_ doc: ParsedOpenAPIRepresentation, config: Config) -> [Diagnostic] {
    let nonExistentOverrides = config.typeOverrides.schemas.keys
        .filter { key in
            guard let componentKey = OpenAPI.ComponentKey(rawValue: key) else { return false }
            return !doc.components.schemas.contains(key: componentKey)
        }
        .sorted()
    return nonExistentOverrides.map { override in
        Diagnostic.warning(
            message: "A type override defined for schema '\(override)' is not defined in the OpenAPI document."
        )
    }
}

/// Runs validation steps on the incoming OpenAPI document.
/// - Parameters:
///   - doc: The OpenAPI document to validate.
///   - config: The generator config.
/// - Returns: An array of diagnostic messages representing validation warnings.
/// - Throws: An error if a fatal issue is found.
func validateDoc(_ doc: ParsedOpenAPIRepresentation, config: Config) throws -> [Diagnostic] {
    try validateContentTypes(in: doc) { contentType in
        (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
    }
    let typeOverrideDiagnostics = validateTypeOverrides(doc, config: config)

    // Run OpenAPIKit's default built-in validations and additionally check
    // that all references point to entries in the Components Object and all
    // operations contain responses.
    //
    // Pass `false` to `strict`, however, because we don't
    // want to turn schema loading warnings into errors.
    // We already propagate the warnings to the generator's
    // diagnostics, so they get surfaced to the user.
    // But the warnings are often too strict and should not
    // block the generator from running.
    // Validation errors continue to be fatal, such as
    // structural issues, non-unique operationIds, etc.
    let validator = Validator()
        .validatingAllReferencesFoundInComponents()
        .validating(.operationsContainResponses)
    let warnings = try doc.validate(using: validator, strict: false)
    let diagnostics: [Diagnostic] = warnings.map { warning in
        .warning(
            message: "Validation warning: \(warning.description)",
            context: [
                "codingPath": warning.codingPathString ?? "<none>", "contextString": warning.contextString ?? "<none>",
                "subjectName": warning.subjectName ?? "<none>",
            ]
        )
    }
    return typeOverrideDiagnostics + diagnostics
}
