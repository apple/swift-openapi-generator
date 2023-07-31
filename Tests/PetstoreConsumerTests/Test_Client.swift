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

    func testListPets_200() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "listPets")
            XCTAssertEqual(request.path, "/pets")
            XCTAssertEqual(
                request.query,
                "limit=24&habitat=water&feeds=herbivore&feeds=carnivore&since=2023-01-18T10:04:11Z"
            )
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(
                request.headerFields,
                [
                    .init(name: "My-Request-UUID", value: "abcd-1234"),
                    .init(name: "accept", value: "application/json"),
                ]
            )
            XCTAssertNil(request.body)
            return .init(
                statusCode: 200,
                headers: [
                    .init(name: "content-type", value: "application/json"),
                    .init(name: "my-response-uuid", value: "abcd"),
                    .init(name: "my-tracing-header", value: "1234"),
                ],
                encodedBody: #"""
                    [
                      {
                        "id": 1,
                        "name": "Fluffz"
                      }
                    ]
                    """#
            )
        }
        let response = try await client.listPets(
            .init(
                query: .init(
                    limit: 24,
                    habitat: .water,
                    feeds: [.herbivore, .carnivore],
                    since: .test
                ),
                headers: .init(
                    My_Request_UUID: "abcd-1234"
                )
            )
        )
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(value.headers.My_Response_UUID, "abcd")
        XCTAssertEqual(value.headers.My_Tracing_Header, "1234")
        switch value.body {
        case .json(let pets):
            XCTAssertEqual(pets, [.init(id: 1, name: "Fluffz")])
        }
    }

    func testListPets_default() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "listPets")
            XCTAssertEqual(request.path, "/pets")
            XCTAssertEqual(request.query, "limit=24")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(
                request.headerFields,
                [
                    .init(name: "accept", value: "application/json")
                ]
            )
            XCTAssertNil(request.body)
            return .init(
                statusCode: 400,
                headers: [
                    .init(name: "content-type", value: "application/json")
                ],
                encodedBody: #"""
                    {
                      "code": 1,
                      "me$sage": "Oh no!",
                      "userData": {"one" : 1}
                    }
                    """#
            )
        }
        let response = try await client.listPets(
            .init(
                query: .init(limit: 24)
            )
        )
        guard case let .default(statusCode, value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(statusCode, 400)
        switch value.body {
        case .json(let error):
            XCTAssertEqual(
                error,
                .init(
                    code: 1,
                    me_sage: "Oh no!",
                    userData: try .init(unvalidatedValue: ["one": 1])
                )
            )
        }
    }

    func testCreatePet_201() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "createPet")
            XCTAssertEqual(request.path, "/pets")
            XCTAssertNil(request.query)
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(
                request.headerFields,
                [
                    .init(name: "X-Extra-Arguments", value: #"{"code":1}"#),
                    .init(name: "accept", value: "application/json"),
                    .init(name: "content-type", value: "application/json; charset=utf-8"),
                ]
            )
            XCTAssertEqual(
                request.body?.pretty,
                #"""
                {
                  "name" : "Fluffz"
                }
                """#
            )
            return .init(
                statusCode: 201,
                headers: [
                    .init(name: "content-type", value: "application/json; charset=utf-8"),
                    .init(name: "x-extra-arguments", value: #"{"code":1}"#),
                ],
                encodedBody: #"""
                    {
                      "id": 1,
                      "name": "Fluffz"
                    }
                    """#
            )
        }
        let response = try await client.createPet(
            .init(
                headers: .init(
                    X_Extra_Arguments: .init(code: 1)
                ),
                body: .json(.init(name: "Fluffz"))
            )
        )
        guard case let .created(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(value.headers.X_Extra_Arguments, .init(code: 1))
        switch value.body {
        case .json(let pets):
            XCTAssertEqual(pets, .init(id: 1, name: "Fluffz"))
        }
    }

    func testCreatePet_400() async throws {
        transport = .init { request, baseURL, operationID in
            .init(
                statusCode: 400,
                headers: [
                    .init(name: "content-type", value: "application/json; charset=utf-8"),
                    .init(name: "x-reason", value: "bad luck"),
                ],
                encodedBody: #"""
                    {
                      "code": 1
                    }
                    """#
            )
        }
        let response = try await client.createPet(
            .init(body: .json(.init(name: "Fluffz")))
        )
        guard case let .badRequest(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(value.headers.X_Reason, "bad luck")
        switch value.body {
        case .json(let body):
            XCTAssertEqual(body, .init(code: 1))
        }
    }

    func testUpdatePet_204_withBody() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "updatePet")
            XCTAssertEqual(request.path, "/pets/1")
            XCTAssertNil(request.query)
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .patch)
            XCTAssertEqual(
                request.headerFields,
                [
                    .init(name: "accept", value: "application/json"),
                    .init(name: "content-type", value: "application/json; charset=utf-8"),
                ]
            )
            XCTAssertEqual(
                request.body?.pretty,
                #"""
                {
                  "name" : "Fluffz"
                }
                """#
            )
            return .init(
                statusCode: 204,
                headerFields: [
                    .init(name: "content-type", value: "application/json")
                ]
            )
        }
        let response = try await client.updatePet(
            .init(
                path: .init(petId: 1),
                body: .json(.init(name: "Fluffz"))
            )
        )
        guard case .noContent = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testUpdatePet_204_withoutBody() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "updatePet")
            XCTAssertEqual(request.path, "/pets/1")
            XCTAssertNil(request.query)
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .patch)
            XCTAssertEqual(
                request.headerFields,
                [
                    .init(name: "accept", value: "application/json")
                ]
            )
            XCTAssertNil(request.body)
            return .init(
                statusCode: 204,
                headerFields: [
                    .init(name: "content-type", value: "application/json")
                ]
            )
        }
        let response = try await client.updatePet(
            .init(
                path: .init(petId: 1)
            )
        )
        guard case .noContent = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testUpdatePet_400() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "updatePet")
            XCTAssertEqual(request.path, "/pets/1")
            XCTAssertNil(request.query)
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .patch)
            XCTAssertEqual(
                request.headerFields,
                [
                    .init(name: "accept", value: "application/json")
                ]
            )
            XCTAssertNil(request.body)
            return .init(
                statusCode: 400,
                headers: [
                    .init(name: "content-type", value: "application/json")
                ],
                encodedBody: #"""
                    {
                      "message" : "Oh no!"
                    }
                    """#
            )
        }
        let response = try await client.updatePet(
            .init(
                path: .init(petId: 1)
            )
        )
        guard case let .badRequest(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case let .json(error):
            XCTAssertEqual(error.message, "Oh no!")
        }
    }

    func testProbe_204() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "probe")
            XCTAssertEqual(request.path, "/probe/")
            XCTAssertNil(request.query)
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(request.headerFields, [])
            XCTAssertNil(request.body)
            return .init(statusCode: 204)
        }
        let response = try await client.probe(.init())
        guard case .noContent = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testProbe_undocumented() async throws {
        transport = .init { request, baseURL, operationID in
            .init(statusCode: 503)
        }
        let response = try await client.probe(.init())
        guard case let .undocumented(statusCode, _) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(statusCode, 503)
    }

    func testUploadAvatarForPet_200() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "uploadAvatarForPet")
            XCTAssertEqual(request.path, "/pets/1/avatar")
            XCTAssertNil(request.query)
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .put)
            XCTAssertEqual(
                request.headerFields,
                [
                    .init(name: "accept", value: "application/octet-stream, application/json, text/plain"),
                    .init(name: "content-type", value: "application/octet-stream"),
                ]
            )
            XCTAssertEqual(request.body?.pretty, Data.abcdString)
            return .init(
                statusCode: 200,
                headers: [
                    .init(name: "content-type", value: "application/octet-stream")
                ],
                encodedBody: Data.efghString
            )
        }
        let response = try await client.uploadAvatarForPet(
            .init(
                path: .init(petId: 1),
                body: .binary(.abcd)
            )
        )
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .binary(let binary):
            XCTAssertEqualStringifiedData(binary, Data.efghString)
        }
    }

    func testUploadAvatarForPet_412() async throws {
        transport = .init { request, baseURL, operationID in
            XCTAssertEqual(operationID, "uploadAvatarForPet")
            XCTAssertEqual(request.path, "/pets/1/avatar")
            XCTAssertNil(request.query)
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .put)
            XCTAssertEqual(
                request.headerFields,
                [
                    .init(name: "accept", value: "application/octet-stream, application/json, text/plain"),
                    .init(name: "content-type", value: "application/octet-stream"),
                ]
            )
            XCTAssertEqual(request.body?.pretty, Data.abcdString)
            return .init(
                statusCode: 412,
                headers: [
                    .init(name: "content-type", value: "application/json")
                ],
                encodedBody: Data.quotedEfghString
            )
        }
        let response = try await client.uploadAvatarForPet(
            .init(
                path: .init(petId: 1),
                body: .binary(.abcd)
            )
        )
        guard case let .preconditionFailed(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .json(let json):
            XCTAssertEqual(json, Data.efghString)
        }
    }

    func testUploadAvatarForPet_500() async throws {
        transport = .init { request, baseURL, operationID in
            return .init(
                statusCode: 500,
                headers: [
                    .init(name: "content-type", value: "text/plain")
                ],
                encodedBody: Data.efghString
            )
        }
        let response = try await client.uploadAvatarForPet(
            .init(
                path: .init(petId: 1),
                body: .binary(.abcd)
            )
        )
        guard case let .internalServerError(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .text(let text):
            XCTAssertEqual(text, Data.efghString)
        }
    }
}
