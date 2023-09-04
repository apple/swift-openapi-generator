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
import HTTPTypes
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

    func testListPets_200() async throws {
        transport = .init { (request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) in
            XCTAssertEqual(operationID, "listPets")
            XCTAssertEqual(request.path, "/pets?limit=24&habitat=water&feeds=herbivore&feeds=carnivore&since=2023-01-18T10%3A04%3A11Z")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(
                request.headerFields,
                [
                    .accept: "application/json",
                    .init("My-Request-UUID")!: "abcd-1234"
                ]
            )
            XCTAssertNil(body)
            return try HTTPResponse(
                statusCode: 200,
                headers: [
                    .contentType: "application/json",
                    .init("my-response-uuid")!: "abcd",
                    .init("my-tracing-header")!: "1234"
                ]
            ).withEncodedBody(
                #"""
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
                    My_hyphen_Request_hyphen_UUID: "abcd-1234"
                )
            )
        )
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(value.headers.My_hyphen_Response_hyphen_UUID, "abcd")
        XCTAssertEqual(value.headers.My_hyphen_Tracing_hyphen_Header, "1234")
        switch value.body {
        case .json(let pets):
            XCTAssertEqual(pets, [.init(id: 1, name: "Fluffz")])
        }
    }

    func testListPets_default() async throws {
        transport = .init { request, body, baseURL, operationID in
            XCTAssertEqual(operationID, "listPets")
            XCTAssertEqual(request.path, "/pets?limit=24")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(
                request.headerFields,
                [
                    .accept: "application/json"
                ]
            )
            XCTAssertNil(body)
            return try HTTPResponse(
                statusCode: 400,
                headers: [
                    .contentType: "application/json"
                ]
            ).withEncodedBody(
                #"""
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
                    me_dollar_sage: "Oh no!",
                    userData: try .init(unvalidatedValue: ["one": 1])
                )
            )
        }
    }

    func testCreatePet_201() async throws {
        transport = .init { request, body, baseURL, operationID in
            XCTAssertEqual(operationID, "createPet")
            XCTAssertEqual(request.path, "/pets")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(
                request.headerFields,
                [
                    .accept: "application/json",
                    .contentType: "application/json; charset=utf-8",
                    .init("X-Extra-Arguments")!: #"{"code":1}"#
                ]
            )
            let bodyString = try await body?.collectAsString(upTo: .max)
            XCTAssertEqual(
                bodyString,
                #"""
                {
                  "name" : "Fluffz"
                }
                """#
            )
            return try HTTPResponse(
                statusCode: 201,
                headers: [
                    .contentType: "application/json; charset=utf-8",
                    .init("x-extra-arguments")!: #"{"code":1}"#,
                ]
            ).withEncodedBody(
                #"""
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
                    X_hyphen_Extra_hyphen_Arguments: .init(code: 1)
                ),
                body: .json(.init(name: "Fluffz"))
            )
        )
        guard case let .created(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(value.headers.X_hyphen_Extra_hyphen_Arguments, .init(code: 1))
        switch value.body {
        case .json(let pets):
            XCTAssertEqual(pets, .init(id: 1, name: "Fluffz"))
        }
    }

