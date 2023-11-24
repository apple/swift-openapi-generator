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

/// A container for an OpenAPI request body and its computed Swift type usage.
struct TypedRequestBody {

    /// The OpenAPI request body.
    var request: OpenAPI.Request

    /// The computed type usage.
    var typeUsage: TypeUsage

    /// A Boolean value indicating whether the response is inlined.
    var isInlined: Bool

    /// The validated contents.
    var contents: [TypedSchemaContent]
}

extension FileTranslator {

    /// Returns typed request body for the specified operation's request body.
    /// - Parameter operation: The parent operation of the request body.
    /// - Returns: Typed request content; nil if the request body is nil or
    /// unsupported.
    /// - Throws: An error if there is an issue translating the parameter extraction for the client.
    func typedRequestBody(in operation: OperationDescription) throws -> TypedRequestBody? {
        guard let requestBody = operation.operation.requestBody else { return nil }
        return try typedRequestBody(from: requestBody, inParent: operation.inputTypeName)
    }

    /// Returns typed request body for the specified request body.
    /// - Parameters:
    ///   - unresolvedRequest: An unresolved request body.
    ///   - parent: The parent type of the request body.
    /// - Returns: Typed request content; nil if the request body is
    /// unsupported.
    /// - Throws: An error if there is an issue translating the typed request body.
    func typedRequestBody(from unresolvedRequest: UnresolvedRequest, inParent parent: TypeName) throws
        -> TypedRequestBody?
    {
        let type: TypeName
        switch unresolvedRequest {
        case .a(let reference): type = try typeAssigner.typeName(for: reference)
        case .b:
            type = parent.appending(swiftComponent: Constants.Operation.Body.typeName, jsonComponent: "requestBody")
        }
        return try typedRequestBody(typeName: type, from: unresolvedRequest)
    }

    /// Returns typed request body for the specified request body.
    /// - Parameters:
    ///   - typeName: The type of the request body.
    ///   - unresolvedRequest: An unresolved request body.
    /// - Returns: Typed request content; nil if the request body is
    /// unsupported.
    /// - Throws: An error if there is an issue translating the typed request body.
    func typedRequestBody(typeName: TypeName, from unresolvedRequest: UnresolvedRequest) throws -> TypedRequestBody? {

        let request: OpenAPI.Request
        let isInlined: Bool
        switch unresolvedRequest {
        case .a(let reference):
            request = try components.lookup(reference)
            isInlined = false
        case .b(let _request):
            request = _request
            isInlined = true
        }

        let contents = try supportedTypedContents(request.content, isRequired: request.required, inParent: typeName)
        if contents.isEmpty { return nil }

        let usage = typeName.asUsage.withOptional(!request.required)
        return TypedRequestBody(request: request, typeUsage: usage, isInlined: isInlined, contents: contents)
    }
}

/// An unresolved OpenAPI request.
///
/// Can be either a reference or an inline request.
typealias UnresolvedRequest = Either<OpenAPI.Reference<OpenAPI.Request>, OpenAPI.Request>
