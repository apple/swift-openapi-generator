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

/// A test implementation of the `ServerTransport` protocol for simulating server-side API handling.
///
/// The `TestServerTransport` class allows you to define custom operations and handlers that
/// simulate server-side API handling. This is useful for testing and verifying the behavior of
/// your server-related code without the need for actual network interactions.
///
/// Example usage:
/// ```swift
/// let testTransport = TestServerTransport()
/// try testTransport.register { request, metadata in
///     // Simulate server response logic here
///     return Response(...)
/// }
///
/// let server = MyServer(transport: testTransport)
/// ```
public final class TestServerTransport: ServerTransport {
    /// Represents the input parameters for an API operation.
    public struct OperationInputs: Equatable {
        /// The HTTP method of the operation.
        public var method: HTTPRequest.Method
        /// The path components of the operation's route.
        public var path: String

        /// Initializes a new instance of `OperationInputs`.
        ///
        /// - Parameters:
        ///   - method: The HTTP method of the operation.
        ///   - path: The path components of the operation's route.
        public init(method: HTTPRequest.Method, path: String) {
            self.method = method
            self.path = path
        }
    }

    /// A typealias representing a handler closure for processing server requests.
    public typealias Handler = @Sendable (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (
        HTTPResponse, HTTPBody?
    )

    /// Represents an operation with its inputs and associated handler.
    public struct Operation {
        /// The input parameters for the API operation.
        public var inputs: OperationInputs
        /// The closure representing the server operation logic.
        public var closure: Handler

        /// Initializes a new instance of `Operation`.
        ///
        /// - Parameters:
        ///   - inputs: The input parameters for the API operation.
        ///   - closure: The closure representing the server operation logic
        public init(inputs: OperationInputs, closure: @escaping Handler) {
            self.inputs = inputs
            self.closure = closure
        }
    }

    /// Initializes a new instance of `TestServerTransport`.
    public init() {}

    /// The array of registered operations.
    public private(set) var registered: [Operation] = []

    /// Registers a new API operation handler with specific parameters.
    ///
    /// - Parameters:
    ///   - handler: The closure representing the server operation logic.
    ///   - method: The HTTP method of the operation.
    ///   - path: The path components of the operation.
    /// - Throws: An error if there's an issue registering the operation.
    public func register(
        _ handler: @Sendable @escaping (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (
            HTTPResponse, HTTPBody?
        ),
        method: HTTPRequest.Method,
        path: String
    ) throws { registered.append(Operation(inputs: .init(method: method, path: path), closure: handler)) }
}
