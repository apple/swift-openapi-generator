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

public final class TestServerTransport: ServerTransport {

    public struct OperationInputs: Equatable {
        public var method: HTTPRequest.Method
        public var path: String

        public init(method: HTTPRequest.Method, path: String) {
            self.method = method
            self.path = path
        }
    }

    public typealias Handler = @Sendable (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (
        HTTPResponse, HTTPBody?
    )

    public struct Operation {
        public var inputs: OperationInputs
        public var closure: Handler

        public init(inputs: OperationInputs, closure: @escaping Handler) {
            self.inputs = inputs
            self.closure = closure
        }
    }

    public init() {}
    public private(set) var registered: [Operation] = []

    public func register(
        _ handler: @Sendable @escaping (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (
            HTTPResponse, HTTPBody?
        ),
        method: HTTPRequest.Method,
        path: String
    ) throws {
        registered.append(
            Operation(
                inputs: .init(method: method, path: path),
                closure: handler
            )
        )
    }
}
