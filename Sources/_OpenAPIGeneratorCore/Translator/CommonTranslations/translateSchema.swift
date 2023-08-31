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

extension FileTranslator {

    /// Returns a list of declarations for the specified schema.
    ///
    /// Might return more than one declaration, for example when a typealias
    /// refers to an unnamed type, and a new type needs to be defined inline.
    ///
    /// Might also return no declarations, for example when encountering an
    /// unsupported schema. When that happens, a diagnostic is also emitted
    /// into the collector.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared type.
    ///   - schema: The JSON schema representing the type.
    ///   - overrides: A structure with the properties that should be overridden
    ///   instead of extracted from the schema.
    func translateSchema(
        typeName: TypeName,
        schema: UnresolvedSchema?,
        overrides: SchemaOverrides
    ) throws -> [Declaration] {
        let unwrappedSchema: JSONSchema
        if let schema {
            switch schema {
            case let .a(ref):
                // reference, wrap that into JSONSchema
                unwrappedSchema = .reference(ref.jsonReference)
            case let .b(schema):
                unwrappedSchema = schema
            }
        } else {
            // fragment
            unwrappedSchema = .fragment
        }
        return try translateSchema(
            typeName: typeName,
            schema: unwrappedSchema,
            overrides: overrides
        )
    }

    /// Returns a list of declarations for the specified schema.
    ///
    /// Might return more than one declaration, for example when a typealias
    /// refers to an unnamed type, and a new type needs to be defined inline.
    ///
    /// Might also return no declarations, for example when encountering an
    /// unsupported schema. When that happens, a diagnostic is also emitted
    /// into the collector.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared type.
    ///   - schema: The JSON schema representing the type.
    ///   - overrides: A structure with the properties that should be overridden
    ///   instead of extracted from the schema.
    func translateSchema(
        typeName: TypeName,
        schema: JSONSchema,
        overrides: SchemaOverrides
    ) throws -> [Declaration] {

        let value = schema.value

        // Attach any warnings from the parsed schema as a diagnostic.
        for warning in schema.warnings {
            diagnostics.emit(
                .warning(
                    message: "Schema warning: \(warning.description)",
                    context: [
                        "codingPath": warning.codingPathString ?? "<none>",
                        "contextString": warning.contextString ?? "<none>",
                        "subjectName": warning.subjectName ?? "<none>",
                    ]
                )
            )
        }

        // If this type maps to a referenceable schema, define a typealias
        if let builtinType = try typeMatcher.tryMatchReferenceableType(for: schema) {
            let typealiasDecl = try translateTypealias(
                named: typeName,
                userDescription: overrides.userDescription ?? schema.description,
                to: builtinType.withOptional(overrides.isOptional ?? !schema.required)
            )
            return [typealiasDecl]
        }

        // Not a global schema, we have to actually define a type for it
        switch value {
        case let .object(coreContext, objectContext):
            let objectDecl = try translateObjectStruct(
                typeName: typeName,
                openAPIDescription: overrides.userDescription ?? coreContext.description,
                objectContext: objectContext,
                isDeprecated: coreContext.deprecated
            )
            return [objectDecl]
        case let .string(coreContext, _):
            guard let allowedValues = coreContext.allowedValues else {
                throw GenericError(message: "Unexpected non-global string for \(typeName)")
            }
            let enumDecl = try translateStringEnum(
                typeName: typeName,
                userDescription: overrides.userDescription ?? coreContext.description,
                isNullable: coreContext.nullable,
                allowedValues: allowedValues
            )
            return [enumDecl]
        case let .array(coreContext, arrayContext):
            return try translateArray(
                typeName: typeName,
                openAPIDescription: overrides.userDescription ?? coreContext.description,
                arrayContext: arrayContext
            )
        case let .all(of: schemas, core: coreContext):
            let allOfDecl = try translateAllOrAnyOf(
                typeName: typeName,
                openAPIDescription: overrides.userDescription ?? coreContext.description,
                type: .allOf,
                schemas: schemas
            )
            return [allOfDecl]
        case let .any(of: schemas, core: coreContext):
            let anyOfDecl = try translateAllOrAnyOf(
                typeName: typeName,
                openAPIDescription: overrides.userDescription ?? coreContext.description,
                type: .anyOf,
                schemas: schemas
            )
            return [anyOfDecl]
        case let .one(of: schemas, core: coreContext):
            let oneOfDecl = try translateOneOf(
                typeName: typeName,
                openAPIDescription: overrides.userDescription ?? coreContext.description,
                discriminator: coreContext.discriminator,
                schemas: schemas
            )
            return [oneOfDecl]
        default:
            return []
        }
    }
}
