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

/// A container for an OpenAPI response and its computed Swift type usage.
struct TypedResponse {

    /// The OpenAPI response.
    var response: ResolvedResponse

    /// The computed type usage.
    var typeUsage: TypeUsage

    /// A Boolean value indicating whether the response is inlined.
    var isInlined: Bool
}

extension FileTranslator {

    /// Returns a typed response for the specified unresolved response.
    /// - Parameters:
    ///   - unresolvedResponse: An unresolved response.
    ///   - operation: The operation in which the response resi.
    /// - Returns: A typed response.
    func typedResponse(
        from outcome: OpenAPI.Operation.ResponseOutcome,
        operation: OperationDescription
    ) throws -> TypedResponse {
        let unresolvedResponse = outcome.response
        let typeName: TypeName
        let response: ResolvedResponse
        let isInlined: Bool
        switch unresolvedResponse {
        case .a(let reference):
            typeName = try TypeAssigner.typeName(for: reference)
            response = try components.lookup(reference)
            isInlined = false
        case .b(let _response):
            let responseKind = outcome.status.value.asKind
            typeName = operation.responseStructTypeName(for: responseKind)
            response = _response
            isInlined = true
        }
        return .init(
            response: response,
            typeUsage: typeName.asUsage,
            isInlined: isInlined
        )
    }
}

/// An unresolved OpenAPI response.
///
/// Can be either a reference or an inline response.
typealias UnresolvedResponse = Either<JSONReference<OpenAPI.Response>, OpenAPI.Response>

/// A resolved OpenAPI response.
typealias ResolvedResponse = OpenAPI.Response
