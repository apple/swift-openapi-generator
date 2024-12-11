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
import Foundation

struct Handler: APIProtocol {
    private let storage: StreamStorage = .init()
    func getGreetingsStream(_ input: Operations.getGreetingsStream.Input) async throws
        -> Operations.getGreetingsStream.Output
    {
        let eventStream = await self.storage.makeStream(input: input)
        /// To keep it simple, using JSON Lines, as it most straightforward and easy way to have streams.
        /// For SSE and JSON Sequences cases please check `event-streams-server-example`.
        let responseBody = Operations.getGreetingsStream.Output.Ok.Body.application_jsonl(
            .init(eventStream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
        )
        return .ok(.init(body: responseBody))
    }
}

@main struct BidirectionalEventStreamsServer {
    static func main() async throws {
        let app = try await Vapor.Application.make()
        let transport = VaporTransport(routesBuilder: app)
        let handler = Handler()
        try handler.registerHandlers(on: transport, serverURL: URL(string: "/api")!)
        try await app.execute()
    }
}
