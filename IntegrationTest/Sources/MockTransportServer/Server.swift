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
import Types
import Server
import OpenAPIRuntime
import HTTPTypes

actor SimpleAPIImpl: APIProtocol {
    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        let message = "Hello, \(input.query.name ?? "Stranger")!"
        return .ok(.init(body: .json(.init(message: message))))
    }
}

class MockServerTransport: ServerTransport {
    typealias Handler = @Sendable (
        HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, OpenAPIRuntime.ServerRequestMetadata
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)

    func register(_ handler: @escaping Handler, method: HTTPTypes.HTTPRequest.Method, path: String) throws {
        // noop.
    }
}

func initializeServer() throws {
    let handler = SimpleAPIImpl()
    let transport = MockServerTransport()
    try handler.registerHandlers(on: transport, serverURL: Servers.Server1.url())
}
