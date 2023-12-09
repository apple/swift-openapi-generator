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
import OpenAPIRuntime
import HTTPTypes

/// A server middleware that authenticates the incoming user based on the value of
/// the `Authorization` header field and injects the identifier `User` information
/// into a task local value, allowing the request handler to use it.
package struct AuthenticationServerMiddleware: Sendable {

    /// Information about an authenticated user.
    package struct User: Hashable {

        /// The name of the authenticated user.
        package var name: String

        /// Creates a new user.
        /// - Parameter name: The name of the authenticated user.
        package init(name: String) { self.name = name }

        /// The task local value of the currently authenticated user.
        @TaskLocal package static var current: User?
    }

    /// The closure that authenticates the user based on the value of the `Authorization`
    /// header field.
    private let authenticate: @Sendable (String) -> User?

    /// Creates a new middleware.
    /// - Parameter authenticate: The closure that authenticates the user based on the value
    ///   of the `Authorization` header field.
    package init(authenticate: @Sendable @escaping (String) -> User?) { self.authenticate = authenticate }
}

extension AuthenticationServerMiddleware: ServerMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        // Extracts the `Authorization` value, if present.
        // If no `Authorization` header field value was provided, no User is injected into
        // the task local.
        guard let authorizationHeaderFieldValue = request.headerFields[.authorization] else {
            return try await next(request, body, metadata)
        }
        // Delegate the authentication logic to the closure.
        let user = authenticate(authorizationHeaderFieldValue)
        // Inject the authenticated user into the task local and call the next middleware.
        return try await User.$current.withValue(user) { try await next(request, body, metadata) }
    }
}
