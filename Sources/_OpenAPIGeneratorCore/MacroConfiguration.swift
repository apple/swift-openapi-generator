//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Configuration for attaching attribute annotations (macros) to generated declarations.
///
/// Use this to emit `@MyMacro` or similar attributes before generated types.
/// The attribute text is emitted verbatim, so the corresponding module must be
/// imported via ``Config/additionalImports``.
///
/// ## Example
///
/// ```yaml
/// additionalImports:
///   - MyMacros
/// macroAnnotations:
///   schemas:
///     "*":
///       - "@MyMacro"
///     "Pet":
///       - "@PetMacro(enabled: true)"
///   client:
///     - "@ClientMacro"
/// ```
public struct MacroConfiguration: Sendable, Codable, Equatable {

    /// Attribute annotations applied to named schema types in `Types.swift`.
    ///
    /// Keys are OpenAPI component schema names (e.g. `"Pet"`) or `"*"` for a
    /// wildcard that matches every generated schema type. Both the wildcard
    /// and any exact-match annotations are collected (wildcard first).
    public var schemas: [String: [String]]

    /// Attribute annotations applied to the generated `Client` struct in `Client.swift`.
    public var client: [String]

    /// Creates a new macro configuration.
    /// - Parameters:
    ///   - schemas: Per-schema attribute rules, keyed by OpenAPI schema name or `"*"`.
    ///   - client: Attribute annotations for the generated `Client` struct.
    public init(schemas: [String: [String]] = [:], client: [String] = []) {
        self.schemas = schemas
        self.client = client
    }

    /// Returns the attribute strings to apply to a schema type with the given OpenAPI name.
    ///
    /// Collects wildcard (`"*"`) entries first, then exact-name entries.
    /// - Parameter name: The OpenAPI component schema name (e.g. `"Pet"`).
    /// - Returns: An ordered list of raw attribute strings, possibly empty.
    public func attributes(forSchema name: String) -> [String] {
        var result: [String] = []
        result += schemas["*", default: []]
        if name != "*" { result += schemas[name, default: []] }
        return result
    }

    /// The default empty configuration.
    public static let `default` = MacroConfiguration()
}
