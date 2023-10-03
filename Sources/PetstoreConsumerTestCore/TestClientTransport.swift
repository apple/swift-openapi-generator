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
import HTTPTypes

public struct TestClientTransport: ClientTransport {

    public typealias CallHandler = @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (
        HTTPResponse, HTTPBody?
    )

    public let callHandler: CallHandler

    public init(callHandler: @escaping CallHandler) {
        self.callHandler = callHandler
    }

    public func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        try await callHandler(request, body, baseURL, operationID)
    }
}
