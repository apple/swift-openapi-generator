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
import Foundation

/// A set of functions that compute the deterministic, unique, and global
/// type name for the provided type parameters.
///
/// Assigns a type name to a given schema, reference, parameter – given context.
///
/// # Internals
///
/// Only contains logic related to calculating the global name for a
/// type (including nested, unnamed types).
///
/// Does not perform deep schema inspection.
///
/// Type assigner does not follow references, it just computes
/// a type name for the reference itself.
///
/// To keep the Translator logic manageable, we minimize the number of code
/// locations where we make specialized decisions based on whether a schema
/// is a primitive type vs a composite type vs a reference vs an inline type.
///
/// Centralize that logic in the type assigner, and vend very specific APIs
/// that provide the answer instead.
///
/// That means that the callers of the type assigner should always pass in
/// all the context information they have about the schema, even in
/// cases when it's a simple string schema.
struct TypeAssigner {

    /// Returns a type name for an OpenAPI-named component type.
    ///
    /// A component type is any type in `#/components` in the OpenAPI document.
    ///
    /// Examples:
    ///
    /// `originalName: "Foo"` + `location: .schemas` = `Components.Schemas.Foo`
    ///
    /// - Parameters:
    ///   - originalName: The original type name (component key) from
    ///   the OpenAPI document.
    ///   - location: The location of the type in the OpenAPI document.
    static func typeName(
        forComponentOriginallyNamed originalName: String,
        in location: TypeLocation
    ) -> TypeName {
        location
            .namespace
            .appending(
                swiftComponent: originalName.asSwiftSafeName,
                jsonComponent: originalName
            )
    }

    /// Returns a type usage for an unresolved schema.
    /// - Parameters:
    ///   - hint: A hint string used when computing a name for an inline type.
    ///   - schema: The OpenAPI schema.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage; or nil if the schema is nil or unsupported.
    static func typeUsage(
        usingNamingHint hint: String,
        withSchema schema: Either<JSONReference<JSONSchema>, JSONSchema>?,
        inParent parent: TypeName
    ) throws -> TypeUsage? {
        let associatedType: TypeUsage?
        if let schema {
            switch schema {
            case let .a(reference):
                associatedType = try TypeAssigner.typeName(for: reference).asUsage
            case let .b(schema):
                associatedType = try TypeAssigner._typeUsage(
                    forPotentiallyInlinedValueNamed: hint,
                    withSchema: schema,
                    inParent: parent,
                    subtype: .appendScope
                )
            }
        } else {
            associatedType = nil
        }
        return associatedType
    }

    /// Returns a type usage for a property.
    /// - Parameters:
    ///   - originalName: The name of the property in the OpenAPI document.
    ///   - schema: The OpenAPI schema provided for the property.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage.
    static func typeUsage(
        forObjectPropertyNamed originalName: String,
        withSchema schema: JSONSchema,
        inParent parent: TypeName
    ) throws -> TypeUsage {
        try _typeUsage(
            forPotentiallyInlinedValueNamed: originalName,
            withSchema: schema,
            inParent: parent,
            subtype: .appendScope
        )
    }

    /// Returns a type usage for a child schema of an allOf/anyOf/oneOf.
    /// - Parameters:
    ///   - originalName: A hint for naming.
    ///   - schema: The OpenAPI schema provided for the property.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage.
    static func typeUsage(
        forAllOrAnyOrOneOfChildSchemaNamed originalName: String,
        withSchema schema: JSONSchema,
        inParent parent: TypeName
    ) throws -> TypeUsage {
        try _typeUsage(
            forPotentiallyInlinedValueNamed: originalName.uppercasingFirstLetter,
            jsonReferenceComponentOverride: originalName,
            withSchema: schema,
            inParent: parent,
            subtype: .appendScope
        )
    }

    /// Returns a type usage for an element schema of an array.
    /// - Parameters:
    ///   - schema: The OpenAPI schema provided for the array element type.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage.
    static func typeUsage(
        forArrayElementWithSchema schema: JSONSchema,
        inParent parent: TypeName
    ) throws -> TypeUsage {
        try _typeUsage(
            forPotentiallyInlinedValueNamed: parent.shortSwiftName,
            withSchema: schema,
            inParent: parent,
            subtype: .appendToLastPathComponent
        )
    }

    /// Returns a type usage for a parameter.
    /// - Parameters:
    ///   - originalName: The name of the parameter in the OpenAPI document.
    ///   - schema: The OpenAPI schema provided for the parameter.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage.
    static func typeUsage(
        forParameterNamed originalName: String,
        withSchema schema: JSONSchema,
        inParent parent: TypeName
    ) throws -> TypeUsage {
        try _typeUsage(
            forPotentiallyInlinedValueNamed: originalName,
            withSchema: schema,
            inParent: parent,
            subtype: .appendScope
        )
    }

