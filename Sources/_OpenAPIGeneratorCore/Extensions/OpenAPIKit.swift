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

extension Either {

    /// Returns the contained value, looking it up in the specified
    /// OpenAPI components if it contains a reference.
    /// - Parameter components: The Components section of the OpenAPI document.
    /// - Returns: The resolved value from the `Either` instance.
    /// - Throws: An error if there's an issue looking up the value in the components.
    func resolve(in components: OpenAPI.Components) throws -> B where A == OpenAPI.Reference<B> {
        switch self {
        case let .a(a): return try components.lookup(a)
        case let .b(b): return b
        }
    }
}

extension JSONSchema.Schema {

    /// Returns the name of the schema.
    var schemaName: String {
        switch self {
        case .boolean: return "boolean"
        case .number: return "number"
        case .integer: return "integer"
        case .string: return "string"
        case .object: return "object"
        case .array: return "array"
        case .all: return "allOf"
        case .one: return "oneOf"
        case .any: return "anyOf"
        case .not: return "not"
        case .reference: return "reference"
        case .fragment: return "fragment"
        case .null: return "null"
        }
    }

    /// Returns the format string of the schema.
    var schemaFormat: String? {
        switch self {
        case .boolean(let coreContext): return coreContext.formatString
        case .number(let coreContext, _): return coreContext.formatString
        case .integer(let coreContext, _): return coreContext.formatString
        case .string(let coreContext, _): return coreContext.formatString
        case .object(let coreContext, _): return coreContext.formatString
        case .array(let coreContext, _): return coreContext.formatString
        case .all(_, let coreContext): return coreContext.formatString
        case .one(_, let coreContext): return coreContext.formatString
        case .any(_, let coreContext): return coreContext.formatString
        case .not(_, let coreContext): return coreContext.formatString
        case .reference: return nil
        case .fragment(let coreContext): return coreContext.formatString
        case .null: return nil
        }
    }

    /// Returns a human-readable description of the schema.
    var prettyDescription: String {
        guard let schemaFormat else { return schemaName }
        return "\(schemaName) (\(schemaFormat))"
    }
}

extension JSONSchema {

    /// Returns a human-readable description of the schema.
    var prettyDescription: String { value.prettyDescription }
}
