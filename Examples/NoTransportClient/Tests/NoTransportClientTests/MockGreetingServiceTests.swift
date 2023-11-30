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
import NoTransportClient
import OpenAPIRuntime
import HTTPTypes

struct MockTransport: ClientTransport {
    func send(
        _ request: HTTPTypes.HTTPRequest,
        body: OpenAPIRuntime.HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (
        HTTPTypes.HTTPResponse,
        OpenAPIRuntime.HTTPBody?
    ) {
        return (
            HTTPResponse(status: .ok, headerFields: [.contentType: "application/json"]),
            HTTPBody(#"{"message": "Hello, Stranger!"}"#)
        )
    }
}

final class GreetingServiceMockTests: XCTestCase {
    func testWithMock() async throws {
        let transport = MockTransport()
        let client = try GreetingServiceClient(transport: transport)
        let response = try await client.invoke()
        XCTAssertEqual(response, "Hello, Stranger!")
    }
}
