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
        guard try isSchemaSupported(schema) else {
            diagnostics.emitUnsupported("Schema", foundIn: foundIn)
            return false
        }
        return true
    }

    /// Validates that the schema is supported by the generator.
    ///
    /// Also emits a diagnostic into the collector if the schema is unsupported.
    /// - Parameters:
    ///   - schema: The schema to validate.
    ///   - foundIn: A description of the schema's context.
    /// - Returns: `true` if the schema is supported; `false` otherwise.
    func validateSchemaIsSupported(
        _ schema: Either<JSONReference<JSONSchema>, JSONSchema>?,
        foundIn: String
    ) throws -> Bool {
        guard try isSchemaSupported(schema) else {
            diagnostics.emitUnsupported("Schema", foundIn: foundIn)
            return false
        }
        return true
    }

    /// Returns a Boolean value that indicates whether the schema is supported.
    ///
    /// If a schema is not supported, no references to it should be emitted.
    /// - Parameters:
    ///   - schema: The schema to validate.
    /// - Returns: `true` if the schema is supported; `false` otherwise.
    func isSchemaSupported(
        _ schema: JSONSchema
    ) throws -> Bool {
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
            return true
        case .reference(let ref, _):
            // reference is supported iff the existing type is supported
            let existingSchema = try components.lookup(ref)
            return try isSchemaSupported(existingSchema)
        case .array(_, let array):
            guard let items = array.items else {
                // an array of fragments is supported
                return true
            }
            // an array is supported iff its element schema is supported
            return try isSchemaSupported(items)
        case .all(of: let schemas, _):
            guard !schemas.isEmpty else {
                return false
            }
            return try areObjectishSchemasAndSupported(schemas)
        case .any(of: let schemas, _):
            guard !schemas.isEmpty else {
                return false
            }
            return try areObjectishSchemasAndSupported(schemas)
        case .one(of: let schemas, let context):
            guard !schemas.isEmpty else {
                return false
            }
            // If a discriminator is provided, only refs to object/allOf of
            // object schemas are allowed.
            // Otherwise, any schema is allowed.
            guard context.discriminator != nil else {
                return try areSchemasSupported(schemas)
            }
            return try areRefsToObjectishSchemaAndSupported(schemas)
        case .not:
            return false
        }
    }

    /// Returns a Boolean value that indicates whether the schema is supported.
    ///
    /// If a schema is not supported, no references to it should be emitted.
    /// - Parameters:
    ///   - schema: The schema to validate.
    /// - Returns: `true` if the schema is supported; `false` otherwise.
    func isSchemaSupported(
        _ schema: Either<JSONReference<JSONSchema>, JSONSchema>?
    ) throws -> Bool {
        guard let schema else {
            // fragment type is supported
            return true
        }
        switch schema {
        case .a:
            // references are supported
            return true
        case let .b(schema):
            return try isSchemaSupported(schema)
        }
    }

    /// Returns a Boolean value that indicates whether the provided schemas
    /// are supported.
    /// - Parameter schemas: Schemas to check.
    /// - Returns: `true` if all schemas are supported; `false` otherwise.
    func areSchemasSupported(_ schemas: [JSONSchema]) throws -> Bool {
        try schemas.allSatisfy(isSchemaSupported)
    }

    /// Returns a Boolean value that indicates whether the provided schemas
    /// are reference, object, or allOf schemas and supported.
    /// - Parameter schemas: Schemas to check.
    /// - Returns: `true` if all schemas match; `false` otherwise.
    func areObjectishSchemasAndSupported(_ schemas: [JSONSchema]) throws -> Bool {
        try schemas.allSatisfy(isObjectishSchemaAndSupported)
    }

    /// Returns a Boolean value that indicates whether the provided schema
    /// is an reference, object, or allOf (object-ish) schema and is supported.
    /// - Parameter schema: A schemas to check.
    /// - Returns: `true` if the schema matches; `false` otherwise.
    func isObjectishSchemaAndSupported(_ schema: JSONSchema) throws -> Bool {
        switch schema.value {
        case .object, .reference:
            return try isSchemaSupported(schema)
        case .all(of: let schemas, _):
            return try areObjectishSchemasAndSupported(schemas)
        default:
            return false
        }
    }

    /// Returns a Boolean value that indicates whether the provided schemas
    /// are reference schemas that point to object-ish schemas and supported.
    /// - Parameter schemas: Schemas to check.
    /// - Returns: `true` if all schemas match; `false` otherwise.
    func areRefsToObjectishSchemaAndSupported(_ schemas: [JSONSchema]) throws -> Bool {
        try schemas.allSatisfy(isRefToObjectishSchemaAndSupported)
    }

    /// Returns a Boolean value that indicates whether the provided schema
    /// is a reference schema that points to an object-ish schema and is supported.
    /// - Parameter schema: A schema to check.
    /// - Returns: `true` if the schema matches; `false` otherwise.
    func isRefToObjectishSchemaAndSupported(_ schema: JSONSchema) throws -> Bool {
        switch schema.value {
        case .reference:
            return try isObjectishSchemaAndSupported(schema)
        default:
            return false
        }
    }
}
