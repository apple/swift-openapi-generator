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
import OpenAPIVapor
import Vapor

struct Handler: APIProtocol {
    private let storage: StreamStorage = .init()
    func getGreetingsStream(_ input: Operations.getGreetingsStream.Input) async throws
        -> Operations.getGreetingsStream.Output
    {
        let name = input.query.name ?? "Stranger"
        let count = input.query.count ?? 10
        let eventStream = storage.makeStream(name: name, count: count)
        let responseBody: Operations.getGreetingsStream.Output.Ok.Body
        // Default to `application/jsonl`, if no other content type requested through the `Accept` header.
        let chosenContentType = input.headers.accept.sortedByQuality().first ?? .init(contentType: .application_jsonl)
        switch chosenContentType.contentType {
        case .application_jsonl, .other:
            responseBody = .application_jsonl(
                .init(eventStream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
            )
        case .application_json_hyphen_seq:
            responseBody = .application_json_hyphen_seq(
                .init(eventStream.asEncodedJSONSequence(), length: .unknown, iterationBehavior: .single)
            )
        case .text_event_hyphen_stream:
            responseBody = .text_event_hyphen_stream(
                .init(
                    eventStream.map { greeting in
                        ServerSentEventWithJSONData(
                            event: "greeting",
                            data: greeting,
                            id: UUID().uuidString,
                            retry: 10_000
                        )
                    }
                    .asEncodedServerSentEventsWithJSONData(),
                    length: .unknown,
                    iterationBehavior: .single
                )
            )
        }
        return .ok(.init(body: responseBody))
    }
}

@main struct EventStreamsServer {
    static func main() async throws {
        let app = Vapor.Application()
        let transport = VaporTransport(routesBuilder: app)
        let handler = Handler()
        try handler.registerHandlers(on: transport, serverURL: URL(string: "/api")!)
        try await app.execute()
    }
}
