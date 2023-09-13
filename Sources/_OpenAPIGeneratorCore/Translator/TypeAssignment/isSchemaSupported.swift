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

/// A result of checking whether a schema is supported.
enum IsSchemaSupportedResult: Equatable {

    /// The schema is supported and can be generated.
    case supported

    /// The reason a schema is unsupported.
    enum UnsupportedReason: Equatable, CustomStringConvertible {

        /// Describes when no subschemas are found in an allOf, oneOf, or anyOf.
        case noSubschemas

        /// Describes when the schema is not object-ish, in other words isn't
        /// an object, a ref, or an allOf.
        case notObjectish

        /// Describes when the schema is not a reference.
        case notRef

        /// Describes when the schema is of an unsupported schema type.
        case schemaType

        var description: String {
            switch self {
            case .noSubschemas:
                return "no subschemas"
            case .notObjectish:
                return "not an object-ish schema (object, ref, allOf)"
            case .notRef:
                return "not a reference"
            case .schemaType:
                return "schema type"
            }
        }
    }

    /// The schema is unsupported for the provided reason.
    case unsupported(reason: UnsupportedReason, schema: JSONSchema)
}

extension FileTranslator {

    /// Validates that the schema is supported by the generator.
    ///
    /// Also emits a diagnostic into the collector if the schema is unsupported.
    /// - Parameters:
    ///   - schema: The schema to validate.
    ///   - foundIn: A description of the schema's context.
    /// - Returns: `true` if the schema is supported; `false` otherwise.
    func validateSchemaIsSupported(
        _ schema: JSONSchema,
        foundIn: String
    ) throws -> Bool {
        switch try isSchemaSupported(schema) {
        case .supported:
            return true
        case .unsupported(reason: let reason, schema: let schema):
            diagnostics.emitUnsupportedSchema(
                reason: reason.description,
                schema: schema,
                foundIn: foundIn
            )
            return false
        }
    }

    /// Validates that the schema is supported by the generator.
    ///
    /// Also emits a diagnostic into the collector if the schema is unsupported.
    /// - Parameters:
    ///   - schema: The schema to validate.
    ///   - foundIn: A description of the schema's context.
    /// - Returns: `true` if the schema is supported; `false` otherwise.
    func validateSchemaIsSupported(
        _ schema: UnresolvedSchema?,
        foundIn: String
    ) throws -> Bool {
        switch try isSchemaSupported(schema) {
        case .supported:
            return true
        case .unsupported(reason: let reason, schema: let schema):
            diagnostics.emitUnsupportedSchema(
                reason: reason.description,
                schema: schema,
                foundIn: foundIn
            )
            return false
        }
    }

    /// Returns whether the schema is supported.
    ///
    /// If a schema is not supported, no references to it should be emitted.
    /// - Parameters:
    ///   - schema: The schema to validate.
    func isSchemaSupported(
        _ schema: JSONSchema
    ) throws -> IsSchemaSupportedResult {
        switch schema.value {
        case .string,
            .integer,
            .number,
            .boolean,
            // We mark any object as supported, even if it
            // has unsupported properties.
            // The code responsible for emitting an object is
            // responsible for picking only supported properties.
            .object,
            .fragment:
            return .supported
        case .reference(let ref, _):
            // reference is supported iff the existing type is supported
            let existingSchema = try components.lookup(ref)
            return try isSchemaSupported(existingSchema)
        case .array(_, let array):
            guard let items = array.items else {
                // an array of fragments is supported
                return .supported
            }
            // an array is supported iff its element schema is supported
            return try isSchemaSupported(items)
        case .all(of: let schemas, _):
            guard !schemas.isEmpty else {
                return .unsupported(
                    reason: .noSubschemas,
                    schema: schema
                )
            }
            return try areSchemasSupported(schemas)
        case .any(of: let schemas, _):
            guard !schemas.isEmpty else {
                return .unsupported(
                    reason: .noSubschemas,
                    schema: schema
                )
            }
            return try areSchemasSupported(schemas)
        case .one(of: let schemas, let context):
            guard !schemas.isEmpty else {
                return .unsupported(
                    reason: .noSubschemas,
                    schema: schema
                )
            }
            guard context.discriminator != nil else {
                return try areSchemasSupported(schemas)
            }
            // > When using the discriminator, inline schemas will not be considered.
            // > — https://spec.openapis.org/oas/v3.0.3#discriminator-object
            return try areRefsToObjectishSchemaAndSupported(schemas.filter(\.isReference))
        case .not, .null:
            return .unsupported(
                reason: .schemaType,
                schema: schema
            )
        }
    }

