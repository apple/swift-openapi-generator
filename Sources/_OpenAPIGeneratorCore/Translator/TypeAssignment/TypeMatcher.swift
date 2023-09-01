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

/// A set of functions that match Swift types onto OpenAPI types.
struct TypeMatcher {

    /// A converted function from user-provided strings to strings
    /// safe to be used as a Swift identifier.
    var asSwiftSafeName: (String) -> String

    /// Returns the type name of a built-in type that matches the specified
    /// schema.
    ///
    /// - Important: Optionality from the `JSONSchema` is not applied, since
    /// this function takes `JSONSchema.Schema`, and optionality is defined
    /// at the `JSONSchema` level.
    ///
    /// # Examples
    ///
    /// Examples of schemas that can be represented directly by builtin types:
    /// - platform builtin types
    ///     - `type: string` -> `Swift.String`
    ///     - `type: string, format: date-time` -> `Foundation.Date`
    /// - OpenAPIRuntime types
    ///     - `{}` (fragment) -> `OpenAPIRuntime.OpenAPIValueContainer`
    ///     - `type: object` (with no properties) ->
    ///     `OpenAPIRuntime.OpenAPIObjectContainer`
    /// - Parameter schema: The schema to match a built-in type for.
    /// - Returns: A type usage for the schema if the schema is supported.
    /// Otherwise, returns nil.
    func tryMatchBuiltinType(for schema: JSONSchema.Schema) -> TypeUsage? {
        Self._tryMatchRecursive(
            for: schema,
            test: { schema in
                Self._tryMatchBuiltinNonRecursive(for: schema)
            },
            matchedArrayHandler: { elementType in
                elementType.asArray
            },
            genericArrayHandler: {
                TypeName.arrayContainer.asUsage
            }
        )
    }

    /// Returns the type name of a built-in type that matches the specified
    /// schema.
    ///
    /// A referenceable schema is one of:
    /// - A builtin type
    /// - A reference
    ///
    /// - Note: Optionality from the `JSONSchema` is applied.
    /// - Parameter schema: The schema to match a referenceable type for.
    /// - Returns: A type usage for the schema if the schema is supported.
    /// Otherwise, returns nil.
    func tryMatchReferenceableType(
        for schema: JSONSchema
    ) throws -> TypeUsage? {
        try Self._tryMatchRecursive(
            for: schema.value,
            test: { (schema) -> TypeUsage? in
                if let builtinType = Self._tryMatchBuiltinNonRecursive(for: schema) {
                    return builtinType
                }
                guard case let .reference(ref, _) = schema else {
                    return nil
                }
                return try TypeAssigner(asSwiftSafeName: asSwiftSafeName)
                    .typeName(for: ref).asUsage
            },
            matchedArrayHandler: { elementType in
                elementType.asArray
            },
            genericArrayHandler: {
                TypeName.arrayContainer.asUsage
            }
        )?
        .withOptional(!schema.required)
    }

    /// Returns a Boolean value that indicates whether the schema
    /// is referenceable.
    ///
    /// A referenceable schema is one of:
    /// - A builtin type
    /// - A reference
    /// - Parameter schema: The schema to match a referenceable type for.
    /// - Returns: `true` if the schema is referenceable; `false` otherwise.
    static func isReferenceable(_ schema: JSONSchema) -> Bool {
        // This logic should be kept in sync with `tryMatchReferenceableType`.
        _tryMatchRecursive(
            for: schema.value,
            test: { schema in
                if _tryMatchBuiltinNonRecursive(for: schema) != nil {
                    return true
                }
                guard case .reference = schema else {
                    return false
                }
                return true
            },
            matchedArrayHandler: { elementIsReferenceable in
                elementIsReferenceable
            },
            genericArrayHandler: {
                true
            }
        ) ?? false
    }

    /// Returns a Boolean value that indicates whether the schema
    /// is referenceable.
    ///
    /// A referenceable schema is one of:
    /// - A builtin type
    /// - A reference
    /// - Parameter schema: The schema to match a referenceable type for.
    /// - Returns: `true` if the schema is referenceable; `false` otherwise.
    static func isReferenceable(
        _ schema: UnresolvedSchema?
    ) -> Bool {
        guard let schema else {
            // fragment type is referenceable
            return true
        }
        switch schema {
        case .a:
            // is a reference
            return true
        case let .b(schema):
            return isReferenceable(schema)
        }
    }

