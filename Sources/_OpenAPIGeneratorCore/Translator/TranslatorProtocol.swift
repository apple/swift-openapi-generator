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

/// An object that turns an OpenAPI document into the structured Swift
/// representation of the request generated file: types, client, or server.
protocol TranslatorProtocol {

    /// Translates the provided OpenAPI document into Swift code.
    /// - Parameters:
    ///   - parsedOpenAPI: The input OpenAPI document.
    ///   - config: A set of configuration values for the generator, such as
    ///   which file to generate code for.
    ///   - diagnostics: The collector to which the translator emits
    ///   diagnostics.
    /// - Returns: A structured Swift representation of the generated code.
    /// - Throws: An error if there are issues parsing or translating the request body.
    func translate(parsedOpenAPI: ParsedOpenAPIRepresentation, config: Config, diagnostics: any DiagnosticCollector)
        throws -> StructuredSwiftRepresentation
}