    /// Returns a result indicating whether the schema is supported.
    ///
    /// If a schema is not supported, no references to it should be emitted.
    /// - Parameters:
    ///   - schema: The schema to validate.
    func isSchemaSupported(
        _ schema: UnresolvedSchema?
    ) throws -> IsSchemaSupportedResult {
        guard let schema else {
            // fragment type is supported
            return .supported
        }
        switch schema {
        case .a:
            // references are supported
            return .supported
        case let .b(schema):
            return try isSchemaSupported(schema)
        }
    }

    /// Returns a result indicating whether the provided schemas
    /// are supported.
    /// - Parameter schemas: Schemas to check.
    func areSchemasSupported(_ schemas: [JSONSchema]) throws -> IsSchemaSupportedResult {
        for schema in schemas {
            let result = try isSchemaSupported(schema)
            guard result == .supported else {
                return result
            }
        }
        return .supported
    }

    /// Returns a result indicating whether the provided schema
    /// is an reference, object, or allOf (object-ish) schema and is supported.
    /// - Parameter schema: A schemas to check.
    func isObjectishSchemaAndSupported(_ schema: JSONSchema) throws -> IsSchemaSupportedResult {
        switch schema.value {
        case .object:
            return try isSchemaSupported(schema)
        case .reference:
            return try isRefToObjectishSchemaAndSupported(schema)
        case .all(of: let schemas, _), .any(of: let schemas, _), .one(of: let schemas, _):
            return try areObjectishSchemasAndSupported(schemas)
        default:
            return .unsupported(
                reason: .notObjectish,
                schema: schema
            )
        }
    }

    /// Returns a result indicating whether the provided schemas
    /// are object-ish schemas and supported.
    /// - Parameter schemas: Schemas to check.
    /// - Returns: `.supported` if all schemas match; `.unsupported` otherwise.
    func areObjectishSchemasAndSupported(_ schemas: [JSONSchema]) throws -> IsSchemaSupportedResult {
        for schema in schemas {
            let result = try isObjectishSchemaAndSupported(schema)
            guard result == .supported else {
                return result
            }
        }
        return .supported
    }

    /// Returns a result indicating whether the provided schemas
    /// are reference schemas that point to object-ish schemas and supported.
    /// - Parameter schemas: Schemas to check.
    /// - Returns: `.supported` if all schemas match; `.unsupported` otherwise.
    func areRefsToObjectishSchemaAndSupported(_ schemas: [JSONSchema]) throws -> IsSchemaSupportedResult {
        for schema in schemas {
            let result = try isRefToObjectishSchemaAndSupported(schema)
            guard result == .supported else {
                return result
            }
        }
        return .supported
    }

    /// Returns a result indicating whether the provided schema
    /// is a reference schema that points to an object-ish schema and is supported.
    /// - Parameter schema: A schema to check.
    func isRefToObjectishSchemaAndSupported(_ schema: JSONSchema) throws -> IsSchemaSupportedResult {
        switch schema.value {
        case let .reference(ref, _):
            let referencedSchema = try components.lookup(ref)
            return try isObjectishSchemaAndSupported(referencedSchema)
        default:
            return .unsupported(
                reason: .notRef,
                schema: schema
            )
        }
    }
}
