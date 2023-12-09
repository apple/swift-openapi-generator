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
@testable import ContentTypesServer

final class ContentTypesServerTests: XCTestCase {

    func testGetJSON() async throws {
        let handler: APIProtocol = Handler()
        let response = try await handler.getExampleJSON(query: .init(name: "Test"))
        XCTAssertEqual(response, .ok(.init(body: .json(.init(message: "Hello, Test!")))))
    }

    func testPostJSON() async throws {
        let handler: APIProtocol = Handler()
        let response = try await handler.postExampleJSON(body: .json(.init(message: "Hello, Test!")))
        XCTAssertEqual(response, .accepted(.init()))
    }

    func testGetPlainText() async throws {
        let handler: APIProtocol = Handler()
        let response = try await handler.getExamplePlainText()
        let value = try await String(collecting: response.ok.body.plainText, upTo: 1024)
        XCTAssertEqual(
            value,
            """
            A snow log.
            ---
            [2023-12-24] It snowed.
            [2023-12-25] It snowed even more.
            """
        )
    }

    func testPostPlainText() async throws {
        let handler: APIProtocol = Handler()
        let response = try await handler.postExamplePlainText(body: .plainText("Hello, world!"))
        XCTAssertEqual(response, .accepted(.init()))
    }

    func testGetMultipleContentTypes() async throws {
        let handler: APIProtocol = Handler()
        do {
            // By default, return JSON.
            let response = try await handler.getExampleMultipleContentTypes()
            XCTAssertEqual(try response.ok.body.json.message, "Hello, Stranger!")
        }
        do {
            // Explicitly ask for JSON.
            let response = try await handler.getExampleMultipleContentTypes(
                headers: .init(accept: [.init(contentType: .json)])
            )
            XCTAssertEqual(try response.ok.body.json.message, "Hello, Stranger!")
        }
        do {
            // Explicitly ask for plain text.
            let response = try await handler.getExampleMultipleContentTypes(
                headers: .init(accept: [.init(contentType: .plainText)])
            )
            let value = try await String(collecting: response.ok.body.plainText, upTo: 1024)
            XCTAssertEqual(value, "Hello, Stranger!")
        }
    }

    func testPostMultipleContentTypes() async throws {
        let handler: APIProtocol = Handler()
        do {
            let response = try await handler.postExampleMultipleContentTypes(
                body: .json(.init(message: "Hello, Stranger!"))
            )
            XCTAssertEqual(response, .accepted(.init()))
        }
        do {
            let response = try await handler.postExampleMultipleContentTypes(body: .plainText("Hello, Stranger!"))
            XCTAssertEqual(response, .accepted(.init()))
        }
    }

    func testPostURLEncoded() async throws {
        let handler: APIProtocol = Handler()
        let response = try await handler.postExampleURLEncoded(body: .urlEncodedForm(.init(message: "Hello, Test!")))
        XCTAssertEqual(response, .accepted(.init()))
    }

    func testGetRawBytes() async throws {
        let handler: APIProtocol = Handler()
        let response = try await handler.getExampleRawBytes()
        let value = try await [UInt8](collecting: response.ok.body.binary, upTo: 1024)
        XCTAssertEqual(value, [0x73, 0x6e, 0x6f, 0x77, 0x0a])
    }

    func testPostRawBytes() async throws {
        let handler: APIProtocol = Handler()
        let response = try await handler.postExampleRawBytes(body: .binary([0x73, 0x6e, 0x6f, 0x77, 0x0a]))
        XCTAssertEqual(response, .accepted(.init()))
    }

    func testGetMultipart() async throws {
        let handler: APIProtocol = Handler()
        let response = try await handler.getExampleMultipart()
        let multipartBody = try response.ok.body.multipartForm
        var parts: [Operations.getExampleMultipart.Output.Ok.Body.multipartFormPayload] = []
        for try await part in multipartBody { parts.append(part) }
        XCTAssertEqual(parts.count, 3)
    }

    func testPostMultipart() async throws {
        let handler: APIProtocol = Handler()
        let response = try await handler.postExampleMultipart(
            body: .multipartForm([.greetingTemplate(.init(payload: .init(body: .init(message: "Hello, {name}!"))))])
        )
        XCTAssertEqual(response, .accepted(.init()))
    }
}
