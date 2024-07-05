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
import OpenAPIRuntime
import OpenAPIAsyncHTTPClient
import Foundation

@main struct BidirectionalEventStreamsClient {
    private static let templates: [String] = [
        "Hello, %@!", "Good morning, %@!", "Hi, %@!", "Greetings, %@!", "Hey, %@!", "Hi there, %@!",
        "Good evening, %@!",
    ]
    static func main() async throws {
        let client = Client(serverURL: URL(string: "http://localhost:8080/api")!, transport: AsyncHTTPClientTransport())
        do {
            print("Sending and fetching back greetings using JSON Lines")
            let (stream, continuation) = AsyncStream<Components.Schemas.Greeting>.makeStream()
            /// To keep it simple, using JSON Lines, as it most straightforward and easy way to have streams.
            /// For SSE and JSON Sequences cases please check `event-streams-client-example`.
            let requestBody: Operations.getGreetingsStream.Input.Body = .application_jsonl(
                .init(stream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
            )
            let response = try await client.getGreetingsStream(query: .init(name: "Example"), body: requestBody)
            let greetingStream = try response.ok.body.application_jsonl.asDecodedJSONLines(
                of: Components.Schemas.Greeting.self
            )
            try await withThrowingTaskGroup(of: Void.self) { group in
                // Listen for upcoming messages
                group.addTask {
                    for try await greeting in greetingStream {
                        try Task.checkCancellation()
                        print("Got greeting: \(greeting.message)")
                    }
                }
                // Send messages
                group.addTask {
                    for template in Self.templates {
                        try Task.checkCancellation()
                        continuation.yield(.init(message: template))
                        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    }
                    continuation.finish()
                }
                return try await group.waitForAll()
            }
        }
    }
}
