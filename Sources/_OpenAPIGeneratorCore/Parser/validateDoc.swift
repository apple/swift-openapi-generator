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
/// - Parameters:
///   - validate: A closure to validate each content type.
func validateContentTypes(_ validate: @escaping (String) -> Bool) -> Validation<OpenAPI.ContentType> {
    return .init(
        description: "Content type is of form '<type>/<subtype>'.",
        check: take(\.rawValue, check: validate)
    )
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
    let typeOverrideDiagnostics = validateTypeOverrides(doc, config: config)

    // Run OpenAPIKit's default built-in validations and additionally check
    // that all references point to entries in the Components Object, all
    // operations contain responses, and all content types parse by this
    // library's code.
    //
    // Pass `false` to `strict`, however, because we don't
    // want to turn schema loading warnings into errors.
    // We already propagate the warnings to the generator's
    // diagnostics, so they get surfaced to the user.
    // But the warnings are often too strict and should not
    // block the generator from running.
    // Validation errors continue to be fatal, such as
    // structural issues, non-unique operationIds, etc.
    let contentTypesValidation = validateContentTypes() { contentType in (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil }
    let validator = Validator()
        .validatingAllReferencesFoundInComponents()
        .validating(.operationsContainResponses)
        .validating(contentTypesValidation)
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
