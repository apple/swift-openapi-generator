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
import OpenAPIURLSession
import Foundation

@main struct EventStreamsClient {
    static func main() async throws {
        let client = Client(serverURL: URL(string: "http://localhost:8080/api")!, transport: URLSessionTransport())
        do {
            print("Fetching greetings using JSON Lines")
            let response = try await client.getGreetingsStream(
                query: .init(name: "Example", count: 3),
                headers: .init(accept: [.init(contentType: .applicationJsonl)])
            )
            let greetingStream = try response.ok.body.applicationJsonl.asDecodedJSONLines(
                of: Components.Schemas.Greeting.self
            )
            for try await greeting in greetingStream { print("Got greeting: \(greeting.message)") }
        }
        do {
            print("Fetching greetings using JSON Sequence")
            let response = try await client.getGreetingsStream(
                query: .init(name: "Example", count: 3),
                headers: .init(accept: [.init(contentType: .applicationJsonSeq)])
            )
            let greetingStream = try response.ok.body.applicationJsonSeq.asDecodedJSONSequence(
                of: Components.Schemas.Greeting.self
            )
            for try await greeting in greetingStream { print("Got greeting: \(greeting.message)") }
        }
        do {
            print("Fetching greetings using Server-sent Events")
            let response = try await client.getGreetingsStream(
                query: .init(name: "Example", count: 3),
                headers: .init(accept: [.init(contentType: .textEventStream)])
            )
            let greetingStream = try response.ok.body.textEventStream.asDecodedServerSentEventsWithJSONData(
                of: Components.Schemas.Greeting.self
            )
            for try await greeting in greetingStream { print("Got greeting: \(greeting.data?.message ?? "<nil>")") }
        }
    }
}
