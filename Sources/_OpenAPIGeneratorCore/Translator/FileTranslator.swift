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
import OpenAPIKit30

/// An object that generates a Swift file for a provided OpenAPI document.
///
/// Since the translator always produces a single Swift file, there are
/// multiple implementations, one for each Swift file that the generator
/// supports: types, client, and server.
///
/// Translators contain the majority of the generator's OpenAPI to
/// Swift conversion logic.
protocol FileTranslator {

    /// The configuration tells the translator which Swift file
    /// to generate and what additional import statements to include.
    var config: Config { get }

    /// The collector receives diagnostics from the translator, which should
    /// be surfaced to the user in some way.
    var diagnostics: any DiagnosticCollector { get }

    /// The components section of the OpenAPI document is required by the
    /// translator logic to follow JSON references to schemas, parameters,
    /// and other reusable objects.
    var components: OpenAPI.Components { get }

    /// Translates the specified OpenAPI document to the Swift file
    /// requested by the generator mode.
    /// - Parameter parsedOpenAPI: The OpenAPI document.
    /// - Returns: Structured representation of the generated Swift file.
    func translateFile(
        parsedOpenAPI: ParsedOpenAPIRepresentation
    ) throws -> StructuredSwiftRepresentation
}
