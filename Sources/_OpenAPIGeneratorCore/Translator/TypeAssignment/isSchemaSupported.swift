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
        _ schema: UnresolvedSchema?,
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
    ///   - seenReferences: A set of seen references, used to detect cycles.
    /// - Returns: `true` if the schema is supported; `false` otherwise.
    func isSchemaSupported(
        _ schema: JSONSchema,
        seenReferences: Set<String> = []
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
            let referenceString = ref.absoluteString
            guard !seenReferences.contains(referenceString) else {
                throw JSONReferenceParsingError.referenceCycleUnsupported(referenceString)
            }
            // reference is supported iff the existing type is supported
            let existingSchema = try components.lookup(ref)
            return try isSchemaSupported(existingSchema, seenReferences: seenReferences.union([referenceString]))
        case .array(_, let array):
            guard let items = array.items else {
                // an array of fragments is supported
                return true
            }
            // an array is supported iff its element schema is supported
            return try isSchemaSupported(items, seenReferences: seenReferences)
        case .all(of: let schemas, _):
            guard !schemas.isEmpty else {
                return false
            }
            return try areObjectishSchemasAndSupported(schemas, seenReferences: seenReferences)
        case .any(of: let schemas, _):
            guard !schemas.isEmpty else {
                return false
            }
            return try areObjectishSchemasAndSupported(schemas, seenReferences: seenReferences)
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
            return try areRefsToObjectishSchemaAndSupported(schemas, seenReferences: seenReferences)
        case .not:
            return false
        }
    }

    /// Returns a Boolean value that indicates whether the schema is supported.
    ///
    /// If a schema is not supported, no references to it should be emitted.
    /// - Parameters:
    ///   - schema: The schema to validate.
    ///   - seenReferences: A set of seen references, used to detect cycles.
    /// - Returns: `true` if the schema is supported; `false` otherwise.
    func isSchemaSupported(
        _ schema: UnresolvedSchema?,
        seenReferences: Set<String> = []
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
            return try isSchemaSupported(schema, seenReferences: seenReferences)
        }
    }

    /// Returns a Boolean value that indicates whether the provided schemas
    /// are supported.
    /// - Parameter:
    ///   - schemas: Schemas to check.
    ///   - seenReferences: A set of seen references, used to detect cycles.
    /// - Returns: `true` if all schemas are supported; `false` otherwise.
    func areSchemasSupported(
        _ schemas: [JSONSchema],
        seenReferences: Set<String> = []
    ) throws -> Bool {
        try schemas.allSatisfy { try isSchemaSupported($0, seenReferences: seenReferences) }
    }

    /// Returns a Boolean value that indicates whether the provided schemas
    /// are reference, object, or allOf schemas and supported.
    /// - Parameter:
    ///   - schemas: Schemas to check.
    ///   - seenReferences: A set of seen references, used to detect cycles.
    /// - Returns: `true` if all schemas match; `false` otherwise.
    func areObjectishSchemasAndSupported(
        _ schemas: [JSONSchema],
        seenReferences: Set<String> = []
    ) throws -> Bool {
        try schemas.allSatisfy { try isObjectishSchemaAndSupported($0, seenReferences: seenReferences) }
    }

    /// Returns a Boolean value that indicates whether the provided schema
    /// is an reference, object, or allOf (object-ish) schema and is supported.
    /// - Parameter:
    ///   - schemas: Schemas to check.
    ///   - seenReferences: A set of seen references, used to detect cycles.
    /// - Returns: `true` if the schema matches; `false` otherwise.
    func isObjectishSchemaAndSupported(
        _ schema: JSONSchema,
        seenReferences: Set<String> = []
    ) throws -> Bool {
        switch schema.value {
        case .object, .reference:
            return try isSchemaSupported(schema, seenReferences: seenReferences)
        case .all(of: let schemas, _):
            return try areObjectishSchemasAndSupported(schemas, seenReferences: seenReferences)
        default:
            return false
        }
    }

    /// Returns a Boolean value that indicates whether the provided schemas
    /// are reference schemas that point to object-ish schemas and supported.
    /// - Parameter:
    ///   - schemas: Schemas to check.
    ///   - seenReferences: A set of seen references, used to detect cycles.
    /// - Returns: `true` if all schemas match; `false` otherwise.
    func areRefsToObjectishSchemaAndSupported(
        _ schemas: [JSONSchema],
        seenReferences: Set<String> = []
    ) throws -> Bool {
        try schemas.allSatisfy { try isRefToObjectishSchemaAndSupported($0, seenReferences: seenReferences) }
    }

    /// Returns a Boolean value that indicates whether the provided schema
    /// is a reference schema that points to an object-ish schema and is supported.
    /// - Parameter:
    ///   - schemas: Schemas to check.
    ///   - seenReferences: A set of seen references, used to detect cycles.
    /// - Returns: `true` if the schema matches; `false` otherwise.
    func isRefToObjectishSchemaAndSupported(
        _ schema: JSONSchema,
        seenReferences: Set<String> = []
    ) throws -> Bool {
        switch schema.value {
        case .reference:
            return try isObjectishSchemaAndSupported(schema, seenReferences: seenReferences)
        default:
            return false
        }
    }
}
