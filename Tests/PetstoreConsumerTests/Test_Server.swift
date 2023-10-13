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
import HTTPTypes

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
                XCTAssertEqual(input.headers.My_hyphen_Request_hyphen_UUID, "abcd-1234")
                return .ok(
                    .init(
                        headers: .init(
                            My_hyphen_Response_hyphen_UUID: "abcd",
                            My_hyphen_Tracing_hyphen_Header: "1234"
                        ),
                        body: .json([
                            .init(id: 1, name: "Fluffz")
                        ])
                    )
                )
            }
        )
        let (response, responseBody) = try await server.listPets(
            .init(
                soar_path: "/api/pets?limit=24&habitat=water&feeds=carnivore&feeds=herbivore&since=\(Date.testString)",
                method: .get,
                headerFields: [
                    .init("My-Request-UUID")!: "abcd-1234"
                ]
            ),
            nil,
            .init()
        )
        XCTAssertEqual(response.status.code, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .init("My-Response-UUID")!: "abcd",
                .init("My-Tracing-Header")!: "1234",
                .contentType: "application/json; charset=utf-8",
            ]
        )
        let bodyString: String
        if let responseBody {
            bodyString = try await String(collecting: responseBody, upTo: .max)
        } else {
            bodyString = ""
        }
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
                    .init(body: .json(.init(code: 1, me_dollar_sage: "Oh no!")))
                )
            }
        )
        let (response, responseBody) = try await server.listPets(
            .init(
                soar_path: "/api/pets",
                method: .get
            ),
            nil,
            .init()
        )
        XCTAssertEqual(response.status.code, 400)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "application/json; charset=utf-8"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
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
                XCTAssertEqual(input.headers.X_hyphen_Extra_hyphen_Arguments, .init(code: 1))
                guard case let .json(createPet) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqual(createPet, .init(name: "Fluffz"))
                return .created(
                    .init(
                        headers: .init(
                            X_hyphen_Extra_hyphen_Arguments: .init(code: 1)
                        ),
                        body: .json(
                            .init(id: 1, name: "Fluffz")
                        )
                    )
                )
            }
        )
        let (response, responseBody) = try await server.createPet(
            .init(
                soar_path: "/api/pets",
                method: .post,
                headerFields: [
                    .init("x-extra-arguments")!: #"{"code":1}"#,
                    .contentType: "application/json; charset=utf-8",
                ]
            ),
            .init(
                #"""
                {
                  "name" : "Fluffz"
                }
                """#
            ),
            .init()
        )
        XCTAssertEqual(response.status.code, 201)
        XCTAssertEqual(
            response.headerFields,
            [
                .init("X-Extra-Arguments")!: #"{"code":1}"#,
                .contentType: "application/json; charset=utf-8",
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
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
                            X_hyphen_Reason: "bad luck"
                        ),
                        body: .json(
                            .init(code: 1)
                        )
                    )
                )
            }
        )
        let (response, responseBody) = try await server.createPet(
            .init(
                soar_path: "/api/pets",
                method: .post,
                headerFields: [
                    .contentType: "application/json; charset=utf-8"
                ]
            ),
            .init(
                #"""
                {
                  "name" : "Fluffz"
                }
                """#
            ),
            .init()
        )
        XCTAssertEqual(response.status.code, 400)
        XCTAssertEqual(
            response.headerFields,
            [
                .init("X-Reason")!: "bad%20luck",
                .contentType: "application/json; charset=utf-8",
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
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
                    soar_path: "/api/pets",
                    method: .post,
                    headerFields: [
                        .init("x-extra-arguments")!: #"{"code":1}"#,
                        .contentType: "text/plain; charset=utf-8",
                    ]
                ),
                .init(
                    #"""
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

    func testCreatePetWithForm_204() async throws {
        client = .init(
            createPetWithFormBlock: { input in
                guard case let .urlEncodedForm(createPet) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqual(createPet, .init(name: "Fluffz"))
                return .noContent(.init())
            }
        )
        let (response, responseBody) = try await server.createPetWithForm(
            .init(
                soar_path: "/api/pets/create",
                method: .post,
                headerFields: [
                    .init("x-extra-arguments")!: #"{"code":1}"#,
                    .contentType: "application/x-www-form-urlencoded",
                ]
            ),
            .init("name=Fluffz"),
            .init()
        )
        XCTAssertEqual(response.status.code, 204)
        XCTAssertNil(responseBody)
        XCTAssertEqual(
            response.headerFields,
            [:]
        )
    }

    func testCreatePet_201_withBase64() async throws {
        client = .init(
            createPetBlock: { input in
                XCTAssertEqual(input.headers.X_hyphen_Extra_hyphen_Arguments, .init(code: 1))
                guard case let .json(createPet) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                XCTAssertEqual(
                    createPet,
                    .init(
                        name: "Fluffz",
                        genome: Base64EncodedData(
                            data: ArraySlice(#""GACTATTCATAGAGTTTCACCTCAGGAGAGAGAAGTAAGCATTAGCAGCTGC""#.utf8)
                        )
                    )
                )
                return .created(
                    .init(
                        headers: .init(
                            X_hyphen_Extra_hyphen_Arguments: .init(code: 1)
                        ),
                        body: .json(
                            .init(id: 1, name: "Fluffz")
                        )
                    )
                )
            }
        )
        let (response, responseBody) = try await server.createPet(
            .init(
                soar_path: "/api/pets",
                method: .post,
                headerFields: [
                    .init("x-extra-arguments")!: #"{"code":1}"#,
                    .contentType: "application/json; charset=utf-8",
                ]
            ),
            .init(
                #"""
                {

                  "genome" : "IkdBQ1RBVFRDQVRBR0FHVFRUQ0FDQ1RDQUdHQUdBR0FHQUFHVEFBR0NBVFRBR0NBR0NUR0Mi",
                  "name" : "Fluffz"
                }
                """#
            ),
            .init()
        )
        XCTAssertEqual(response.status.code, 201)
        XCTAssertEqual(
            response.headerFields,
            [
                .init("X-Extra-Arguments")!: #"{"code":1}"#,
                .contentType: "application/json; charset=utf-8",
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
            #"""
            {
              "id" : 1,
              "name" : "Fluffz"
            }
            """#
        )
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
        let (response, responseBody) = try await server.updatePet(
            .init(
                soar_path: "/api/pets/1",
                method: .patch,
                headerFields: [
                    .accept: "application/json",
                    .contentType: "application/json",
                ]
            ),
            .init(
                #"""
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
        XCTAssertEqual(response.status.code, 204)
        XCTAssertEqual(response.headerFields, [:])
        XCTAssertNil(responseBody)
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
        let (response, responseBody) = try await server.updatePet(
            .init(
                soar_path: "/api/pets/1",
                method: .patch,
                headerFields: [:]
            ),
            .init(
                #"""
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
        XCTAssertEqual(response.status.code, 204)
        XCTAssertEqual(response.headerFields, [:])
        XCTAssertNil(responseBody)
    }

    func testUpdatePet_204_withoutBody() async throws {
        client = .init(
            updatePetBlock: { input in
                XCTAssertEqual(input.path.petId, 1)
                XCTAssertNil(input.body)
                return .noContent(.init())
            }
        )
        let (response, responseBody) = try await server.updatePet(
            .init(
                soar_path: "/api/pets/1",
                method: .patch
            ),
            nil,
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.status.code, 204)
        XCTAssertEqual(response.headerFields, [:])
        XCTAssertNil(responseBody)
    }

    func testUpdatePet_400() async throws {
        client = .init(
            updatePetBlock: { input in
                XCTAssertEqual(input.path.petId, 1)
                XCTAssertNil(input.body)
                return .badRequest(.init(body: .json(.init(message: "Oh no!"))))
            }
        )
        let (response, responseBody) = try await server.updatePet(
            .init(
                soar_path: "/api/pets/1",
                method: .patch
            ),
            nil,
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.status.code, 400)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "application/json; charset=utf-8"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
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
        let (response, responseBody) = try await server.getStats(
            .init(
                soar_path: "/api/pets/stats",
                method: .patch,
                headerFields: [
                    .accept: "application/json, text/plain, application/octet-stream"
                ]
            ),
            nil,
            .init()
        )
        XCTAssertEqual(response.status.code, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "application/json; charset=utf-8"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
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
                    soar_path: "/api/pets/stats",
                    method: .patch,
                    headerFields: [
                        .accept: "foo/bar"
                    ]
                ),
                nil,
                .init()
            )
            XCTFail("Should have thrown an error.")
        } catch {}
    }

    func testGetStats_200_text() async throws {
        client = .init(
            getStatsBlock: { input in
                return .ok(.init(body: .plainText("count is 1")))
            }
        )
        let (response, responseBody) = try await server.getStats(
            .init(
                soar_path: "/api/pets/stats",
                method: .patch,
                headerFields: [
                    .accept: "application/json, text/plain, application/octet-stream"
                ]
            ),
            .init(),
            .init()
        )
        XCTAssertEqual(response.status.code, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "text/plain"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
            #"""
            count is 1
            """#
        )
    }

    func testGetStats_200_streaming_text() async throws {
        client = .init(
            getStatsBlock: { input in
                let body = HTTPBody(
                    AsyncStream { continuation in
                        continuation.yield([72])
                        continuation.yield([69])
                        continuation.yield([76])
                        continuation.yield([76])
                        continuation.yield([79])
                        continuation.finish()
                    },
                    length: .unknown
                )
                return .ok(.init(body: .plainText(body)))
            }
        )
        let (response, responseBody) = try await server.getStats(
            .init(
                soar_path: "/api/pets/stats",
                method: .patch,
                headerFields: [
                    .accept: "application/json, text/plain, application/octet-stream"
                ]
            ),
            .init(),
            .init()
        )
        XCTAssertEqual(response.status.code, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "text/plain"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
            #"""
            HELLO
            """#
        )
    }

    func testGetStats_200_text_requestedSpecific() async throws {
        client = .init(
            getStatsBlock: { input in
                XCTAssertEqual(
                    input.headers.accept,
                    [
                        .init(contentType: .plainText),
                        .init(contentType: .json, quality: 0.5),
                    ]
                )
                return .ok(.init(body: .plainText("count is 1")))
            }
        )
        let (response, responseBody) = try await server.getStats(
            .init(
                soar_path: "/api/pets/stats",
                method: .patch,
                headerFields: [
                    .accept: "text/plain, application/json; q=0.500"
                ]
            ),
            nil,
            .init()
        )
        XCTAssertEqual(response.status.code, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "text/plain"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
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
                        .init(contentType: .json, quality: 0.8),
                        .init(contentType: .plainText),
                    ]
                )
                return .ok(.init(body: .plainText("count is 1")))
            }
        )
        let (response, responseBody) = try await server.getStats(
            .init(
                soar_path: "/api/pets/stats",
                method: .patch,
                headerFields: [
                    .accept: "application/json; q=0.8, text/plain"
                ]
            ),
            nil,
            .init()
        )
        XCTAssertEqual(response.status.code, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "text/plain"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
            #"""
            count is 1
            """#
        )
    }

    func testGetStats_200_binary() async throws {
        client = .init(
            getStatsBlock: { input in
                return .ok(.init(body: .binary("count_is_1")))
            }
        )
        let (response, responseBody) = try await server.getStats(
            .init(
                soar_path: "/api/pets/stats",
                method: .patch,
                headerFields: [
                    .accept: "application/json, text/plain, application/octet-stream"
                ]
            ),
            nil,
            .init()
        )
        XCTAssertEqual(response.status.code, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "application/octet-stream"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
            #"""
            count_is_1
            """#
        )
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
        let (response, responseBody) = try await server.postStats(
            .init(
                soar_path: "/api/pets/stats",
                method: .post,
                headerFields: [
                    .contentType: "application/json; charset=utf-8"
                ]
            ),
            .init(
                #"""
                {
                  "count" : 1
                }
                """#
            ),
            .init()
        )
        XCTAssertEqual(response.status.code, 202)
        XCTAssertEqual(response.headerFields, [:])
        XCTAssertNil(responseBody)
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
        let (response, responseBody) = try await server.postStats(
            .init(
                soar_path: "/api/pets/stats",
                method: .post,
                headerFields: [:]
            ),
            .init(
                #"""
                {
                  "count" : 1
                }
                """#
            ),
            .init()
        )
        XCTAssertEqual(response.status.code, 202)
        XCTAssertEqual(response.headerFields, [:])
        XCTAssertNil(responseBody)
    }

    func testPostStats_202_text() async throws {
        client = .init(
            postStatsBlock: { input in
                guard case let .plainText(stats) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                try await XCTAssertEqualStringifiedData(stats, "count is 1")
                return .accepted(.init())
            }
        )
        let (response, responseBody) = try await server.postStats(
            .init(
                soar_path: "/api/pets/stats",
                method: .post,
                headerFields: [
                    .contentType: "text/plain"
                ]
            ),
            .init(
                #"""
                count is 1
                """#
            ),
            .init()
        )
        XCTAssertEqual(response.status.code, 202)
        XCTAssertEqual(response.headerFields, [:])
        XCTAssertNil(responseBody)
    }

    func testPostStats_202_binary() async throws {
        client = .init(
            postStatsBlock: { input in
                guard case let .binary(stats) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                try await XCTAssertEqualStringifiedData(stats, "count_is_1")
                return .accepted(.init())
            }
        )
        let (response, responseBody) = try await server.postStats(
            .init(
                soar_path: "/api/pets/stats",
                method: .post,
                headerFields: [
                    .contentType: "application/octet-stream"
                ]
            ),
            .init(
                #"""
                count_is_1
                """#
            ),
            .init()
        )
        XCTAssertEqual(response.status.code, 202)
        XCTAssertEqual(response.headerFields, [:])
        XCTAssertNil(responseBody)
    }

    func testProbe_204() async throws {
        client = .init(
            probeBlock: { input in
                return .noContent(.init())
            }
        )
        let (response, responseBody) = try await server.probe(
            .init(
                soar_path: "/api/probe/",
                method: .post
            ),
            nil,
            .init()
        )
        XCTAssertEqual(response.status.code, 204)
        XCTAssertEqual(response.headerFields, [:])
        XCTAssertNil(responseBody)
    }

    func testProbe_undocumented() async throws {
        client = .init(
            probeBlock: { input in
                .undocumented(statusCode: 503, .init())
            }
        )
        let (response, responseBody) = try await server.probe(
            .init(
                soar_path: "/api/probe/",
                method: .post
            ),
            nil,
            .init()
        )
        XCTAssertEqual(response.status.code, 503)
        XCTAssertEqual(response.headerFields, [:])
        XCTAssertNil(responseBody)
    }

    func testUploadAvatarForPet_200_buffered() async throws {
        client = .init(
            uploadAvatarForPetBlock: { input in
                guard case let .binary(avatar) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                try await XCTAssertEqualStringifiedData(avatar, Data.abcdString)
                return .ok(.init(body: .binary(.init(.efgh))))
            }
        )
        let (response, responseBody) = try await server.uploadAvatarForPet(
            .init(
                soar_path: "/api/pets/1/avatar",
                method: .put,
                headerFields: [
                    .accept: "application/octet-stream, application/json, text/plain",
                    .contentType: "application/octet-stream",
                ]
            ),
            .init(Data.abcdString),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.status.code, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "application/octet-stream"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
            Data.efghString
        )
    }

    func testUploadAvatarForPet_200_streaming() async throws {
        actor CollectedChunkSizes {
            private(set) var sizes: [Int] = []
            func record(size: Int) {
                sizes.append(size)
            }
        }
        let chunkSizeCollector = CollectedChunkSizes()
        client = .init(
            uploadAvatarForPetBlock: { input in
                guard case let .binary(avatar) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                let responseSequence = avatar.map { chunk in
                    await chunkSizeCollector.record(size: chunk.count)
                    return chunk
                }
                return .ok(
                    .init(
                        body: .binary(
                            .init(
                                responseSequence,
                                length: avatar.length,
                                iterationBehavior: avatar.iterationBehavior
                            )
                        )
                    )
                )
            }
        )
        let (response, responseBody) = try await server.uploadAvatarForPet(
            .init(
                soar_path: "/api/pets/1/avatar",
                method: .put,
                headerFields: [
                    .accept: "application/octet-stream, application/json, text/plain",
                    .contentType: "application/octet-stream",
                ]
            ),
            .init([97, 98, 99, 100], length: .known(4)),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.status.code, 200)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "application/octet-stream"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
            Data.abcdString
        )
        let sizes = await chunkSizeCollector.sizes
        XCTAssertEqual(sizes, [4])
    }

    func testUploadAvatarForPet_412() async throws {
        client = .init(
            uploadAvatarForPetBlock: { input in
                guard case let .binary(avatar) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                try await XCTAssertEqualStringifiedData(avatar, Data.abcdString)
                return .preconditionFailed(.init(body: .json(Data.efghString)))
            }
        )
        let (response, responseBody) = try await server.uploadAvatarForPet(
            .init(
                soar_path: "/api/pets/1/avatar",
                method: .put,
                headerFields: [
                    .accept: "application/octet-stream, application/json, text/plain",
                    .contentType: "application/octet-stream",
                ]
            ),
            .init(Data.abcdString),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.status.code, 412)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "application/json; charset=utf-8"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
            Data.quotedEfghString
        )
    }

    func testUploadAvatarForPet_500() async throws {
        client = .init(
            uploadAvatarForPetBlock: { input in
                guard case let .binary(avatar) = input.body else {
                    throw TestError.unexpectedValue(input.body)
                }
                try await XCTAssertEqualStringifiedData(avatar, Data.abcdString)
                return .internalServerError(
                    .init(
                        body: .plainText(.init(Data.efghString))
                    )
                )
            }
        )
        let (response, responseBody) = try await server.uploadAvatarForPet(
            .init(
                soar_path: "/api/pets/1/avatar",
                method: .put,
                headerFields: [
                    .accept: "application/octet-stream, application/json, text/plain",
                    .contentType: "application/octet-stream",
                ]
            ),
            .init(Data.abcdString),
            .init(
                pathParameters: [
                    "petId": "1"
                ]
            )
        )
        XCTAssertEqual(response.status.code, 500)
        XCTAssertEqual(
            response.headerFields,
            [
                .contentType: "text/plain"
            ]
        )
        try await XCTAssertEqualStringifiedData(
            responseBody,
            Data.efghString
        )
    }
}
