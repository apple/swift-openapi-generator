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

final class Test_Playground: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    func testBidiStreaming() async throws {

        // Server

        struct MyServer: APIProtocol {

            func uploadAvatarForPet(
                _ input: Operations.uploadAvatarForPet.Input
            ) async throws -> Operations.uploadAvatarForPet.Output {

                // The server handler verifies the pet id, sends back
                // the start of the 200 response, and then streams back
                // the body it's receiviving from the request, with every
                // byte being decremented by 1.

                guard input.path.petId == 1 else {
                    return .preconditionFailed(.init(body: .json("bad id")))
                }

                let requestSequence: HTTPBody
                switch input.body {
                case .binary(let body):
                    requestSequence = body
                }

                let responseSequence = requestSequence.map { chunk in
                    print("Server received a chunk: \(String(decoding: chunk, as: UTF8.self))")
                    return chunk.map { $0 - 1 }[...]
                }

                return .ok(
                    .init(
                        body: .binary(
                            .init(
                                sequence: responseSequence,
                                length: requestSequence.length,
                                iterationBehavior: requestSequence.iterationBehavior
                            )
                        )
                    )
                )
            }

            func listPets(_ input: Operations.listPets.Input) async throws -> Operations.listPets.Output {
                fatalError()
            }

            func createPet(_ input: Operations.createPet.Input) async throws -> Operations.createPet.Output {
                fatalError()
            }

            func getStats(_ input: Operations.getStats.Input) async throws -> Operations.getStats.Output {
                fatalError()
            }

            func postStats(_ input: Operations.postStats.Input) async throws -> Operations.postStats.Output {
                fatalError()
            }

            func probe(_ input: Operations.probe.Input) async throws -> Operations.probe.Output {
                fatalError()
            }

            func updatePet(_ input: Operations.updatePet.Input) async throws -> Operations.updatePet.Output {
                fatalError()
            }
        }

        // Client

        // Create the client.
        let client: some APIProtocol = MyServer()

        // Create the request stream.
        let (requestStream, requestContinuation) = AsyncStream.makeStream(
            of: String.self,
            bufferingPolicy: .unbounded
        )

        // Create a request body wrapping the request stream.
        let requestBody: HTTPBody = .init(stream: requestStream, length: .unknown)

        // Send the request, wait for the response.
        // At this point, both the request and response streams are still open.
        let response = try await client.uploadAvatarForPet(
            .init(
                path: .init(petId: 1),
                body: .binary(requestBody)
            )
        )

        // Verify the response status and content type, extract the response stream.
        guard case .ok(let ok) = response, case .binary(let body) = ok.body else {
            XCTFail("Unexpected response")
            return
        }

        let loggedBody = body.map { chunk in
            print("Client received a chunk: \(String(decoding: chunk, as: UTF8.self))")
            return chunk
        }
        var responseIterator = loggedBody.makeAsyncIterator()

        // Send a chunk into the request stream, get one from the response stream
        // verify the contents.
        requestContinuation.yield("hello")
        let firstResponseChunk = try await responseIterator.next()
        XCTAssertEqualStringifiedData(firstResponseChunk, "gdkkn")

        // Send a second chunk.
        requestContinuation.yield("world")
        let secondResponseChunk = try await responseIterator.next()
        XCTAssertEqualStringifiedData(secondResponseChunk, "vnqkc")

