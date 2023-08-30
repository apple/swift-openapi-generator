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

    func testListPets_200() async throws {
        client = .init(
            listPetsBlock: { input in
                XCTAssertEqual(input.query.limit, 24)
                XCTAssertEqual(input.query.habitat, .water)
                XCTAssertEqual(input.query.since, .test)
                XCTAssertEqual(input.query.feeds, [.carnivore, .herbivore])
                XCTAssertEqual(input.headers.My_Request_UUID, "abcd-1234")
                XCTAssertNil(input.body)
                return .ok(
                    .init(
                        headers: .init(
                            My_Response_UUID: "abcd",
                            My_Tracing_Header: "1234"
                        ),
                        body: .json([
                            .init(id: 1, name: "Fluffz")
                        ])
                    )
                )
            }
        )
        let response = try await server.listPets(
            .init(
                path: "/api/pets",
                query: "limit=24&habitat=water&feeds=carnivore&feeds=herbivore&since=\(Date.testString)",
                method: .get,
                headerFields: [
                    .init(name: "My-Request-UUID", value: "abcd-1234")
                ]
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .init(name: "My-Response-UUID", value: "abcd"),
                .init(name: "My-Tracing-Header", value: "1234"),
                .init(name: "content-type", value: "application/json; charset=utf-8"),
            ]
        )
        let bodyString = String(decoding: response.body, as: UTF8.self)
        XCTAssertEqual(
            bodyString,
            #"""
            [
              {
                "id" : 1,
                "name" : "Fluffz"
              }
            ]
            """#
        )
    }

    func testListPets_default() async throws {
        client = .init(
            listPetsBlock: { input in
                return .default(
                    statusCode: 400,
                    .init(body: .json(.init(code: 1, me_sage: "Oh no!")))
                )
            }
        )
        let response = try await server.listPets(
            .init(
                path: "/api/pets",
                method: .get
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 400)
        XCTAssertEqual(
            response.headerFields,
            [
                .init(name: "content-type", value: "application/json; charset=utf-8")
            ]
        )
        let bodyString = String(decoding: response.body, as: UTF8.self)
        XCTAssertEqual(
            bodyString,
            #"""
            {
              "code" : 1,
              "me$sage" : "Oh no!"
            }
            """#
        )
    }

    func testCreatePet_201() async throws {
        client = .init(
            createPetBlock: { input in
                XCTAssertEqual(input.headers.X_Extra_Arguments, .init(code: 1))
                guard case let .json(createPet) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqual(createPet, .init(name: "Fluffz"))
                return .created(
                    .init(
                        headers: .init(
                            X_Extra_Arguments: .init(code: 1)
                        ),
                        body: .json(
                            .init(id: 1, name: "Fluffz")
                        )
                    )
                )
            }
        )
        let response = try await server.createPet(
            .init(
                path: "/api/pets",
                method: .post,
                headerFields: [
                    .init(name: "x-extra-arguments", value: #"{"code":1}"#),
                    .init(name: "content-type", value: "application/json; charset=utf-8"),
                ],
                encodedBody: #"""
                    {
                      "name" : "Fluffz"
                    }
                    """#
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 201)
        XCTAssertEqual(
            response.headerFields,
            [
                .init(name: "X-Extra-Arguments", value: #"{"code":1}"#),
                .init(name: "content-type", value: "application/json; charset=utf-8"),
            ]
        )
        let bodyString = String(decoding: response.body, as: UTF8.self)
        XCTAssertEqual(
            bodyString,
            #"""
            {
              "id" : 1,
              "name" : "Fluffz"
            }
            """#
        )
    }

    func testCreatePet_400() async throws {
        client = .init(
            createPetBlock: { input in
                .clientError(
                    statusCode: 400,
                    .init(
                        headers: .init(
                            X_Reason: "bad luck"
                        ),
                        body: .json(
                            .init(code: 1)
                        )
                    )
                )
            }
        )
        let response = try await server.createPet(
            .init(
                path: "/api/pets",
                method: .post,
                headerFields: [
                    .init(name: "content-type", value: "application/json; charset=utf-8")
                ],
                encodedBody: #"""
                    {
                      "name" : "Fluffz"
                    }
                    """#
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 400)
        XCTAssertEqual(
            response.headerFields,
            [
                .init(name: "X-Reason", value: "bad%20luck"),
                .init(name: "content-type", value: "application/json; charset=utf-8"),
            ]
        )
        let bodyString = String(decoding: response.body, as: UTF8.self)
        XCTAssertEqual(
            bodyString,
            #"""
            {
              "code" : 1
            }
            """#
        )
    }

    func testCreatePet_withIncorrectContentType() async throws {
        client = .init(
            createPetBlock: { input in
                XCTFail("The handler should not have been called")
                fatalError("Unreachable")
            }
        )
        do {
            _ = try await server.createPet(
                .init(
                    path: "/api/pets",
                    method: .post,
                    headerFields: [
                        .init(name: "x-extra-arguments", value: #"{"code":1}"#),
                        .init(name: "content-type", value: "text/plain; charset=utf-8"),
                    ],
                    encodedBody: #"""
                        {
                          "name" : "Fluffz"
                        }
                        """#
                ),
                .init()
            )
            XCTFail("The method should have thrown an error.")
        } catch {}
    }

    func testUpdatePet_204_withBody() async throws {
        client = .init(
            updatePetBlock: { input in
                XCTAssertEqual(input.path.petId, 1)
                guard let body = input.body else {
                    throw TestError.unexpectedMissingRequestBody
                }
                guard case let .json(updatePet) = body else {
                    throw TestError.unexpectedValue(body)
                }
                XCTAssertEqual(updatePet, .init(name: "Fluffz"))
                return .noContent(.init())
            }
        )
        let response = try await server.updatePet(
            .init(
                path: "/api/pets/1",
                method: .patch,
                headerFields: [
                    .init(name: "accept", value: "application/json"),
                    .init(name: "content-type", value: "application/json"),
                ],
                encodedBody: #"""
                    {
                      "name" : "Fluffz"
                    }
                    """#
            ),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.statusCode, 204)
        XCTAssertEqual(response.headerFields, [])
    }

    func testUpdatePet_204_withBody_default_json() async throws {
        client = .init(
            updatePetBlock: { input in
                XCTAssertEqual(input.path.petId, 1)
                guard let body = input.body else {
                    throw TestError.unexpectedMissingRequestBody
                }
                guard case let .json(updatePet) = body else {
                    throw TestError.unexpectedValue(body)
                }
                XCTAssertEqual(updatePet, .init(name: "Fluffz"))
                return .noContent(.init())
            }
        )
        let response = try await server.updatePet(
            .init(
                path: "/api/pets/1",
                method: .patch,
                headerFields: [],
                encodedBody: #"""
                    {
                      "name" : "Fluffz"
                    }
                    """#
            ),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.statusCode, 204)
        XCTAssertEqual(response.headerFields, [])
    }

    func testUpdatePet_204_withoutBody() async throws {
        client = .init(
            updatePetBlock: { input in
                XCTAssertEqual(input.path.petId, 1)
                XCTAssertNil(input.body)
                return .noContent(.init())
            }
        )
        let response = try await server.updatePet(
            .init(
                path: "/api/pets/1",
                method: .patch
            ),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.statusCode, 204)
        XCTAssertEqual(response.headerFields, [])
    }

    func testUpdatePet_400() async throws {
        client = .init(
            updatePetBlock: { input in
                XCTAssertEqual(input.path.petId, 1)
                XCTAssertNil(input.body)
                return .badRequest(.init(body: .json(.init(message: "Oh no!"))))
            }
        )
        let response = try await server.updatePet(
            .init(
                path: "/api/pets/1",
                method: .patch
            ),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.statusCode, 400)
        XCTAssertEqual(
            response.headerFields,
            [
                .init(name: "content-type", value: "application/json; charset=utf-8")
            ]
        )
        XCTAssertEqualStringifiedData(
            response.body,
            #"""
            {
              "message" : "Oh no!"
            }
            """#
        )
    }

    func testGetStats_200_json() async throws {
        client = .init(
            getStatsBlock: { input in
                return .ok(.init(body: .json(.init(count: 1))))
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
                .init(name: "content-type", value: "application/json; charset=utf-8")
            ]
        )
        XCTAssertEqualStringifiedData(
            response.body,
            #"""
            {
              "count" : 1
            }
            """#
        )
    }

    func testGetStats_200_unexpectedAccept() async throws {
        client = .init(
            getStatsBlock: { input in
                return .ok(.init(body: .json(.init(count: 1))))
            }
        )
        do {
            _ = try await server.getStats(
                .init(
                    path: "/api/pets/stats",
                    method: .patch,
                    headerFields: [
                        .init(name: "accept", value: "foo/bar")
                    ]
                ),
                .init()
            )
            XCTFail("Should have thrown an error.")
        } catch {}
    }

    func testPostStats_202_json() async throws {
        client = .init(
            postStatsBlock: { input in
                guard case let .json(stats) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqual(stats, .init(count: 1))
                return .accepted(.init())
            }
        )
        let response = try await server.postStats(
            .init(
                path: "/api/pets/stats",
                method: .post,
                headerFields: [
                    .init(name: "content-type", value: "application/json; charset=utf-8")
                ],
                encodedBody: #"""
                    {
                      "count" : 1
                    }
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

    func testPostStats_202_default_json() async throws {
        client = .init(
            postStatsBlock: { input in
                guard case let .json(stats) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqual(stats, .init(count: 1))
                return .accepted(.init())
            }
        )
        let response = try await server.postStats(
            .init(
                path: "/api/pets/stats",
                method: .post,
                headerFields: [],
                encodedBody: #"""
                    {
                      "count" : 1
                    }
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

    func testProbe_204() async throws {
        client = .init(
            probeBlock: { input in
                XCTAssertNil(input.body)
                return .noContent(.init())
            }
        )
        let response = try await server.probe(
            .init(
                path: "/api/probe",
                method: .post
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 204)
        XCTAssertEqual(response.headerFields, [])
        XCTAssertEqual(response.body, .init())
    }

    func testProbe_undocumented() async throws {
        client = .init(
            probeBlock: { input in
                .undocumented(statusCode: 503, .init())
            }
        )
        let response = try await server.probe(
            .init(
                path: "/api/probe",
                method: .post
            ),
            .init()
        )
        XCTAssertEqual(response.statusCode, 503)
        XCTAssertEqual(response.headerFields, [])
        XCTAssertEqual(response.body, .init())
    }

    func testUploadAvatarForPet_200() async throws {
        client = .init(
            uploadAvatarForPetBlock: { input in
                guard case let .binary(avatar) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqualStringifiedData(avatar, Data.abcdString)
                return .ok(.init(body: .binary(.efgh)))
            }
        )
        let response = try await server.uploadAvatarForPet(
            .init(
                path: "/api/pets/1/avatar",
                method: .put,
                headerFields: [
                    .init(name: "accept", value: "application/octet-stream, application/json, text/plain"),
                    .init(name: "content-type", value: "application/octet-stream"),
                ],
                encodedBody: Data.abcdString
            ),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
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
            Data.efghString
        )
    }

    func testUploadAvatarForPet_412() async throws {
        client = .init(
            uploadAvatarForPetBlock: { input in
                guard case let .binary(avatar) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqualStringifiedData(avatar, Data.abcdString)
                return .preconditionFailed(.init(body: .json(Data.efghString)))
            }
        )
        let response = try await server.uploadAvatarForPet(
            .init(
                path: "/api/pets/1/avatar",
                method: .put,
                headerFields: [
                    .init(name: "accept", value: "application/octet-stream, application/json, text/plain"),
                    .init(name: "content-type", value: "application/octet-stream"),
                ],
                encodedBody: Data.abcdString
            ),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.statusCode, 412)
        XCTAssertEqual(
            response.headerFields,
            [
                .init(name: "content-type", value: "application/json; charset=utf-8")
            ]
        )
        XCTAssertEqualStringifiedData(
            response.body,
            Data.quotedEfghString
        )
    }

    func testUploadAvatarForPet_500() async throws {
        client = .init(
            uploadAvatarForPetBlock: { input in
                guard case let .binary(avatar) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqualStringifiedData(avatar, Data.abcdString)
                return .internalServerError(.init(body: .text(Data.efghString)))
            }
        )
        let response = try await server.uploadAvatarForPet(
            .init(
                path: "/api/pets/1/avatar",
                method: .put,
                headerFields: [
                    .init(name: "accept", value: "application/octet-stream, application/json, text/plain"),
                    .init(name: "content-type", value: "application/octet-stream"),
                ],
                encodedBody: Data.abcdString
            ),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.statusCode, 500)
        XCTAssertEqual(
            response.headerFields,
            [
                .init(name: "content-type", value: "text/plain")
            ]
        )
        XCTAssertEqualStringifiedData(
            response.body,
            Data.efghString
        )
    }

}
