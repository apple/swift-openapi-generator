//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import Foundation
import OpenAPIKit

extension TypesFileTranslator {

    /// The Swift type `[OpenAPIRuntime.SecurityRequirement]`.
    private var securityRequirementsArrayType: ExistingTypeDescription {
        .array(.init(TypeName.runtime("SecurityRequirement")))
    }

    /// Returns the security requirements that apply to the operation.
    ///
    /// An operation that does not declare `security` inherits the document-level
    /// requirements; an operation that declares `security: []` is explicitly
    /// public and returns an empty array.
    /// - Parameters:
    ///   - operation: The operation whose requirements to resolve.
    ///   - documentSecurity: The document-level security requirements.
    /// - Returns: The effective OR-list of security requirements.
    private func effectiveSecurityRequirements(
        for operation: OperationDescription,
        documentSecurity: [OpenAPI.SecurityRequirement]
    ) -> [OpenAPI.SecurityRequirement] {
        operation.operation.security ?? documentSecurity
    }

    /// Returns an expression constructing the `[OpenAPIRuntime.SecurityRequirement]`
    /// value for the provided OpenAPI security requirements.
    ///
    /// The outer array is an OR-list of alternatives; each requirement is an
    /// AND-group of schemes.
    /// - Parameters:
    ///   - requirements: The OpenAPI security requirements (OR-list).
    ///   - components: The components used to resolve security scheme references.
    /// - Returns: An array-literal expression.
    /// - Throws: If a scheme reference cannot be resolved or uses an unsupported type.
    private func translateSecurityRequirements(
        _ requirements: [OpenAPI.SecurityRequirement],
        components: OpenAPI.Components
    ) throws -> Expression {
        let requirementExprs = try requirements.map { requirement in
            try translateSecurityRequirement(requirement, components: components)
        }
        return .literal(.array(requirementExprs))
    }

    /// Returns an expression constructing a single `SecurityRequirement` value
    /// (an AND-group of schemes).
    private func translateSecurityRequirement(
        _ requirement: OpenAPI.SecurityRequirement,
        components: OpenAPI.Components
    ) throws -> Expression {
        // Security requirements are a dictionary keyed by an (unordered) scheme
        // reference, so sort by scheme name to keep generated output stable.
        let schemes =
            try requirement
            .map { reference, scopes -> (name: String, scheme: OpenAPI.SecurityScheme, scopes: [String]) in
                guard let name = reference.name else {
                    throw GenericError(message: "Security scheme reference has no name: \(reference.absoluteString)")
                }
                guard let scheme = components[reference] else {
                    throw GenericError(message: "Undefined security scheme: \(reference.absoluteString)")
                }
                return (name, scheme, scopes)
            }
            .sorted { $0.name < $1.name }
        let schemeExprs = try schemes.map { entry in
            try translateSecurityScheme(name: entry.name, scheme: entry.scheme, scopes: entry.scopes)
        }
        return .dot("init").call([.init(label: "schemes", expression: .literal(.array(schemeExprs)))])
    }

    /// Returns an expression constructing a single `SecurityRequirement.Scheme` value.
    private func translateSecurityScheme(
        name: String,
        scheme: OpenAPI.SecurityScheme,
        scopes: [String]
    ) throws -> Expression {
        try .dot("init")
            .call([
                .init(label: "name", expression: .literal(name)),
                .init(label: "kind", expression: translateSecuritySchemeKind(scheme.type)),
                .init(label: "scopes", expression: .literal(.array(scopes.map { .literal($0) }))),
            ])
    }

    /// Returns an expression constructing a `SecurityRequirement.Scheme.Kind` value.
    private func translateSecuritySchemeKind(_ type: OpenAPI.SecurityScheme.SecurityType) throws -> Expression {
        switch type {
        case .apiKey(let name, let location):
            return .dot("apiKey")
                .call([
                    .init(label: "name", expression: .literal(name)),
                    .init(label: "location", expression: .dot(location.rawValue)),
                ])
        case .http(let scheme, let bearerFormat):
            return .dot("http")
                .call([
                    .init(label: "scheme", expression: .literal(scheme.lowercased())),
                    .init(label: "bearerFormat", expression: bearerFormat.map { .literal($0) } ?? .literal(.nil)),
                ])
        case .oauth2:
            return .dot("oauth2")
        case .openIdConnect(let url):
            return .dot("openIdConnect").call([.init(label: "url", expression: .literal(url.absoluteString))])
        case .mutualTLS:
            throw GenericError(message: "mutualTLS security schemes are not supported by the securityMetadata feature.")
        }
    }

    /// Returns the per-operation `securityRequirements` static property declaration.
    /// - Parameters:
    ///   - operation: The operation to translate.
    ///   - documentSecurity: The document-level security requirements.
    /// - Returns: A variable declaration.
    /// - Throws: If a scheme reference cannot be resolved or uses an unsupported type.
    func translateOperationSecurityRequirements(
        _ operation: OperationDescription,
        documentSecurity: [OpenAPI.SecurityRequirement]
    ) throws -> Declaration {
        let requirements = effectiveSecurityRequirements(for: operation, documentSecurity: documentSecurity)
        let value = try translateSecurityRequirements(requirements, components: operation.components)
        return .variable(
            accessModifier: config.access,
            isStatic: true,
            kind: .let,
            left: Constants.Operations.securityRequirementsPropertyName,
            type: securityRequirementsArrayType,
            right: value
        )
    }

    /// Returns the `OperationSecurity` namespace declaration, exposing a map
    /// from operation ID to the operation's security requirements.
    /// - Parameter operations: The operations defined in the OpenAPI document.
    /// - Returns: An enum declaration.
    func translateOperationSecurityNamespace(_ operations: [OperationDescription]) -> Declaration {
        let entries: [Expression] = operations.map { operation in
            let operationRef = Expression.identifierPattern(Constants.Operations.namespace)
                .dot(operation.operationNamespace.shortSwiftName)
            return .tuple([
                .literal(operation.operationID),
                operationRef.dot(Constants.Operations.securityRequirementsPropertyName),
            ])
        }
        let mapDecl = Declaration.variable(
            accessModifier: config.access,
            isStatic: true,
            kind: .let,
            left: Constants.Operations.requirementsByOperationIDPropertyName,
            type: .dictionaryValue(securityRequirementsArrayType),
            right: .identifierPattern("Dictionary")
                .call([.init(label: "uniqueKeysWithValues", expression: .literal(.array(entries)))])
        )
        return .commentable(
            .doc("The security requirements of each operation, keyed by operation ID."),
            .enum(accessModifier: config.access, name: Constants.Operations.securityNamespace, members: [mapDecl])
        )
    }
}