    /// A method of naming child types.
    ///
    /// Some parent types define a new scope (for example, a struct), some
    /// do not (for example, a typealias).
    private enum SubtypeNamingMethod {

        /// A type that adds a new scope.
        ///
        /// For example: "Foo" -> "Foo.Bar"
        ///
        /// Used when the parent type creates a scope, for example a struct.
        case appendScope

        /// A type that adds a suffix to the existing last path component.
        ///
        /// For example: "Foo" -> "FooBar"
        ///
        /// Used when the parent type does not create a scope, for example
        /// a typealias.
        case appendToLastPathComponent
    }

    /// Returns a type usage for a schema of an inlined value.
    ///
    /// Examples:
    ///
    /// ```yaml
    /// components:
    ///   schemas:
    ///     Foo:
    ///       type: object
    ///       properties:
    ///         bar:
    ///           type: string
    /// ```
    /// \+ `originalName: "bar"` + `parent: Components.Schemas.Foo`
    /// = `Swift.String` (builtin type is used if one is matched, in unnamed contexts)
    ///
    /// ```yaml
    /// components:
    ///   schemas:
    ///     Foo:
    ///       type: object
    ///       properties:
    ///         bar:
    ///           type: object
    ///           properties:
    ///             <...>
    /// ```
    /// \+ `originalName: "bar"` + `parent: Components.Schemas.Foo`
    /// = `Components.Schemas.Foo.barPayload` (a new name is synthesized for inline types)
    ///
    /// - Parameters:
    ///   - originalName: The name specified in the OpenAPI document.
    ///   - jsonReferenceComponentOverride: A custom value for the JSON
    ///   reference component.
    ///   - suffix: The string to append to the name for inline types.
    ///   - schema: The schema describing the content of the type.
    ///   - parent: The name of the parent type in which to name the type.
    ///   - subtype: The naming method used by the type assigner.
    /// - Returns: A type usage.
    private static func _typeUsage(
        forPotentiallyInlinedValueNamed originalName: String,
        jsonReferenceComponentOverride: String? = nil,
        suffix: String = Constants.Global.inlineTypeSuffix,
        withSchema schema: JSONSchema,
        inParent parent: TypeName,
        subtype: SubtypeNamingMethod
    ) throws -> TypeUsage {
        // Check if this type can be simply referenced without
        // creating a new inline type.
        if let referenceableType =
            try TypeMatcher
            .tryMatchReferenceableType(for: schema)
        {
            return referenceableType
        }
        // Otherwise it's an inline, non-referenceable type
        let baseType: TypeName
        switch subtype {
        case .appendScope:
            baseType = parent
        case .appendToLastPathComponent:
            baseType = parent.parent
        }
        return
            baseType.appending(
                swiftComponent: originalName.asSwiftSafeName + suffix,
                jsonComponent: jsonReferenceComponentOverride ?? originalName
            )
            .asUsage
            .withOptional(!schema.required)
    }

    /// Returns a type name for a reusable component.
    ///
    /// Returns the sanitized and formatted fully-qualified type name for
    /// an element in the OpenAPI components object.
    ///
    /// Given the following YAML:
    ///
    ///     components:
    ///       schemas:
    ///         my_reusable_object:
    ///           type: object
    ///           description: "My reusable object"
    ///
    /// The type names can be deterministically mapped as follows:
    ///
    ///     for keyedSchema in components.schemas {
    ///         print(TypeAssigner.typeName(for: keyedSchema))
    ///     }
    ///     // prints "Components.Schemas.my_reusable_object"
    ///
    /// - NOTE: Only internal references are currently supported; throws an error for external references.
    /// - Parameter component: The component for which to compute a name.
    static func typeName<Component: ComponentDictionaryLocatable>(
        for component: OpenAPI.ComponentDictionary<Component>.Element
    ) -> TypeName {
        typeName(for: component.key, of: Component.self)
    }

    /// Returns a type name for a reusable component key.
    ///
    /// Returns the sanitized and formatted fully-qualified type name for
    /// an element in the OpenAPI Components object.
    ///
    /// Given the following YAML:
    ///
    ///     components:
    ///       schemas:
    ///         my_reusable_object:
    ///           type: object
    ///           description: "My reusable object"
    ///
    /// The type names can be deterministically mapped as follows:
    ///
    ///     for keyedSchema in components.schemas {
    ///         print(TypeAssigner.typeName(for: keyedSchema))
    ///     }
    ///     // prints "Components.Schemas.my_reusable_object"
    ///
    /// - NOTE: Only internal references are currently supported; throws an error for external references.
    /// - Parameters:
    ///   - key: The key for the component in the OpenAPI document.
    ///   - componentType: The type of the component.
    static func typeName<Component: ComponentDictionaryLocatable>(
        for key: OpenAPI.ComponentKey,
        of componentType: Component.Type
    ) -> TypeName {
        typeName(for: Component.self)
            .appending(
                swiftComponent: key.shortSwiftName,
                jsonComponent: key.rawValue
            )
    }

