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

/// A container for an OpenAPI parameter and its computed Swift type usage.
struct TypedParameter {

    /// The OpenAPI parameter.
    var parameter: ResolvedParameter

    /// The underlying schema.
    var schema: Either<JSONReference<JSONSchema>, JSONSchema>

    /// The computed type usage.
    var typeUsage: TypeUsage

    /// The coding strategy appropriate for this parameter.
    var codingStrategy: CodingStrategy
}

extension TypedParameter: CustomStringConvertible {
    var description: String {
        typeUsage.description + "/param:\(name)"
    }
}

extension TypedParameter {

    /// The name of the parameter exactly as specified in the OpenAPI document.
    var name: String {
        parameter.name
    }

    /// The name of the parameter sanitized to be a valid Swift identifier.
    var variableName: String {
        name.asSwiftSafeName
    }

    /// A Boolean value that indicates whether the parameter must be specified
    /// when performing the OpenAPI operation.
    var required: Bool {
        parameter.required
    }

    /// The location of the parameter in the HTTP request.
    var location: ResolvedParameter.Context.Location {
        parameter.location
    }

    /// A schema to be inlined.
    ///
    /// - Returns: Nil when schema is referenceable.
    var inlineableSchema: JSONSchema? {
        schema.inlineableSchema
    }
}

extension Either where A == JSONReference<JSONSchema>, B == JSONSchema {

    /// A schema to be inlined.
    ///
    /// - Returns: Nil when schema is referenceable.
    var inlineableSchema: JSONSchema? {
        switch self {
        case .a:
            return nil
        case let .b(schema):
            if TypeMatcher.isInlinable(schema) {
                return schema
            }
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
    func typedParameters(
        from operation: OperationDescription
    ) throws -> [TypedParameter] {
        let inputTypeName = operation.inputTypeName
        return
            try operation
            .allParameters
            .compactMap { parameter in
                try parseAsTypedParameter(
                    from: parameter,
                    inParent: inputTypeName
                )
            }
    }

    /// Returns a typed parameter if the specified unresolved parameter is supported.
    /// - Parameters:
    ///   - unresolvedParameter: An unresolved parameter.
    ///   - parent: The parent type of the parameter.
    /// - Returns: A typed parameter. Nil if the parameter is unsupported.
    func parseAsTypedParameter(
        from unresolvedParameter: UnresolvedParameter,
        inParent parent: TypeName
    ) throws -> TypedParameter? {

        // Collect the parameter
        let parameter: ResolvedParameter
        switch unresolvedParameter {
        case let .a(ref):
            parameter = try components.lookup(ref)
        case let .b(_parameter):
            parameter = _parameter
        }

        let locationTypeName = parameter.location.typeName(in: parent)
        let foundIn = "\(locationTypeName.description)/\(parameter.name)"

        let schema: Either<JSONReference<JSONSchema>, JSONSchema>
        let codingStrategy: CodingStrategy
        switch parameter.schemaOrContent {
        case let .a(schemaContext):
            schema = schemaContext.schema
            codingStrategy = .text

            // Check supported exploded/style types
            let location = parameter.location
            switch location {
            case .query:
                guard case .form = schemaContext.style else {
                    diagnostics.emitUnsupported(
                        "Non-form style query params",
                        foundIn: foundIn
                    )
                    return nil
                }
                guard schemaContext.explode else {
                    diagnostics.emitUnsupported(
                        "Unexploded query params",
                        foundIn: foundIn
                    )
                    return nil
                }
            case .header, .path:
                guard case .simple = schemaContext.style else {
                    diagnostics.emitUnsupported(
                        "Non-simple style \(location.rawValue) params",
                        foundIn: foundIn
                    )
                    return nil
                }
            case .cookie:
                diagnostics.emitUnsupported(
                    "Cookie params",
                    foundIn: foundIn
                )
                return nil
            }

        case let .b(contentMap):
            guard
                let typedContent = try bestSingleTypedContent(
                    contentMap,
                    excludeBinary: true,
                    inParent: locationTypeName
                )
            else {
                return nil
            }
            schema = typedContent.content.schema ?? .b(.fragment)
            codingStrategy =
                typedContent
                .content
                .contentType
                .codingStrategy
        }

        // Check if the underlying schema is supported
        guard
            try validateSchemaIsSupported(
                schema,
                foundIn: foundIn
            )
        else {
            return nil
        }

        let type: TypeUsage
        switch unresolvedParameter {
        case let .a(ref):
            type = try TypeAssigner.typeName(for: ref).asUsage
        case let .b(_parameter):
            switch schema {
            case let .a(reference):
                type = try TypeAssigner.typeName(for: reference).asUsage
            case let .b(schema):
                type = try TypeAssigner.typeUsage(
                    forParameterNamed: _parameter.name,
                    withSchema: schema,
                    inParent: locationTypeName
                )
            }
        }
        let usage = type.withOptional(!parameter.required)
        return .init(
            parameter: parameter,
            schema: schema,
            typeUsage: usage,
            codingStrategy: codingStrategy
        )
    }
}

/// An unresolved OpenAPI parameter.
///
/// Can be either a reference or an inline parameter.
typealias UnresolvedParameter = Either<JSONReference<OpenAPI.Parameter>, OpenAPI.Parameter>

/// A resolved OpenAPI parameter.
typealias ResolvedParameter = OpenAPI.Parameter

extension ResolvedParameter.Context.Location {

    /// A name of the location usable as a Swift type name.
    var shortTypeName: String {
        switch self {
        case .path:
            return "Path"
        case .header:
            return "Headers"
        case .query:
            return "Query"
        case .cookie:
            return "Cookies"
        }
    }

    /// Returns a type name that's nested in the provided type name with the location's name appended.
    func typeName(in parent: TypeName) -> TypeName {
        parent.appending(
            swiftComponent: shortTypeName,
            jsonComponent: rawValue
        )
    }

    /// A name of the location usable as a Swift variable name.
    var shortVariableName: String {
        switch self {
        case .path:
            return "path"
        case .header:
            return "headers"
        case .query:
            return "query"
        case .cookie:
            return "cookies"
        }
    }
}
