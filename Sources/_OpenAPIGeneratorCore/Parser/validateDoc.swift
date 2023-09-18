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

/// Runs validation steps on the incoming OpenAPI document.
/// - Parameters:
///   - doc: The OpenAPI document to validate.
///   - config: The generator config.
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
    let warnings = try doc.validate(
        using: Validator().validating(.operationsContainResponses),
        strict: false
    )
    let diagnostics: [Diagnostic] = warnings.map { warning in
        .warning(
            message: "Validation warning: \(warning.description)",
            context: [
                "codingPath": warning.codingPathString ?? "<none>",
                "contextString": warning.contextString ?? "<none>",
                "subjectName": warning.subjectName ?? "<none>",
            ]
        )
    }

    // Validate that the document is dereferenceable, which
    // catches reference cycles, which we don't yet support.
    _ = try doc.locallyDereferenced()

    // Also explicitly dereference the parts of components
    // that the generator uses. `locallyDereferenced()` above
    // only dereferences paths/operations, but not components.
    let components = doc.components
    try components.schemas.forEach { schema in
        _ = try schema.value.dereferenced(in: components)
    }
    try components.parameters.forEach { schema in
        _ = try schema.value.dereferenced(in: components)
    }
    try components.headers.forEach { schema in
        _ = try schema.value.dereferenced(in: components)
    }
    try components.requestBodies.forEach { schema in
        _ = try schema.value.dereferenced(in: components)
    }
    try components.responses.forEach { schema in
        _ = try schema.value.dereferenced(in: components)
    }
    return diagnostics
}
