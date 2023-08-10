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

final class Test_Server: XCTestCase {

    var client: TestClient!
    var server: TestServerTransport {
        get throws {
            try client.configuredServer()
        }
    }

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    func testGetStats_200_text() async throws {
        client = .init(
            getStatsBlock: { input in
                return .ok(.init(body: .text("count is 1")))
            }
        )
        let response = try await server.getStats(
            .init(
                path: "/api/pets/stats",
                method: .patch,
                headerFields: [
                    .init(name: "accept", value: "application/json, text/plain, application/octet-stream")
                ]
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
        XCTAssertEqualStringifiedData(
            response.body,
            #"""
            count is 1
            """#
        )
    }

    func testGetStats_200_text_customAccept() async throws {
        client = .init(
            getStatsBlock: { input in
                XCTAssertEqual(
                    input.headers.accept,
                    [
                        .init(quality: 0.8, contentType: .json),
                        .init(contentType: .text),
                    ]
                )
                return .ok(.init(body: .text("count is 1")))
            }
        )
        let response = try await server.getStats(
            .init(
                path: "/api/pets/stats",
                method: .patch,
                headerFields: [
                    .init(name: "accept", value: "application/json; q=0.8, text/plain")
                ]
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
        XCTAssertEqualStringifiedData(
            response.body,
            #"""
            count is 1
            """#
        )
    }

    func testGetStats_200_binary() async throws {
        client = .init(
            getStatsBlock: { input in
                return .ok(.init(body: .binary(Data("count_is_1".utf8))))
            }
        )
        let response = try await server.getStats(
            .init(
                path: "/api/pets/stats",
                method: .patch,
                headerFields: [
                    .init(name: "accept", value: "application/json, text/plain, application/octet-stream")
                ]
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .init(name: "content-type", value: "application/octet-stream")
            ]
        )
        XCTAssertEqualStringifiedData(
            response.body,
            #"""
            count_is_1
            """#
        )
    }

    func testPostStats_202_text() async throws {
        client = .init(
            postStatsBlock: { input in
                guard case let .text(stats) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqual(stats, "count is 1")
                return .accepted(.init())
            }
        )
        let response = try await server.postStats(
            .init(
                path: "/api/pets/stats",
                method: .post,
                headerFields: [
                    .init(name: "content-type", value: "text/plain")
                ],
                encodedBody: #"""
                    count is 1
                    """#
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 202)
        XCTAssertEqual(
            response.headerFields,
            []
        )
        XCTAssert(response.body.isEmpty)
    }

    func testPostStats_202_binary() async throws {
        client = .init(
            postStatsBlock: { input in
                guard case let .binary(stats) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqualStringifiedData(stats, "count_is_1")
                return .accepted(.init())
            }
        )
        let response = try await server.postStats(
            .init(
                path: "/api/pets/stats",
                method: .post,
                headerFields: [
                    .init(name: "content-type", value: "application/octet-stream")
                ],
                encodedBody: #"""
                    count_is_1
                    """#
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 202)
        XCTAssertEqual(
            response.headerFields,
            []
        )
        XCTAssert(response.body.isEmpty)
    }
}
