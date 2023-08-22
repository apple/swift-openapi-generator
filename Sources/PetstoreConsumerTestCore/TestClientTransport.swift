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
import Foundation

/// A test implementation of the `ClientTransport` protocol.
///
/// The `TestClientTransport` struct provides a way to simulate network calls by
/// utilizing a custom `CallHandler` closure. This allows testing the behavior of
/// client-side API interactions in controlled scenarios.
///
/// Example usage:
/// ```swift
/// let testTransport = TestClientTransport { request, baseURL, operationID in
///     // Simulate response logic here
///     return Response(...)
/// }
///
/// let client = APIClient(transport: testTransport)
/// ```
public struct TestClientTransport: ClientTransport {
    /// A closure that handles the client call operation.
    public typealias CallHandler = @Sendable (Request, URL, String) async throws -> Response

    /// The call handler responsible for processing client requests.
    public let callHandler: CallHandler

    /// Initializes a `TestClientTransport` instance with a custom call handler.
    ///
    /// - Parameter callHandler: The closure responsible for processing client requests.
    public init(callHandler: @escaping CallHandler) {
        self.callHandler = callHandler
    }

    /// Sends a client request using the test transport.
    ///
    /// - Parameters:
    ///   - request: The request to send.
    ///   - baseURL: The base URL for the request.
    ///   - operationID: The ID of the operation being performed.
    /// - Returns: The response received from the call handler.
    /// - Throws: An error if the call handler encounters an issue.
    public func send(
        _ request: Request,
        baseURL: URL,
        operationID: String
    ) async throws -> Response {
        try await callHandler(request, baseURL, operationID)
    }
}