//    func testCreatePet_400() async throws {
//        transport = .init { request, baseURL, operationID in
//            .init(
//                statusCode: 400,
//                headers: [
//                    .init(name: "content-type", value: "application/json; charset=utf-8"),
//                    .init(name: "x-reason", value: "bad luck"),
//                ],
//                encodedBody: #"""
//                    {
//                      "code": 1
//                    }
//                    """#
//            )
//        }
//        let response = try await client.createPet(
//            .init(body: .json(.init(name: "Fluffz")))
//        )
//        guard case let .clientError(statusCode, value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        XCTAssertEqual(statusCode, 400)
//        XCTAssertEqual(value.headers.X_hyphen_Reason, "bad luck")
//        switch value.body {
//        case .json(let body):
//            XCTAssertEqual(body, .init(code: 1))
//        }
//    }
//
//    func testUpdatePet_204_withBody() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "updatePet")
//            XCTAssertEqual(request.path, "/pets/1")
//            XCTAssertNil(request.query)
//            XCTAssertEqual(baseURL.absoluteString, "/api")
//            XCTAssertEqual(request.method, .patch)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "accept", value: "application/json"),
//                    .init(name: "content-type", value: "application/json; charset=utf-8"),
//                ]
//            )
//            XCTAssertEqual(
//                request.body?.pretty,
//                #"""
//                {
//                  "name" : "Fluffz"
//                }
//                """#
//            )
//            return .init(
//                statusCode: 204,
//                headerFields: [
//                    .init(name: "content-type", value: "application/json")
//                ]
//            )
//        }
//        let response = try await client.updatePet(
//            .init(
//                path: .init(petId: 1),
//                body: .json(.init(name: "Fluffz"))
//            )
//        )
//        guard case .noContent = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//    }
//
//    func testUpdatePet_204_withoutBody() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "updatePet")
//            XCTAssertEqual(request.path, "/pets/1")
//            XCTAssertNil(request.query)
//            XCTAssertEqual(baseURL.absoluteString, "/api")
//            XCTAssertEqual(request.method, .patch)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "accept", value: "application/json")
//                ]
//            )
//            XCTAssertNil(request.body)
//            return .init(
//                statusCode: 204,
//                headerFields: [
//                    .init(name: "content-type", value: "application/json")
//                ]
//            )
//        }
//        let response = try await client.updatePet(
//            .init(
//                path: .init(petId: 1)
//            )
//        )
//        guard case .noContent = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//    }
//
//    func testUpdatePet_400() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "updatePet")
//            XCTAssertEqual(request.path, "/pets/1")
//            XCTAssertNil(request.query)
//            XCTAssertEqual(baseURL.absoluteString, "/api")
//            XCTAssertEqual(request.method, .patch)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "accept", value: "application/json")
//                ]
//            )
//            XCTAssertNil(request.body)
//            return .init(
//                statusCode: 400,
//                headers: [
//                    .init(name: "content-type", value: "application/json")
//                ],
//                encodedBody: #"""
//                    {
//                      "message" : "Oh no!"
//                    }
//                    """#
//            )
//        }
//        let response = try await client.updatePet(
//            .init(
//                path: .init(petId: 1)
//            )
//        )
//        guard case let .badRequest(value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        switch value.body {
//        case let .json(error):
//            XCTAssertEqual(error.message, "Oh no!")
//        }
//    }
//
//    func testGetStats_200_json() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "getStats")
//            XCTAssertEqual(request.path, "/pets/stats")
//            XCTAssertEqual(request.method, .get)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "accept", value: "application/json, text/plain, application/octet-stream")
//                ]
//            )
//            XCTAssertNil(request.body)
//            return .init(
//                statusCode: 200,
//                headers: [
//                    .init(name: "content-type", value: "application/json")
//                ],
//                encodedBody: #"""
//                    {
//                      "count" : 1
//                    }
//                    """#
//            )
//        }
//        let response = try await client.getStats(.init())
//        guard case let .ok(value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        switch value.body {
//        case .json(let stats):
//            XCTAssertEqual(stats, .init(count: 1))
//        default:
//            XCTFail("Unexpected content type")
//        }
//    }
//
//    func testGetStats_200_default_json() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "getStats")
//            XCTAssertEqual(request.path, "/pets/stats")
//            XCTAssertEqual(request.method, .get)
//            XCTAssertNil(request.body)
//            return .init(
//                statusCode: 200,
//                headers: [],
//                encodedBody: #"""
//                    {
//                      "count" : 1
//                    }
//                    """#
//            )
//        }
//        let response = try await client.getStats(.init())
//        guard case let .ok(value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        switch value.body {
//        case .json(let stats):
//            XCTAssertEqual(stats, .init(count: 1))
//        default:
//            XCTFail("Unexpected content type")
//        }
//    }
//
//    func testGetStats_200_text() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "getStats")
//            XCTAssertEqual(request.path, "/pets/stats")
//            XCTAssertEqual(request.method, .get)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "accept", value: "application/json, text/plain, application/octet-stream")
//                ]
//            )
//            XCTAssertNil(request.body)
//            return .init(
//                statusCode: 200,
//                headers: [
//                    .init(name: "content-type", value: "text/plain")
//                ],
//                encodedBody: #"""
//                    count is 1
//                    """#
//            )
//        }
//        let response = try await client.getStats(.init())
//        guard case let .ok(value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        switch value.body {
//        case .plainText(let stats):
//            XCTAssertEqual(stats, "count is 1")
//        default:
//            XCTFail("Unexpected content type")
//        }
//    }
//
//    func testGetStats_200_text_requestedSpecific() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "getStats")
//            XCTAssertEqual(request.path, "/pets/stats")
//            XCTAssertEqual(request.method, .get)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "accept", value: "text/plain, application/json; q=0.500")
//                ]
//            )
//            XCTAssertNil(request.body)
//            return .init(
//                statusCode: 200,
//                headers: [
//                    .init(name: "content-type", value: "text/plain")
//                ],
//                encodedBody: #"""
//                    count is 1
//                    """#
//            )
//        }
//        let response = try await client.getStats(
//            .init(
//                headers: .init(accept: [
//                    .init(contentType: .plainText),
//                    .init(contentType: .json, quality: 0.5),
//                ])
//            )
//        )
//        guard case let .ok(value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        switch value.body {
//        case .plainText(let stats):
//            XCTAssertEqual(stats, "count is 1")
//        default:
//            XCTFail("Unexpected content type")
//        }
//    }
//
//    func testGetStats_200_text_customAccept() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "getStats")
//            XCTAssertEqual(request.path, "/pets/stats")
//            XCTAssertEqual(request.method, .get)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "accept", value: "application/json; q=0.800, text/plain")
//                ]
//            )
//            XCTAssertNil(request.body)
//            return .init(
//                statusCode: 200,
//                headers: [
//                    .init(name: "content-type", value: "text/plain")
//                ],
//                encodedBody: #"""
//                    count is 1
//                    """#
//            )
//        }
//        let response = try await client.getStats(
//            .init(
//                headers: .init(accept: [
//                    .init(contentType: .json, quality: 0.8),
//                    .init(contentType: .plainText),
//                ])
//            )
//        )
//        guard case let .ok(value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        switch value.body {
//        case .plainText(let stats):
//            XCTAssertEqual(stats, "count is 1")
//        default:
//            XCTFail("Unexpected content type")
//        }
//    }
//
//    func testGetStats_200_binary() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "getStats")
//            XCTAssertEqual(request.path, "/pets/stats")
//            XCTAssertEqual(request.method, .get)
//            XCTAssertNil(request.body)
//            return .init(
//                statusCode: 200,
//                headers: [
//                    .init(name: "content-type", value: "application/octet-stream")
//                ],
//                encodedBody: #"""
//                    count_is_1
//                    """#
//            )
//        }
//        let response = try await client.getStats(.init())
//        guard case let .ok(value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        switch value.body {
//        case .binary(let stats):
//            XCTAssertEqual(String(decoding: stats, as: UTF8.self), "count_is_1")
//        default:
//            XCTFail("Unexpected content type")
//        }
//    }
//
//    func testGetStats_200_unexpectedContentType() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "getStats")
//            XCTAssertEqual(request.path, "/pets/stats")
//            XCTAssertEqual(request.method, .get)
//            XCTAssertNil(request.body)
//            return .init(
//                statusCode: 200,
//                headers: [
//                    .init(name: "content-type", value: "foo/bar")
//                ],
//                encodedBody: #"""
//                    count_is_1
//                    """#
//            )
//        }
//        do {
//            _ = try await client.getStats(.init())
//            XCTFail("Should have thrown an error")
//        } catch {}
//    }
//
//    func testPostStats_202_json() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "postStats")
//            XCTAssertEqual(request.path, "/pets/stats")
//            XCTAssertNil(request.query)
//            XCTAssertEqual(baseURL.absoluteString, "/api")
//            XCTAssertEqual(request.method, .post)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "content-type", value: "application/json; charset=utf-8")
//                ]
//            )
//            XCTAssertEqual(
//                request.body?.pretty,
//                #"""
//                {
//                  "count" : 1
//                }
//                """#
//            )
//            return .init(statusCode: 202)
//        }
//        let response = try await client.postStats(
//            .init(body: .json(.init(count: 1)))
//        )
//        guard case .accepted = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//    }
//
//    func testPostStats_202_text() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "postStats")
//            XCTAssertEqual(request.path, "/pets/stats")
//            XCTAssertNil(request.query)
//            XCTAssertEqual(baseURL.absoluteString, "/api")
//            XCTAssertEqual(request.method, .post)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "content-type", value: "text/plain")
//                ]
//            )
//            XCTAssertEqual(
//                request.body?.pretty,
//                #"""
//                count is 1
//                """#
//            )
//            return .init(statusCode: 202)
//        }
//        let response = try await client.postStats(
//            .init(body: .plainText("count is 1"))
//        )
//        guard case .accepted = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//    }
//
//    func testPostStats_202_binary() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "postStats")
//            XCTAssertEqual(request.path, "/pets/stats")
//            XCTAssertNil(request.query)
//            XCTAssertEqual(baseURL.absoluteString, "/api")
//            XCTAssertEqual(request.method, .post)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "content-type", value: "application/octet-stream")
//                ]
//            )
//            XCTAssertEqual(
//                request.body?.pretty,
//                #"""
//                count_is_1
//                """#
//            )
//            return .init(statusCode: 202)
//        }
//        let response = try await client.postStats(
//            .init(body: .binary(Data("count_is_1".utf8)))
//        )
//        guard case .accepted = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//    }
//
//    @available(*, deprecated)
//    func testProbe_204() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "probe")
//            XCTAssertEqual(request.path, "/probe/")
//            XCTAssertNil(request.query)
//            XCTAssertEqual(baseURL.absoluteString, "/api")
//            XCTAssertEqual(request.method, .post)
//            XCTAssertEqual(request.headerFields, [])
//            XCTAssertNil(request.body)
//            return .init(statusCode: 204)
//        }
//        let response = try await client.probe(.init())
//        guard case .noContent = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//    }
//
//    @available(*, deprecated)
//    func testProbe_undocumented() async throws {
//        transport = .init { request, baseURL, operationID in
//            .init(statusCode: 503)
//        }
//        let response = try await client.probe(.init())
//        guard case let .undocumented(statusCode, _) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        XCTAssertEqual(statusCode, 503)
//    }
//
//    func testUploadAvatarForPet_200() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "uploadAvatarForPet")
//            XCTAssertEqual(request.path, "/pets/1/avatar")
//            XCTAssertNil(request.query)
//            XCTAssertEqual(baseURL.absoluteString, "/api")
//            XCTAssertEqual(request.method, .put)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "accept", value: "application/octet-stream, application/json, text/plain"),
//                    .init(name: "content-type", value: "application/octet-stream"),
//                ]
//            )
//            XCTAssertEqual(request.body?.pretty, Data.abcdString)
//            return .init(
//                statusCode: 200,
//                headers: [
//                    .init(name: "content-type", value: "application/octet-stream")
//                ],
//                encodedBody: Data.efghString
//            )
//        }
//        let response = try await client.uploadAvatarForPet(
//            .init(
//                path: .init(petId: 1),
//                body: .binary(.abcd)
//            )
//        )
//        guard case let .ok(value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        switch value.body {
//        case .binary(let binary):
//            XCTAssertEqualStringifiedData(binary, Data.efghString)
//        }
//    }
//
//    func testUploadAvatarForPet_412() async throws {
//        transport = .init { request, baseURL, operationID in
//            XCTAssertEqual(operationID, "uploadAvatarForPet")
//            XCTAssertEqual(request.path, "/pets/1/avatar")
//            XCTAssertNil(request.query)
//            XCTAssertEqual(baseURL.absoluteString, "/api")
//            XCTAssertEqual(request.method, .put)
//            XCTAssertEqual(
//                request.headerFields,
//                [
//                    .init(name: "accept", value: "application/octet-stream, application/json, text/plain"),
//                    .init(name: "content-type", value: "application/octet-stream"),
//                ]
//            )
//            XCTAssertEqual(request.body?.pretty, Data.abcdString)
//            return .init(
//                statusCode: 412,
//                headers: [
//                    .init(name: "content-type", value: "application/json")
//                ],
//                encodedBody: Data.quotedEfghString
//            )
//        }
//        let response = try await client.uploadAvatarForPet(
//            .init(
//                path: .init(petId: 1),
//                body: .binary(.abcd)
//            )
//        )
//        guard case let .preconditionFailed(value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        switch value.body {
//        case .json(let json):
//            XCTAssertEqual(json, Data.efghString)
//        }
//    }
//
//    func testUploadAvatarForPet_500() async throws {
//        transport = .init { request, baseURL, operationID in
//            return .init(
//                statusCode: 500,
//                headers: [
//                    .init(name: "content-type", value: "text/plain")
//                ],
//                encodedBody: Data.efghString
//            )
//        }
//        let response = try await client.uploadAvatarForPet(
//            .init(
//                path: .init(petId: 1),
//                body: .binary(.abcd)
//            )
//        )
//        guard case let .internalServerError(value) = response else {
//            XCTFail("Unexpected response: \(response)")
//            return
//        }
//        switch value.body {
//        case .plainText(let text):
//            XCTAssertEqual(text, Data.efghString)
//        }
//    }
}
