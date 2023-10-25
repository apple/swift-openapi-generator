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

/// An object that parses a provided raw file as an OpenAPI document
/// and validates the contents of the document in the process.
///
/// Parsing is the first phase in the generator pipeline.
protocol ParserProtocol {

    /// Parses the specified raw file as an OpenAPI document.
    /// - Parameters:
    ///   - input: The raw contents of the document.
    ///   - config: The configuration of the generator.
    ///   - diagnostics: The collector to which to emit diagnostics.
    /// - Returns: A parsed and validated OpenAPI document.
    /// - Throws: An error if an issue occurs during parsing or validation.
    func parseOpenAPI(_ input: InMemoryInputFile, config: Config, diagnostics: any DiagnosticCollector) throws
        -> ParsedOpenAPIRepresentation
}
