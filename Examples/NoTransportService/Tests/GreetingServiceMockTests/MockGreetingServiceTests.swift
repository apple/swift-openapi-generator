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
import XCTest
import NoTransportService
import OpenAPIRuntime
import HTTPTypes

final class MockTransport: ServerTransport {
    
    private var route: ((HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?))?
    
    init() {
        route = nil
    }
    
    func register(
        _ handler: @escaping @Sendable (
            HTTPRequest,
            HTTPBody?,
            ServerRequestMetadata
        ) async throws -> (
            HTTPResponse,
            HTTPBody?
        ),
        method: HTTPTypes.HTTPRequest.Method,
        path: String
    ) throws {
        route = handler
    }
    
    func invoke(_ request: HTTPRequest, body: HTTPBody?) async throws -> (HTTPResponse, HTTPBody?) {
        try await route!(request, body, .init())
    }
}

final class GreetingServiceMockTests: XCTestCase {
    func testWithMock() async throws {
        let transport = MockTransport()
        try GreetingService.register(transport: transport)
        let (response, body) = try await transport.invoke(
            .init(method: .get, scheme: nil, authority: nil, path: "/api/greet"),
            body: nil
        )
        guard response.status == .ok, let body else {
            XCTFail("Unexpected response")
            return
        }
        let responseBodyData = try await Data(collecting: body, upTo: 1024)
        struct ExpectedResponseBody: Decodable, Hashable {
            var message: String
        }
        let responseBodyValue = try JSONDecoder().decode(ExpectedResponseBody.self, from: responseBodyData)
        XCTAssertEqual(responseBodyValue, .init(message: "Hello, Stranger!"))
    }
}
