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
                configuration: .init(multipartBoundaryGenerator: .constant),
                transport: transport
            )
        }
    }

    /// Setup method called before the invocation of each test method in the class.
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    func testListPets_200() async throws {
        transport = .init { (request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) in
            XCTAssertEqual(operationID, "listPets")
            XCTAssertEqual(
                request.path,
                "/pets?limit=24&habitat=water&feeds=herbivore&feeds=carnivore&since=2023-01-18T10%3A04%3A11Z"
            )
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.headerFields, [.accept: "application/json", .init("My-Request-UUID")!: "abcd-1234"])
            XCTAssertNil(body)
            return try HTTPResponse(
                status: .ok,
                headerFields: [
                    .contentType: "application/json", .init("my-response-uuid")!: "abcd",
                    .init("my-tracing-header")!: "1234",
                ]
            )
            .withEncodedBody(
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
                query: .init(limit: 24, habitat: .water, feeds: [.herbivore, .carnivore], since: .test),
                headers: .init(myRequestUUID: "abcd-1234")
            )
        )
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(value.headers.myResponseUUID, "abcd")
        XCTAssertEqual(value.headers.myTracingHeader, "1234")
        switch value.body {
        case .json(let pets): XCTAssertEqual(pets, [.init(id: 1, name: "Fluffz")])
        }
    }

    func testListPets_default() async throws {
        transport = .init { request, body, baseURL, operationID in
            XCTAssertEqual(operationID, "listPets")
            XCTAssertEqual(request.path, "/pets?limit=24")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.headerFields, [.accept: "application/json"])
            XCTAssertNil(body)
            return try HTTPResponse(status: .badRequest, headerFields: [.contentType: "application/json"])
                .withEncodedBody(
                    #"""
                    {
                      "code": 1,
                      "me$sage": "Oh no!",
                      "userData": {"one" : 1}
                    }
                    """#
                )
        }
        let response = try await client.listPets(.init(query: .init(limit: 24)))
        guard case let .default(statusCode, value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(statusCode, 400)
        switch value.body {
        case .json(let error):
            XCTAssertEqual(
                error,
                .init(code: 1, me_dollar_sage: "Oh no!", userData: try .init(unvalidatedValue: ["one": 1]))
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
                    .accept: "application/json", .contentType: "application/json; charset=utf-8", .contentLength: "23",
                    .init("X-Extra-Arguments")!: #"{"code":1}"#,
                ]
            )
            let bodyString: String
            if let body { bodyString = try await String(collecting: body, upTo: .max) } else { bodyString = "" }
            XCTAssertEqual(
                bodyString,
                #"""
                {
                  "name" : "Fluffz"
                }
                """#
            )
            return try HTTPResponse(
                status: .created,
                headerFields: [
                    .contentType: "application/json; charset=utf-8", .init("x-extra-arguments")!: #"{"code":1}"#,
                ]
            )
            .withEncodedBody(
                #"""
                {
                  "id": 1,
                  "name": "Fluffz"
                }
                """#
            )
        }
        let response = try await client.createPet(
            .init(headers: .init(xExtraArguments: .init(code: 1)), body: .json(.init(name: "Fluffz")))
        )
        guard case let .created(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(value.headers.xExtraArguments, .init(code: 1))
        switch value.body {
        case .json(let pets): XCTAssertEqual(pets, .init(id: 1, name: "Fluffz"))
        }
    }

    func testCreatePet_400() async throws {
        transport = .init { request, body, baseURL, operationID in
            try HTTPResponse(
                status: .badRequest,
                headerFields: [.contentType: "application/json; charset=utf-8", .init("x-reason")!: "bad luck"]
            )
            .withEncodedBody(
                #"""
                {
                  "code": 1
                }
                """#
            )
        }
        let response = try await client.createPet(.init(body: .json(.init(name: "Fluffz"))))
        guard case let .clientError(statusCode, value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(statusCode, 400)
        XCTAssertEqual(value.headers.xReason, "bad luck")
        switch value.body {
        case .json(let body): XCTAssertEqual(body, .init(code: 1))
        }
    }

    func testCreatePetWithForm_204() async throws {
        transport = .init { request, body, baseURL, operationID in
            XCTAssertEqual(operationID, "createPetWithForm")
            XCTAssertEqual(request.path, "/pets/create")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(
                request.headerFields,
                [.contentType: "application/x-www-form-urlencoded", .contentLength: "11"]
            )
            let bodyString: String
            if let body { bodyString = try await String(collecting: body, upTo: .max) } else { bodyString = "" }
            XCTAssertEqual(bodyString, "name=Fluffz")
            return (HTTPResponse(status: .noContent), nil)
        }
        let response = try await client.createPetWithForm(.init(body: .urlEncodedForm(.init(name: "Fluffz"))))
        guard case .noContent = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }

    }

    func testUpdatePet_204_withBody() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "updatePet")
            XCTAssertEqual(request.path, "/pets/1")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .patch)
            XCTAssertEqual(
                request.headerFields,
                [.accept: "application/json", .contentType: "application/json; charset=utf-8", .contentLength: "23"]
            )
            try await XCTAssertEqualStringifiedData(
                requestBody,
                #"""
                {
                  "name" : "Fluffz"
                }
                """#
            )
            return (HTTPResponse(status: .noContent, headerFields: [.contentType: "application/json"]), nil)
        }
        let response = try await client.updatePet(.init(path: .init(petId: 1), body: .json(.init(name: "Fluffz"))))
        guard case .noContent = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testUpdatePet_204_withoutBody() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "updatePet")
            XCTAssertEqual(request.path, "/pets/1")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .patch)
            XCTAssertEqual(request.headerFields, [.accept: "application/json"])
            XCTAssertNil(requestBody)
            return (HTTPResponse(status: .noContent, headerFields: [.contentType: "application/json"]), .init())
        }
        let response = try await client.updatePet(.init(path: .init(petId: 1)))
        guard case .noContent = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testCreatePet_201_withBase64() async throws {
        transport = .init { request, body, baseURL, operationID in
            XCTAssertEqual(operationID, "createPet")
            XCTAssertEqual(request.path, "/pets")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(
                request.headerFields,
                [
                    .accept: "application/json", .contentType: "application/json; charset=utf-8", .contentLength: "112",
                    .init("X-Extra-Arguments")!: #"{"code":1}"#,
                ]
            )
            let bodyString: String
            if let body { bodyString = try await String(collecting: body, upTo: .max) } else { bodyString = "" }
            XCTAssertEqual(
                bodyString,
                #"""
                {
                  "genome" : "IkdBQ1RBVFRDQVRBR0FHVFRUQ0FDQ1RDQUdHQUdBR0FHQUFHVEFBR0NBVFRBR0NBR0NUR0Mi",
                  "name" : "Fluffz"
                }
                """#
            )
            return try HTTPResponse(
                status: .created,
                headerFields: [
                    .contentType: "application/json; charset=utf-8", .init("x-extra-arguments")!: #"{"code":1}"#,
                ]
            )
            .withEncodedBody(
                #"""
                {
                  "id": 1,
                  "genome" : "IkdBQ1RBVFRDQVRBR0FHVFRUQ0FDQ1RDQUdHQUdBR0FHQUFHVEFBR0NBVFRBR0NBR0NUR0Mi",
                  "name": "Fluffz"
                }
                """#
            )
        }
        let response = try await client.createPet(
            .init(
                headers: .init(xExtraArguments: .init(code: 1)),
                body: .json(
                    .init(
                        name: "Fluffz",
                        genome: Base64EncodedData(#""GACTATTCATAGAGTTTCACCTCAGGAGAGAGAAGTAAGCATTAGCAGCTGC""#.utf8)
                    )
                )
            )
        )
        guard case let .created(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(value.headers.xExtraArguments, .init(code: 1))
        switch value.body {
        case .json(let pets):
            XCTAssertEqual(
                pets,
                .init(
                    id: 1,
                    name: "Fluffz",
                    genome: Base64EncodedData(#""GACTATTCATAGAGTTTCACCTCAGGAGAGAGAAGTAAGCATTAGCAGCTGC""#.utf8)
                )
            )
        }
    }

    func testUpdatePet_400() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "updatePet")
            XCTAssertEqual(request.path, "/pets/1")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .patch)
            XCTAssertEqual(request.headerFields, [.accept: "application/json"])
            XCTAssertNil(requestBody)
            return try HTTPResponse(status: .badRequest, headerFields: [.contentType: "application/json"])
                .withEncodedBody(
                    #"""
                    {
                      "message" : "Oh no!"
                    }
                    """#
                )
        }
        let response = try await client.updatePet(.init(path: .init(petId: 1)))
        guard case let .badRequest(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case let .json(error): XCTAssertEqual(error.message, "Oh no!")
        }
    }

    func testGetStats_200_json() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "getStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.headerFields, [.accept: "application/json, text/plain, application/octet-stream"])
            XCTAssertNil(requestBody)
            return try HTTPResponse(status: .ok, headerFields: [.contentType: "application/json"])
                .withEncodedBody(
                    #"""
                    {
                      "count" : 1
                    }
                    """#
                )
        }
        let response = try await client.getStats(.init())
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .json(let stats): XCTAssertEqual(stats, .init(count: 1))
        default: XCTFail("Unexpected content type")
        }
    }

    func testGetStats_200_default_json() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "getStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(request.method, .get)
            XCTAssertNil(requestBody)
            return try HTTPResponse(status: .ok)
                .withEncodedBody(
                    #"""
                    {
                      "count" : 1
                    }
                    """#
                )
        }
        let response = try await client.getStats(.init())
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .json(let stats): XCTAssertEqual(stats, .init(count: 1))
        default: XCTFail("Unexpected content type")
        }
    }

    func testGetStats_200_text() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "getStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.headerFields, [.accept: "application/json, text/plain, application/octet-stream"])
            XCTAssertNil(requestBody)
            return try HTTPResponse(status: .ok, headerFields: [.contentType: "text/plain"])
                .withEncodedBody(
                    #"""
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
        case .plainText(let stats): try await XCTAssertEqualStringifiedData(stats, "count is 1")
        default: XCTFail("Unexpected content type")
        }
    }

    func testGetStats_200_text_requestedSpecific() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "getStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.headerFields, [.accept: "text/plain, application/json; q=0.500"])
            XCTAssertNil(requestBody)
            return try HTTPResponse(status: .ok, headerFields: [.contentType: "text/plain"])
                .withEncodedBody(
                    #"""
                    count is 1
                    """#
                )
        }
        let response = try await client.getStats(
            .init(headers: .init(accept: [.init(contentType: .plainText), .init(contentType: .json, quality: 0.5)]))
        )
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .plainText(let stats): try await XCTAssertEqualStringifiedData(stats, "count is 1")
        default: XCTFail("Unexpected content type")
        }
    }

    func testGetStats_200_text_customAccept() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "getStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.headerFields, [.accept: "application/json; q=0.800, text/plain"])
            XCTAssertNil(requestBody)
            return try HTTPResponse(status: .ok, headerFields: [.contentType: "text/plain"])
                .withEncodedBody(
                    #"""
                    count is 1
                    """#
                )
        }
        let response = try await client.getStats(
            .init(headers: .init(accept: [.init(contentType: .json, quality: 0.8), .init(contentType: .plainText)]))
        )
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .plainText(let stats): try await XCTAssertEqualStringifiedData(stats, "count is 1")
        default: XCTFail("Unexpected content type")
        }
    }

    func testGetStats_200_binary() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "getStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(request.method, .get)
            XCTAssertNil(requestBody)
            return try HTTPResponse(status: .ok, headerFields: [.contentType: "application/octet-stream"])
                .withEncodedBody(
                    #"""
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
        case .binary(let stats): try await XCTAssertEqualStringifiedData(stats, "count_is_1")
        default: XCTFail("Unexpected content type")
        }
    }

    func testGetStats_200_unexpectedContentType() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "getStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(request.method, .get)
            XCTAssertNil(requestBody)
            return try HTTPResponse(status: .ok, headerFields: [.contentType: "foo/bar"])
                .withEncodedBody(
                    #"""
                    count_is_1
                    """#
                )
        }
        do {
            _ = try await client.getStats(.init())
            XCTFail("Should have thrown an error")
        } catch {}
    }

    func testPostStats_202_json() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "postStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(
                request.headerFields,
                [.contentType: "application/json; charset=utf-8", .contentLength: "17"]
            )
            try await XCTAssertEqualStringifiedData(
                requestBody,
                #"""
                {
                  "count" : 1
                }
                """#
            )
            return (.init(status: .accepted), nil)
        }
        let response = try await client.postStats(.init(body: .json(.init(count: 1))))
        guard case .accepted = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testPostStats_202_text() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "postStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(request.headerFields, [.contentType: "text/plain", .contentLength: "10"])
            try await XCTAssertEqualStringifiedData(
                requestBody,
                #"""
                count is 1
                """#
            )
            return (.init(status: .accepted), nil)
        }
        let response = try await client.postStats(.init(body: .plainText("count is 1")))
        guard case .accepted = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testPostStats_202_binary() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "postStats")
            XCTAssertEqual(request.path, "/pets/stats")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(request.headerFields, [.contentType: "application/octet-stream", .contentLength: "10"])
            try await XCTAssertEqualStringifiedData(
                requestBody,
                #"""
                count_is_1
                """#
            )
            return (.init(status: .accepted), nil)
        }
        let response = try await client.postStats(.init(body: .binary("count_is_1")))
        guard case .accepted = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testProbe_204() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "probe")
            XCTAssertEqual(request.path, "/probe/")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(request.headerFields, [:])
            XCTAssertNil(requestBody)
            return (.init(status: .noContent), nil)
        }
        let response = try await client.probe(.init())
        guard case .noContent = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testProbe_undocumented() async throws {
        transport = .init { request, requestBody, baseURL, operationID in (.init(status: .serviceUnavailable), "oh no")
        }
        let response = try await client.probe(.init())
        guard case let .undocumented(statusCode, payload) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        XCTAssertEqual(statusCode, 503)
        XCTAssertEqual(payload.headerFields, [:])
        try await XCTAssertEqualStringifiedData(payload.body, "oh no")
    }

    func testUploadAvatarForPet_200() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "uploadAvatarForPet")
            XCTAssertEqual(request.path, "/pets/1/avatar")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .put)
            XCTAssertEqual(
                request.headerFields,
                [
                    .accept: "application/octet-stream, application/json, text/plain",
                    .contentType: "application/octet-stream", .contentLength: "4",
                ]
            )
            try await XCTAssertEqualStringifiedData(requestBody, Data.abcdString)
            return try HTTPResponse(status: .ok, headerFields: [.contentType: "application/octet-stream"])
                .withEncodedBody(Data.efghString)
        }
        let response = try await client.uploadAvatarForPet(.init(path: .init(petId: 1), body: .binary(.init(.abcd))))
        guard case let .ok(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .binary(let binary): try await XCTAssertEqualStringifiedData(binary, Data.efghString)
        }
    }

    func testUploadAvatarForPet_412() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "uploadAvatarForPet")
            XCTAssertEqual(request.path, "/pets/1/avatar")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .put)
            XCTAssertEqual(
                request.headerFields,
                [
                    .accept: "application/octet-stream, application/json, text/plain",
                    .contentType: "application/octet-stream", .contentLength: "4",
                ]
            )
            try await XCTAssertEqualStringifiedData(requestBody, Data.abcdString)
            return try HTTPResponse(status: .preconditionFailed, headerFields: [.contentType: "application/json"])
                .withEncodedBody(Data.quotedEfghString)
        }
        let response = try await client.uploadAvatarForPet(.init(path: .init(petId: 1), body: .binary(.init(.abcd))))
        guard case let .preconditionFailed(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .json(let json): XCTAssertEqual(json, Data.efghString)
        }
    }

    func testUploadAvatarForPet_500() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            try HTTPResponse(status: .internalServerError, headerFields: [.contentType: "text/plain"])
                .withEncodedBody(Data.efghString)
        }
        let response = try await client.uploadAvatarForPet(.init(path: .init(petId: 1), body: .binary(.init(.abcd))))
        guard case let .internalServerError(value) = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
        switch value.body {
        case .plainText(let text): try await XCTAssertEqualStringifiedData(text, Data.efghString)
        }
    }

    func testMultipartUploadTyped_202() async throws {
        transport = .init { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "multipartUploadTyped")
            XCTAssertEqual(request.path, "/pets/multipart-typed")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(
                request.headerFields,
                [.contentType: "multipart/form-data; boundary=__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__"]
            )
            try await XCTAssertEqualData(requestBody, Data.multipartTypedBodyAsSlice)
            return (.init(status: .accepted), nil)
        }
        let parts: MultipartBody<Components.RequestBodies.MultipartUploadTypedRequest.MultipartFormPayload> = [
            .log(
                .init(
                    payload: .init(
                        headers: .init(xLogType: .unstructured),
                        body: .init("here be logs!\nand more lines\nwheee\n")
                    ),
                    filename: "process.log"
                )
            ), .keyword(.init(payload: .init(body: "fun"), filename: "fun.stuff")),
            .undocumented(.init(name: "foobar", filename: "barfoo.txt", headerFields: .init(), body: .init())),
            .metadata(.init(payload: .init(body: .init(createdAt: Date.test)))),
            .keyword(.init(payload: .init(body: "joy"))),
        ]
        let response = try await client.multipartUploadTyped(.init(body: .multipartForm(parts)))
        guard case .accepted = response else {
            XCTFail("Unexpected response: \(response)")
            return
        }
    }

    func testMultipartDownloadTyped_200() async throws {
        transport = .init(callHandler: { request, requestBody, baseURL, operationID in
            XCTAssertEqual(operationID, "multipartDownloadTyped")
            XCTAssertEqual(request.path, "/pets/multipart-typed")
            XCTAssertEqual(baseURL.absoluteString, "/api")
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.headerFields, [.accept: "multipart/form-data"])
            let stream = AsyncStream<ArraySlice<UInt8>> { continuation in
                let bytes = Data.multipartTypedBodyAsSlice
                continuation.yield(ArraySlice(bytes))
                continuation.finish()
            }
            let body: HTTPBody = .init(stream, length: .unknown)
            return (
                .init(
                    status: .ok,
                    headerFields: [.contentType: "multipart/form-data; boundary=__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__"]
                ), body
            )
        })
        let response = try await client.multipartDownloadTyped()
        let responseMultipart = try response.ok.body.multipartForm

        var iterator = responseMultipart.makeAsyncIterator()
        do {
            let part = try await iterator.next()!
            guard case .log(let log) = part else {
                XCTFail("Unexpected part")
                return
            }
            XCTAssertEqual(log.filename, "process.log")
            XCTAssertEqual(log.payload.headers, .init(xLogType: .unstructured))
            try await XCTAssertEqualData(log.payload.body, "here be logs!\nand more lines\nwheee\n".utf8)
        }
        do {
            let part = try await iterator.next()!
            guard case .keyword(let keyword) = part else {
                XCTFail("Unexpected part")
                return
            }
            XCTAssertEqual(keyword.filename, "fun.stuff")
            try await XCTAssertEqualData(keyword.payload.body, "fun".utf8)
        }
        do {
            let part = try await iterator.next()!
            guard case .undocumented(let undocumented) = part else {
                XCTFail("Unexpected part")
                return
            }
            XCTAssertEqual(
                undocumented.headerFields,
                [.contentDisposition: #"form-data; filename="barfoo.txt"; name="foobar""#, .contentLength: "0"]
            )
            XCTAssertEqual(undocumented.name, "foobar")
            XCTAssertEqual(undocumented.filename, "barfoo.txt")
            try await XCTAssertEqualData(undocumented.body, [])
        }
        do {
            let part = try await iterator.next()!
            guard case .metadata(let metadata) = part else {
                XCTFail("Unexpected part")
                return
            }
            XCTAssertNil(metadata.filename)
            XCTAssertEqual(metadata.payload.body, .init(createdAt: .test))
        }
        do {
            let part = try await iterator.next()!
            guard case .keyword(let keyword) = part else {
                XCTFail("Unexpected part")
                return
            }
            XCTAssertNil(keyword.filename)
            try await XCTAssertEqualData(keyword.payload.body, "joy".utf8)
        }
        do {
            let part = try await iterator.next()
            XCTAssertNil(part)
        }
    }
}