    /// Returns a type name for a JSON reference.
    ///
    /// Example:
    ///
    ///     let ref = JSONReference<JSONSchema>.component(named: "greetings")
    ///
    ///     ref.absoluteString
    ///     // "#/components/schemas/greetings"
    ///
    ///     ref.fullyQualifiedSwiftTypeName
    ///     // "Components.Schemas.greetings"
    ///
    /// - NOTE: Only internal references are currently supported; throws an error for external references.
    /// - Parameters:
    ///   - reference: The reference to compute a type name for.
    ///   - componentType: The type of the component to which the reference
    ///   points.
    static func typeName<Component: ComponentDictionaryLocatable>(
        for reference: JSONReference<Component>,
        in componentType: Component.Type = Component.self
    ) throws -> TypeName {
        guard case let .internal(internalReference) = reference else {
            throw JSONReferenceParsingError.externalPathsUnsupported(reference.absoluteString)
        }
        return try typeName(for: internalReference, in: componentType)
    }

    /// Returns a type name for an internal reference to a component.
    ///
    /// - NOTE: Only component references are supported; throws an error for paths outside of the Components object.
    /// - Parameters:
    ///   - reference: The internal reference to compute a type name for.
    ///   - componentType: The type of the component to which the reference
    ///   points.
    static func typeName<Component: ComponentDictionaryLocatable>(
        for reference: JSONReference<Component>.InternalReference,
        in componentType: Component.Type = Component.self
    ) throws -> TypeName {
        guard case let .component(name) = reference else {
            throw
                JSONReferenceParsingError
                .nonComponentPathsUnsupported(reference.name)
        }
        return typeName(for: componentType)
            .appending(
                swiftComponent: name.asSwiftSafeName,
                jsonComponent: name
            )
    }

    /// Returns a type name for the namespace for the specified component type.
    ///
    /// # Mapping
    /// - `#/components/schemas` -> `JSONSchema`
    /// - `#/components/responses` -> `OpenAPI.Response`
    /// - `#/components/callbacks` -> `OpenAPI.Callbacks`
    /// - `#/components/parameters` -> `ResolvedParameter`
    /// (includes request headers)
    /// - `#/components/examples` -> `OpenAPI.Example`
    /// - `#/components/requestBodies` -> `ResolvedRequestBody`
    /// - `#/components/headers` -> `OpenAPI.Header` (response headers)
    /// - `#/components/securitySchemes` -> `OpenAPI.SecurityScheme`
    /// - `#/components/links` -> `OpenAPI.Link`
    ///
    /// - Parameter componentType: The type of the component.
    static func typeName<Component: ComponentDictionaryLocatable>(
        for componentType: Component.Type = Component.self
    ) -> TypeName {
        typeNameForComponents()
            .appending(
                swiftComponent: componentType
                    .openAPIComponentsKey
                    .asSwiftSafeName
                    .uppercasingFirstLetter,
                jsonComponent: componentType.openAPIComponentsKey
            )
    }

    /// Returns the root namespace for all OpenAPI components.
    static func typeNameForComponents() -> TypeName {
        TypeName(components: [
            .root,
            .init(swift: Constants.Components.namespace, json: "components"),
        ])
    }
}

/// An error used during the parsing of JSON references specified in an
/// OpenAPI document.
enum JSONReferenceParsingError: Swift.Error {

    /// An error thrown when parsing a JSON reference that points outside
    /// of the components object in the OpenAPI document.
    case nonComponentPathsUnsupported(String?)

    /// An error thrown when parsing a JSON reference that points to
    /// other OpenAPI documents.
    case externalPathsUnsupported(String)
}

extension JSONReferenceParsingError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .nonComponentPathsUnsupported(string):
            return "JSON references outside of #/components are not supported, found: \(string ?? "<nil>")"
        case let .externalPathsUnsupported(string):
            return "External JSON references are not supported, found: \(string)"
        }
    }
}

extension JSONReferenceParsingError: LocalizedError {
    var errorDescription: String? {
        description
    }
}

extension OpenAPI.ComponentKey {
    /// A deterministic short Swift name for the component key.
    var shortSwiftName: String {
        rawValue
            .asSwiftSafeName
    }
}

fileprivate extension TypeLocation {

    /// A namespace for the current type location.
    var namespace: TypeName {
        switch self {
        case .schemas:
            return TypeAssigner.typeName(for: JSONSchema.self)
        case .parameters:
            return TypeAssigner.typeName(for: ResolvedParameter.self)
        }
    }
}