    /// Returns a Boolean value that indicates whether the schema
    /// needs to be defined inline..
    ///
    /// An inlinable type is the inverse of a referenceable type.
    ///
    /// In other words, a type is inlinable if and only if it is not
    /// referenceable.
    /// - Parameter schema: The schema to match a referenceable type for.
    /// - Returns: `true` if the schema is inlinable; `false` otherwise.
    static func isInlinable(_ schema: JSONSchema) -> Bool {
        !isReferenceable(schema)
    }

    /// Returns a Boolean value that indicates whether the schema
    /// needs to be defined inline..
    ///
    /// An inlinable type is the inverse of a referenceable type.
    ///
    /// In other words, a type is inlinable if and only if it is not
    /// referenceable.
    /// - Parameter schema: The schema to match a referenceable type for.
    /// - Returns: `true` if the schema is inlinable; `false` otherwise.
    static func isInlinable(
        _ schema: UnresolvedSchema?
    ) -> Bool {
        !isReferenceable(schema)
    }

    // MARK: - Private

    /// Returns the type name of a built-in type that matches the specified
    /// schema.
    ///
    /// This method is a version of `tryMatchBuiltinType` that doesn't
    /// recurse into arrays.
    ///
    /// - Important: Optionality from the `JSONSchema` is not applied, since
    /// this function takes `JSONSchema.Schema`, and optionality is defined
    /// at the `JSONSchema` level.
    /// - Parameter schema: The schema to match a referenceable type for.
    /// - Returns: A type usage for the schema if the schema is built-in.
    /// Otherwise, returns nil.
    private static func _tryMatchBuiltinNonRecursive(
        for schema: JSONSchema.Schema
    ) -> TypeUsage? {
        let typeName: TypeName
        switch schema {
        case .boolean(_):
            typeName = .swift("Bool")
        case .number(let core, _):
            switch core.format {
            case .float:
                typeName = .swift("Float")
            default:
                typeName = .swift("Double")
            }
        case .integer(let core, _):
            if core.allowedValues != nil {
                // custom enum isn't a builtin
                return nil
            }
            switch core.format {
            case .int32:
                typeName = .swift("Int32")
            case .int64:
                typeName = .swift("Int64")
            default:
                typeName = .swift("Int")
            }
        case .string(let core, _):
            if core.allowedValues != nil {
                // custom enum isn't a builtin
                return nil
            }
            switch core.format {
            case .byte:
                typeName = .swift("String")
            case .binary:
                typeName = .foundation("Data")
            case .dateTime:
                typeName = .foundation("Date")
            default:
                typeName = .swift("String")
            }
        case .fragment:
            typeName = .valueContainer
        case let .object(_, objectContext):
            guard objectContext.properties.isEmpty && objectContext.additionalProperties == nil else {
                // object with properties is not a builtin
                return nil
            }
            // freeform object is a builtin
            typeName = .runtime("OpenAPIObjectContainer")
        case .array:
            // arrays are already recursed-into by _tryMatchTypeRecursive
            // so just return nil here
            return nil
        case .reference, .not, .all, .any, .one, .null:
            // never built-in
            return nil
        }
        return typeName.asUsage
    }

    /// Walks the specified schema and calls the test closure on each type,
    /// except arrays. Recurses into arrays.
    /// - Parameters:
    ///   - schema: The root schema to start the walk at.
    ///   - test: A closure that returns the result for a provided schema.
    ///   - matchedArrayHandler: A closure that the function calls when it
    ///   encounters an array that has an element schema. The closure is
    ///   invoked with the result of calling the test closure on the element
    ///   schema.
    ///   - genericArrayHandler: A closure that the function calls when it
    ///   encounters an array without an element schema.
    /// - Returns: The result of calling the test closure on the specified
    /// schema. Returns nil if the test closure returns nil at any point
    /// of the recursive call.
    private static func _tryMatchRecursive<R>(
        for schema: JSONSchema.Schema,
        test: (JSONSchema.Schema) throws -> R?,
        matchedArrayHandler: (R) -> R,
        genericArrayHandler: () -> R
    ) rethrows -> R? {
        switch schema {
        case let .array(_, arrayContext):
            guard let items = arrayContext.items else {
                return genericArrayHandler()
            }
            guard
                let itemsResult = try _tryMatchRecursive(
                    for: items.value,
                    test: test,
                    matchedArrayHandler: matchedArrayHandler,
                    genericArrayHandler: genericArrayHandler
                )
            else {
                return nil
            }
            return matchedArrayHandler(itemsResult)
        default:
            return try test(schema)
        }
    }
}
