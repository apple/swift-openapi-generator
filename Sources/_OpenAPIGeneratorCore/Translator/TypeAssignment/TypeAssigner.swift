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

    /// A set of configuration values that inform translation.
    var context: TranslatorContext

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
    /// - Returns: A Swift type name for the specified component type.
    func typeName(forComponentOriginallyNamed originalName: String, in location: TypeLocation) -> TypeName {
        typeName(forLocation: location)
            .appending(swiftComponent: context.asSwiftSafeName(originalName), jsonComponent: originalName)
    }

    /// Returns the type name for an OpenAPI-named component namespace.
    /// - Parameter location: The location of the type in the OpenAPI document.
    /// - Returns: A Swift type name representing the specified component namespace.
    func typeName(forLocation location: TypeLocation) -> TypeName {
        switch location {
        case .schemas: return typeName(for: JSONSchema.self)
        case .parameters: return typeName(for: OpenAPI.Parameter.self)
        }
    }

    /// Returns a type usage for an unresolved schema.
    /// - Parameters:
    ///   - hint: A hint string used when computing a name for an inline type.
    ///   - schema: The OpenAPI schema.
    ///   - components: The components in which to look up references.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage; or nil if the schema is nil or unsupported.
    /// - Throws: An error if there's an issue while computing the type usage, such as when resolving a type name or checking compatibility.
    func typeUsage(
        usingNamingHint hint: String,
        withSchema schema: UnresolvedSchema?,
        components: OpenAPI.Components,
        inParent parent: TypeName
    ) throws -> TypeUsage? {
        let associatedType: TypeUsage?
        if let schema {
            switch schema {
            case let .a(reference): associatedType = try typeName(for: reference).asUsage
            case let .b(schema):
                associatedType = try _typeUsage(
                    forPotentiallyInlinedValueNamed: hint,
                    withSchema: schema,
                    components: components,
                    inParent: parent,
                    subtype: .appendScope
                )
            }
        } else {
            associatedType = nil
        }
        return associatedType
    }

    /// Returns a type usage for an unresolved multipart schema.
    /// - Parameters:
    ///   - hint: A hint string used when computing a name for an inline type.
    ///   - schema: The OpenAPI schema.
    ///   - encoding: The encoding mapping refining the schema.
    ///   - components: The components in which to look up references.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage.
    /// - Throws: An error if there's an issue while computing the type usage, such as when resolving a type name or checking compatibility.
    func typeUsage(
        usingNamingHint hint: String,
        withMultipartSchema schema: UnresolvedSchema?,
        encoding: OrderedDictionary<String, OpenAPI.Content.Encoding>?,
        components: OpenAPI.Components,
        inParent parent: TypeName
    ) throws -> TypeUsage {
        let multipartBodyElementTypeName: TypeName
        if let ref = TypeMatcher(context: context)
            .multipartElementTypeReferenceIfReferenceable(schema: schema, encoding: encoding)
        {
            multipartBodyElementTypeName = try typeName(for: ref)
        } else {
            let swiftSafeName = context.asSwiftSafeName(hint)
            multipartBodyElementTypeName = parent.appending(
                swiftComponent: swiftSafeName + Constants.Global.inlineTypeSuffix,
                jsonComponent: hint
            )
        }
        let bodyUsage = multipartBodyElementTypeName.asUsage.asWrapped(in: .multipartBody)
        return bodyUsage
    }

    /// Returns a type usage for an unresolved schema.
    /// - Parameters:
    ///   - content: The OpenAPI content.
    ///   - components: The components in which to look up references.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage; or nil if the schema is nil or unsupported.
    /// - Throws: An error if there's an issue while computing the type usage, such as when resolving a type name or checking compatibility.
    func typeUsage(withContent content: SchemaContent, components: OpenAPI.Components, inParent parent: TypeName) throws
        -> TypeUsage?
    {
        let identifier = contentSwiftName(content.contentType)
        if content.contentType.isMultipart {
            return try typeUsage(
                usingNamingHint: identifier,
                withMultipartSchema: content.schema,
                encoding: content.encoding,
                components: components,
                inParent: parent
            )
        } else {
            return try typeUsage(
                usingNamingHint: identifier,
                withSchema: content.schema,
                components: components,
                inParent: parent
            )
        }
    }

    /// Returns a type usage for a property.
    /// - Parameters:
    ///   - originalName: The name of the property in the OpenAPI document.
    ///   - schema: The OpenAPI schema provided for the property.
    ///   - components: The components in which to look up references.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage.
    /// - Throws: An error if there's an issue while processing the schema or generating the type usage.
    func typeUsage(
        forObjectPropertyNamed originalName: String,
        withSchema schema: JSONSchema,
        components: OpenAPI.Components,
        inParent parent: TypeName
    ) throws -> TypeUsage {
        try _typeUsage(
            forPotentiallyInlinedValueNamed: originalName,
            withSchema: schema,
            components: components,
            inParent: parent,
            subtype: .appendScope
        )
    }

    /// Returns a type usage for a child schema of an allOf/anyOf/oneOf.
    /// - Parameters:
    ///   - originalName: A hint for naming.
    ///   - schema: The OpenAPI schema provided for the property.
    ///   - components: The components in which to look up references.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage.
    /// - Throws: An error if there's an issue while processing the schema or generating the type usage.
    func typeUsage(
        forAllOrAnyOrOneOfChildSchemaNamed originalName: String,
        withSchema schema: JSONSchema,
        components: OpenAPI.Components,
        inParent parent: TypeName
    ) throws -> TypeUsage {
        try _typeUsage(
            forPotentiallyInlinedValueNamed: originalName.uppercasingFirstLetter,
            jsonReferenceComponentOverride: originalName,
            withSchema: schema,
            components: components,
            inParent: parent,
            subtype: .appendScope
        )
    }

    /// Returns a type usage for an element schema of an array.
    /// - Parameters:
    ///   - schema: The OpenAPI schema provided for the array element type.
    ///   - components: The components in which to look up references.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage.
    /// - Throws: An error if there's an issue while processing the schema or generating the type usage.
    func typeUsage(
        forArrayElementWithSchema schema: JSONSchema,
        components: OpenAPI.Components,
        inParent parent: TypeName
    ) throws -> TypeUsage {
        try _typeUsage(
            forPotentiallyInlinedValueNamed: parent.shortSwiftName,
            withSchema: schema,
            components: components,
            inParent: parent,
            subtype: .appendToLastPathComponent
        )
    }

    /// Returns a type usage for a parameter.
    /// - Parameters:
    ///   - originalName: The name of the parameter in the OpenAPI document.
    ///   - schema: The OpenAPI schema provided for the parameter.
    ///   - components: The components in which to look up references.
    ///   - parent: The parent type in which to name the type.
    /// - Returns: A type usage.
    /// - Throws: An error if there's an issue while processing the schema or generating the type usage.
    func typeUsage(
        forParameterNamed originalName: String,
        withSchema schema: JSONSchema,
        components: OpenAPI.Components,
        inParent parent: TypeName
    ) throws -> TypeUsage {
        try _typeUsage(
            forPotentiallyInlinedValueNamed: originalName,
            withSchema: schema,
            components: components,
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
    ///   - components: The components from the OpenAPI document.
    ///   - parent: The name of the parent type in which to name the type.
    ///   - subtype: The naming method used by the type assigner.
    /// - Returns: A type usage.
    /// - Throws: An error if there's an issue while processing the schema or generating the type usage.
    private func _typeUsage(
        forPotentiallyInlinedValueNamed originalName: String,
        jsonReferenceComponentOverride: String? = nil,
        suffix: String = Constants.Global.inlineTypeSuffix,
        withSchema schema: JSONSchema,
        components: OpenAPI.Components,
        inParent parent: TypeName,
        subtype: SubtypeNamingMethod
    ) throws -> TypeUsage {
        let typeMatcher = TypeMatcher(context: context)
        // Check if this type can be simply referenced without
        // creating a new inline type.
        if let referenceableType = try typeMatcher.tryMatchReferenceableType(for: schema, components: components) {
            return referenceableType
        }
        // Otherwise it's an inline, non-referenceable type
        let baseType: TypeName
        switch subtype {
        case .appendScope: baseType = parent
        case .appendToLastPathComponent: baseType = parent.parent
        }
        return
            baseType.appending(
                swiftComponent: context.asSwiftSafeName(originalName) + suffix,
                jsonComponent: jsonReferenceComponentOverride ?? originalName
            )
            .asUsage.withOptional(try typeMatcher.isOptional(schema, components: components))
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
    /// - Returns: A type name for a reusable component.
    func typeName<Component: ComponentDictionaryLocatable>(
        for component: OpenAPI.ComponentDictionary<Component>.Element
    ) -> TypeName { typeName(for: component.key, of: Component.self) }

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
    /// - Returns: A type name for a reusable component key.
    func typeName<Component: ComponentDictionaryLocatable>(
        for key: OpenAPI.ComponentKey,
        of componentType: Component.Type
    ) -> TypeName {
        typeName(for: Component.self)
            .appending(swiftComponent: context.asSwiftSafeName(key.rawValue), jsonComponent: key.rawValue)
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
    /// - Returns: A type name for a JSON reference.
    /// - Throws: An error if the provided reference is an external reference or if there's an issue while computing the type name.
    func typeName<Component: ComponentDictionaryLocatable>(
        for reference: JSONReference<Component>,
        in componentType: Component.Type = Component.self
    ) throws -> TypeName {
        guard case let .internal(internalReference) = reference else {
            throw JSONReferenceParsingError.externalPathsUnsupported(reference.absoluteString)
        }
        return try typeName(for: internalReference, in: componentType)
    }

    /// Returns a type name for an OpenAPI reference.
    ///
    /// Behaves similarly to JSONReference.
    ///
    /// - NOTE: Only internal references are currently supported; throws an error for external references.
    /// - Parameters:
    ///   - reference: The reference to compute a type name for.
    ///   - componentType: The type of the component to which the reference
    ///   points.
    /// - Throws: An error if there's an issue while computing the type name, or if the reference is external.
    /// - Returns: A TypeName representing the computed type name for the reference.
    func typeName<Component: ComponentDictionaryLocatable>(
        for reference: OpenAPI.Reference<Component>,
        in componentType: Component.Type = Component.self
    ) throws -> TypeName { try typeName(for: reference.jsonReference, in: componentType) }

    /// Returns a type name for an internal reference to a component.
    ///
    /// - NOTE: Only component references are supported; throws an error for paths outside of the Components object.
    /// - Parameters:
    ///   - reference: The internal reference to compute a type name for.
    ///   - componentType: The type of the component to which the reference
    ///   points.
    /// - Returns: A type name for an internal reference to a component.
    /// - Throws: An error if the provided reference is not a component reference or if there's an issue while computing the type name.
    func typeName<Component: ComponentDictionaryLocatable>(
        for reference: JSONReference<Component>.InternalReference,
        in componentType: Component.Type = Component.self
    ) throws -> TypeName {
        guard case let .component(name) = reference else {
            throw JSONReferenceParsingError.nonComponentPathsUnsupported(reference.name)
        }
        return typeName(for: componentType)
            .appending(swiftComponent: context.asSwiftSafeName(name), jsonComponent: name)
    }

    /// Returns a type name for the namespace for the specified component type.
    ///
    /// # Mapping
    /// - `#/components/schemas` -> `JSONSchema`
    /// - `#/components/responses` -> `OpenAPI.Response`
    /// - `#/components/callbacks` -> `OpenAPI.Callbacks`
    /// - `#/components/parameters` -> `OpenAPI.Parameter`
    /// (includes request headers)
    /// - `#/components/examples` -> `OpenAPI.Example`
    /// - `#/components/requestBodies` -> `OpenAPI.Request`
    /// - `#/components/headers` -> `OpenAPI.Header` (response headers)
    /// - `#/components/securitySchemes` -> `OpenAPI.SecurityScheme`
    /// - `#/components/links` -> `OpenAPI.Link`
    ///
    /// - Parameter componentType: The type of the component.
    /// - Returns: A type name for the namespace for the specified component type.
    func typeName<Component: ComponentDictionaryLocatable>(for componentType: Component.Type = Component.self)
        -> TypeName
    {
        typeNameForComponents()
            .appending(
                swiftComponent: context.asSwiftSafeName(componentType.openAPIComponentsKey).uppercasingFirstLetter,
                jsonComponent: componentType.openAPIComponentsKey
            )
    }

    /// Returns the root namespace for all OpenAPI components.
    /// - Returns: The root namespace for all OpenAPI components.
    func typeNameForComponents() -> TypeName {
        TypeName(components: [.root, .init(swift: Constants.Components.namespace, json: "components")])
    }

    /// Returns a Swift-safe identifier used as the name of the content
    /// enum case.
    ///
    /// - Parameter contentType: The content type for which to compute the name.
    /// - Returns: A Swift-safe identifier representing the name of the content enum case.
    func contentSwiftName(_ contentType: ContentType) -> String {
        let rawContentType = contentType.lowercasedTypeSubtypeAndParameters
        switch rawContentType {
        case "application/json": return "json"
        case "application/x-www-form-urlencoded": return "urlEncodedForm"
        case "multipart/form-data": return "multipartForm"
        case "text/plain": return "plainText"
        case "*/*": return "any"
        case "application/xml": return "xml"
        case "application/octet-stream": return "binary"
        case "text/html": return "html"
        case "application/yaml": return "yaml"
        case "text/csv": return "csv"
        case "image/png": return "png"
        case "application/pdf": return "pdf"
        case "image/jpeg": return "jpeg"
        default:
            let safedType = context.asSwiftSafeName(contentType.originallyCasedType)
            let safedSubtype = context.asSwiftSafeName(contentType.originallyCasedSubtype)
            let prefix = "\(safedType)_\(safedSubtype)"
            let params = contentType.lowercasedParameterPairs
            guard !params.isEmpty else { return prefix }
            let safedParams =
                params.map { pair in
                    pair.split(separator: "=").map { context.asSwiftSafeName(String($0)) }.joined(separator: "_")
                }
                .joined(separator: "_")
            return prefix + "_" + safedParams
        }
    }

}

extension FileTranslator {

    /// A configured type assigner.
    var typeAssigner: TypeAssigner { TypeAssigner(context: context) }

    /// A configured type matcher.
    var typeMatcher: TypeMatcher { TypeMatcher(context: context) }
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

extension JSONReferenceParsingError: LocalizedError { var errorDescription: String? { description } }