        // End the request stream.
        requestContinuation.finish()
        let lastResponseChunk = try await responseIterator.next()
        XCTAssertNil(lastResponseChunk)
    }

    func testServerStreaming() async throws {

        // Server

        struct MyServer: APIProtocol {

            func getStats(
                _ input: Operations.getStats.Input
            ) async throws -> Operations.getStats.Output {

                // The server handler sends back the start of the 200 response,
                // and then sends a few chunks.

                let responseStream = AsyncStream(
                    String.self,
                    bufferingPolicy: .unbounded
                ) { continuation in
                    continuation.yield("hello")
                    continuation.yield("world")
                    continuation.finish()
                }
                let responseBody = HTTPBody(stream: responseStream, length: .unknown)
                return .ok(.init(body: .binary(responseBody)))
            }

            func listPets(_ input: Operations.listPets.Input) async throws -> Operations.listPets.Output {
                fatalError()
            }

            func createPet(_ input: Operations.createPet.Input) async throws -> Operations.createPet.Output {
                fatalError()
            }

            func postStats(_ input: Operations.postStats.Input) async throws -> Operations.postStats.Output {
                fatalError()
            }

            func probe(_ input: Operations.probe.Input) async throws -> Operations.probe.Output {
                fatalError()
            }

            func updatePet(_ input: Operations.updatePet.Input) async throws -> Operations.updatePet.Output {
                fatalError()
            }

            func uploadAvatarForPet(_ input: Operations.uploadAvatarForPet.Input) async throws
                -> Operations.uploadAvatarForPet.Output
            {
                fatalError()
            }
        }

        // Client

        // Create the client.
        let client: some APIProtocol = MyServer()

        // Send the request, wait for the response.
        // At this point, both the request and response streams are still open.
        let response = try await client.getStats(.init())

        // Verify the response status and content type, extract the response stream.
        guard case .ok(let ok) = response, case .binary(let body) = ok.body else {
            XCTFail("Unexpected response")
            return
        }

        let loggedBody = body.map { chunk in
            print("Client received a chunk: \(String(decoding: chunk, as: UTF8.self))")
            return chunk
        }
        var responseIterator = loggedBody.makeAsyncIterator()

        // Get a chunk from the response stream, verify the contents.
        let firstResponseChunk = try await responseIterator.next()
        XCTAssertEqualStringifiedData(firstResponseChunk, "hello")

        // Get a second chunk.
        let secondResponseChunk = try await responseIterator.next()
        XCTAssertEqualStringifiedData(secondResponseChunk, "world")

        // Verify the end of the response stream.
        let lastResponseChunk = try await responseIterator.next()
        XCTAssertNil(lastResponseChunk)
    }

    func testServerStreaming2() async throws {

        // Server

        struct MyServer: APIProtocol {

            func getStats(
                _ input: Operations.getStats.Input
            ) async throws -> Operations.getStats.Output {

                // The server handler sends back the start of the 200 response,
                // and then sends a few chunks.

                actor ChunkProducer {
                    private var chunks: [String] = ["hello", "world"]

                    func produceNext() -> String? {
                        guard !chunks.isEmpty else {
                            return nil
                        }
                        return chunks.removeFirst()
                    }
                }
                let chunkProducer = ChunkProducer()

                let responseStream = AsyncStream<String>(
                    unfolding: {
                        await chunkProducer.produceNext()
                    }
                )

                let responseBody = HTTPBody(stream: responseStream, length: .unknown)
                return .ok(.init(body: .binary(responseBody)))
            }

            func listPets(_ input: Operations.listPets.Input) async throws -> Operations.listPets.Output {
                fatalError()
            }

            func createPet(_ input: Operations.createPet.Input) async throws -> Operations.createPet.Output {
                fatalError()
            }

            func postStats(_ input: Operations.postStats.Input) async throws -> Operations.postStats.Output {
                fatalError()
            }

            func probe(_ input: Operations.probe.Input) async throws -> Operations.probe.Output {
                fatalError()
            }

            func updatePet(_ input: Operations.updatePet.Input) async throws -> Operations.updatePet.Output {
                fatalError()
            }

            func uploadAvatarForPet(_ input: Operations.uploadAvatarForPet.Input) async throws
                -> Operations.uploadAvatarForPet.Output
            {
                fatalError()
            }
        }

        // Client

        // Create the client.
        let client: some APIProtocol = MyServer()

        // Send the request, wait for the response.
        // At this point, both the request and response streams are still open.
        let response = try await client.getStats(.init())

        // Verify the response status and content type, extract the response stream.
        guard case .ok(let ok) = response, case .binary(let body) = ok.body else {
            XCTFail("Unexpected response")
            return
        }

        let loggedBody = body.map { chunk in
            print("Client received a chunk: \(String(decoding: chunk, as: UTF8.self))")
            return chunk
        }
        var responseIterator = loggedBody.makeAsyncIterator()

        // Get a chunk from the response stream, verify the contents.
        let firstResponseChunk = try await responseIterator.next()
        XCTAssertEqualStringifiedData(firstResponseChunk, "hello")

        // Get a second chunk.
        let secondResponseChunk = try await responseIterator.next()
        XCTAssertEqualStringifiedData(secondResponseChunk, "world")

        // Verify the end of the response stream.
        let lastResponseChunk = try await responseIterator.next()
        XCTAssertNil(lastResponseChunk)
    }

}
