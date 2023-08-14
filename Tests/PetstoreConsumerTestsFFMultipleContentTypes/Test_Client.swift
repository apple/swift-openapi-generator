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
import OpenAPIRuntime
import PetstoreConsumerTestCore

final class Test_Client: XCTestCase {

    var transport: TestClientTransport!
    var client: Client {
        get throws {
            .init(
                serverURL: try URL(validatingOpenAPIServerURL: "/api"),
                transport: transport
            )
        }
    }

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    func testGetStats_200_text() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "getStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(request.method, .get)
            XCTAssertNil(request.body)
            return .init(
                statusCode: 200,
                headers: [
                    .init(name: "content-type", value: "text/plain")
                ],
                encodedBody: #"""
                    count is 1
                    """#
            )
        }
        let response = try await client.getStats(.init())
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .plainText(let stats):
            XCTAssertEqual(stats, "count is 1")
        default:
            XCTFail("Unexpected content type")
        }
    }

    func testGetStats_200_binary() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "getStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(request.method, .get)
            XCTAssertNil(request.body)
            return .init(
                statusCode: 200,
                headers: [
                    .init(name: "content-type", value: "application/octet-stream")
                ],
                encodedBody: #"""
                    count_is_1
                    """#
            )
        }
        let response = try await client.getStats(.init())
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .binary(let stats):
            XCTAssertEqual(String(decoding: stats, as: UTF8.self), "count_is_1")
        default:
            XCTFail("Unexpected content type")
        }
    }

    func testPostStats_202_text() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "postStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertNil(request.query)
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(
                request.headerFields,
                [
                    .init(name: "content-type", value: "text/plain")
                ]
            )
            XCTAssertEqual(
                request.body?.pretty,
                #"""
                count is 1
                """#
            )
            return .init(statusCode: 202)
        }
        let response = try await client.postStats(
            .init(body: .plainText("count is 1"))
        )
        guard case .accepted = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testPostStats_202_binary() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "postStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertNil(request.query)
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(
                request.headerFields,
                [
                    .init(name: "content-type", value: "application/octet-stream")
                ]
            )
            XCTAssertEqual(
                request.body?.pretty,
                #"""
                count_is_1
                """#
            )
            return .init(statusCode: 202)
        }
        let response = try await client.postStats(
            .init(body: .binary(Data("count_is_1".utf8)))
        )
        guard case .accepted = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }
}
