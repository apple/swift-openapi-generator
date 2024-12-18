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

/// A container for an OpenAPI parameter and its computed Swift type usage.
struct TypedParameter {

    /// The OpenAPI parameter.
    var parameter: OpenAPI.Parameter

    /// The underlying schema.
    var schema: UnresolvedSchema

    /// The parameter serialization style.
    var style: OpenAPI.Parameter.SchemaContext.Style

    /// The parameter explode value.
    var explode: Bool

    /// The computed type usage.
    var typeUsage: TypeUsage

    /// The coding strategy appropriate for this parameter.
    var codingStrategy: CodingStrategy

    /// A set of configuration values that inform translation.
    var context: TranslatorContext
}

extension TypedParameter: CustomStringConvertible {
    var description: String { typeUsage.description + "/param:\(name)" }
}

extension TypedParameter {

    /// The name of the parameter exactly as specified in the OpenAPI document.
    var name: String { parameter.name }

    /// The name of the parameter sanitized to be a valid Swift identifier.
    var variableName: String { context.safeNameGenerator.swiftMemberName(for: name) }

    /// A Boolean value that indicates whether the parameter must be specified
    /// when performing the OpenAPI operation.
    var required: Bool { parameter.required }

    /// The location of the parameter in the HTTP request.
    var location: OpenAPI.Parameter.Context.Location { parameter.location }

    /// A schema to be inlined.
    ///
    /// - Returns: Nil when schema is referenceable.
    var inlineableSchema: JSONSchema? {
        switch schema {
        case .a: return nil
        case let .b(schema):
            if TypeMatcher(context: context).isInlinable(schema) { return schema }
            return nil
        }
    }
}

extension FileTranslator {

    /// Returns a list of supported parameters from the specified operation.
    ///
    /// Omits unsupported parameters, which emit a diagnostic to the collector
    /// with more information.
    /// - Parameter operation: The operation to extract parameters from.
    /// - Returns: A list of `TypedParameter` instances representing the supported parameters of the operation.
    /// - Throws: An error if there is an issue parsing and typing the parameters.
    func typedParameters(from operation: OperationDescription) throws -> [TypedParameter] {
        let inputTypeName = operation.inputTypeName
        return try operation.allParameters.compactMap { parameter in
            try parseAsTypedParameter(from: parameter, inParent: inputTypeName)
        }
    }

    /// Returns a typed parameter if the specified unresolved parameter is supported.
    /// - Parameters:
    ///   - unresolvedParameter: An unresolved parameter.
    ///   - parent: The parent type of the parameter.
    /// - Returns: A typed parameter. Nil if the parameter is unsupported.
    /// - Throws: An error if there is an issue parsing and typing the parameter.
    func parseAsTypedParameter(from unresolvedParameter: UnresolvedParameter, inParent parent: TypeName) throws
        -> TypedParameter?
    {

        // Collect the parameter
        let parameter: OpenAPI.Parameter
        switch unresolvedParameter {
        case let .a(ref): parameter = try components.lookup(ref)
        case let .b(_parameter): parameter = _parameter
        }

        // OpenAPI 3.0.3: https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#fixed-fields-10
        // > If in is "header" and the name field is "Accept", "Content-Type" or "Authorization", the parameter definition SHALL be ignored.
        if parameter.location == .header {
            switch parameter.name.lowercased() {
            case "accept", "content-type", "authorization": return nil
            default: break
            }
        }

        let locationTypeName = parameter.location.typeName(in: parent)
        let foundIn = "\(locationTypeName.description)/\(parameter.name)"

        let schema: UnresolvedSchema
        let codingStrategy: CodingStrategy
        let style: OpenAPI.Parameter.SchemaContext.Style
        let explode: Bool
        switch parameter.schemaOrContent {
        case let .a(schemaContext):
            schema = schemaContext.schema
            style = schemaContext.style
            explode = schemaContext.explode
            codingStrategy = .uri

            // Check supported exploded/style types
            let location = parameter.location
            switch location {
            case .query:
                guard case .form = style else {
                    try diagnostics.emitUnsupported(
                        "Query params of style \(style.rawValue), explode: \(explode)",
                        foundIn: foundIn
                    )
                    return nil
                }
            case .header, .path:
                guard case .simple = style else {
                    try diagnostics.emitUnsupported(
                        "\(location.rawValue) params of style \(style.rawValue), explode: \(explode)",
                        foundIn: foundIn
                    )
                    return nil
                }
            case .cookie:
                try diagnostics.emitUnsupported("Cookie params", foundIn: foundIn)
                return nil
            }

        case let .b(contentMap):
            guard
                let typedContent = try bestSingleTypedContent(
                    contentMap,
                    excludeBinary: true,
                    inParent: locationTypeName
                )
            else { return nil }
            schema = typedContent.content.schema ?? .b(.fragment)
            codingStrategy = typedContent.content.contentType.codingStrategy

            // Defaults are defined by the OpenAPI specification:
            // https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#fixed-fields-10
            switch parameter.location {
            case .query, .cookie:
                style = .form
                explode = true
            case .path, .header:
                style = .simple
                explode = false
            }
        }

        // Check if the underlying schema is supported
        guard try validateSchemaIsSupported(schema, foundIn: foundIn) else { return nil }

        let type: TypeUsage
        switch unresolvedParameter {
        case let .a(ref): type = try typeAssigner.typeName(for: ref).asUsage
        case let .b(_parameter):
            switch schema {
            case let .a(reference): type = try typeAssigner.typeName(for: reference).asUsage
            case let .b(schema):
                type = try typeAssigner.typeUsage(
                    forParameterNamed: _parameter.name,
                    withSchema: schema,
                    components: components,
                    inParent: locationTypeName
                )
            }
        }
        let usage = type.withOptional(!parameter.required)
        return .init(
            parameter: parameter,
            schema: schema,
            style: style,
            explode: explode,
            typeUsage: usage,
            codingStrategy: codingStrategy,
            context: context
        )
    }
}

/// An unresolved OpenAPI parameter.
///
/// Can be either a reference or an inline parameter.
typealias UnresolvedParameter = Either<OpenAPI.Reference<OpenAPI.Parameter>, OpenAPI.Parameter>

extension OpenAPI.Parameter.Context.Location {

    /// A name of the location usable as a Swift type name.
    var shortTypeName: String {
        switch self {
        case .path: return "Path"
        case .header: return "Headers"
        case .query: return "Query"
        case .cookie: return "Cookies"
        }
    }

    /// Returns a type name that's nested in the provided type name with the location's name appended.
    func typeName(in parent: TypeName) -> TypeName {
        parent.appending(swiftComponent: shortTypeName, jsonComponent: rawValue)
    }

    /// A name of the location usable as a Swift variable name.
    var shortVariableName: String {
        switch self {
        case .path: return "path"
        case .header: return "headers"
        case .query: return "query"
        case .cookie: return "cookies"
        }
    }
}

extension OpenAPI.Parameter.SchemaContext.Style {

    /// The runtime name for the style.
    var runtimeName: String {
        switch self {
        case .form: return Constants.Components.Parameters.Style.form
        default: preconditionFailure("Unsupported style")
        }
    }
}
