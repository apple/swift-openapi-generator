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

public final class TestServerTransport: ServerTransport {

    public struct OperationInputs: Equatable {
        public var method: HTTPMethod
        public var path: [RouterPathComponent]
        public var queryItemNames: Set<String>

        public init(method: HTTPMethod, path: [RouterPathComponent], queryItemNames: Set<String>) {
            self.method = method
            self.path = path
            self.queryItemNames = queryItemNames
        }
    }

    public typealias Handler = @Sendable (Request, ServerRequestMetadata) async throws -> Response

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
        _ handler: @escaping Handler,
        method: HTTPMethod,
        path: [RouterPathComponent],
        queryItemNames: Set<String>
    ) throws {
        registered.append(
            Operation(
                inputs: .init(method: method, path: path, queryItemNames: queryItemNames),
                closure: handler
            )
        )
    }
}
