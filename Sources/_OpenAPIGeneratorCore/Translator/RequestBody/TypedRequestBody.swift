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

/// A container for an OpenAPI request body and its computed Swift type usage.
struct TypedRequestBody {

    /// The OpenAPI request body.
    var request: OpenAPI.Request

    /// The computed type usage.
    var typeUsage: TypeUsage

    /// A Boolean value indicating whether the response is inlined.
    var isInlined: Bool

    /// The validated content.
    var content: TypedSchemaContent
}

extension FileTranslator {

    /// Returns typed request body for the specified operation's request body.
    /// - Parameters:
    ///   - operation: The parent operation of the request body.
    /// - Returns: Typed request content; nil if the request body is nil or
    /// unsupported.
    func typedRequestBody(
        in operation: OperationDescription
    ) throws -> TypedRequestBody? {
        guard let requestBody = operation.operation.requestBody else {
            return nil
        }
        return try typedRequestBody(
            from: requestBody,
            inParent: operation.inputTypeName
        )
    }

    /// Returns typed request body for the specified request body.
    /// - Parameters:
    ///   - unresolvedRequest: An unresolved request body.
    ///   - parent: The parent type of the request body.
    /// - Returns: Typed request content; nil if the request body is
    /// unsupported.
    func typedRequestBody(
        from unresolvedRequest: Either<JSONReference<OpenAPI.Request>, OpenAPI.Request>,
        inParent parent: TypeName
    ) throws -> TypedRequestBody? {
        let type: TypeName
        switch unresolvedRequest {
        case .a(let reference):
            type = try TypeAssigner.typeName(for: reference)
        case .b:
            type = parent.appending(
                swiftComponent: Constants.Operation.Body.typeName
            )
        }
        return try typedRequestBody(
            typeName: type,
            from: unresolvedRequest
        )
    }

    /// Returns typed request body for the specified request body.
    /// - Parameters:
    ///   - typeName: The type of the request body.
    ///   - unresolvedRequest: An unresolved request body.
    /// - Returns: Typed request content; nil if the request body is
    /// unsupported.
    func typedRequestBody(
        typeName: TypeName,
        from unresolvedRequest: Either<JSONReference<OpenAPI.Request>, OpenAPI.Request>
    ) throws -> TypedRequestBody? {

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

        guard
            let content = try bestSingleTypedContent(
                request.content,
                inParent: typeName
            )
        else {
            return nil
        }

        let usage = typeName.asUsage.withOptional(!request.required)
        return TypedRequestBody(
            request: request,
            typeUsage: usage,
            isInlined: isInlined,
            content: content
        )
    }
}
