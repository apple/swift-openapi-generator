//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftOpenAPIGenerator project authors
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
import ChatGPT
import OpenAPIAsyncHTTPClient

// Declare a handler type, conforming to the generated Swift protocol.
struct Handler: APIProtocol {
    enum Error: Swift.Error { case unimplemented }

    // POST /chant
    func createChant(_ input: Operations.CreateChant.Input) async throws -> Operations.CreateChant.Output {
        // Return 422 (Unprocessable Content) if request was not application/json.
        guard case .json(let body) = input.body else {
            return .undocumented(statusCode: 422, .init())
        }

        // Create a client.
        let client = ChatGPT.Client(
            serverURL: URL(string: "https://api.openai.com/v1")!,
            transport: AsyncHTTPClientTransport(),
            middlewares: [HeaderFieldMiddleware.authTokenFromEnvironment("OPENAI_TOKEN")]
        )

        // Construct the request payload.
        let systemPrompt = """
        Here is some data for the current NBA rosters.

        \(try String(contentsOfFile: "./players.txt", encoding: .utf8))

        Your role is to write fun and witty chants for basketball teams for fans to sing at games.

        The user prompt may consist of any free form text that you should use to identify a team to make the chant.

        The chant should be between four and five paragraphs long and have a title that includes the team name.
        """
        let userInput = body.userInput
        let messages: [ChatGPT.Components.Schemas.ChatCompletionRequestMessage] = [
            .ChatCompletionRequestSystemMessage(.init(content: .case1(systemPrompt), role: .system)),
            .ChatCompletionRequestUserMessage(.init(content: .case1(userInput), role: .user)),
        ]

        // Make the request.
        let chatGPTResponse = try await client.createChatCompletion(
            body: .json(.init(messages: messages, model: .init(value2: .chatgpt4oLatest), stream: true, temperature: 0))
        )

        // Decode SSE stream into an async sequence of typed values.
        typealias ChatGPTPayload = ChatGPT.Components.Schemas.CreateChatCompletionStreamResponse
        let chatGPTStream = try chatGPTResponse.ok.body.textEventStream
            .asDecodedServerSentEventsWithJSONData(of: ChatGPTPayload.self, while: { $0 != HTTPBody.ByteChunk("[DONE]".utf8)})

        // Map the async sequence of ChatGPT values to an async sequence of Proxy values.
        typealias ProxyPayload = ProxyServer.Components.Schemas.ChantMessage
        let proxyStream = chatGPTStream.compactMap { chatGPTPayload -> ProxyPayload? in
            guard let delta = chatGPTPayload.data?.choices.first?.delta.content else { return nil }
            return ProxyPayload(delta: delta)
        }

        // Create a HTTP body by encoding the async sequence as JSON Lines.
        // NOTE: unknown length and single iteration to support arbitrarily long streams.
        let responseBody = HTTPBody(proxyStream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)

        // Return an OK response with the streaming body.
        return .ok(.init(body: .applicationJsonl(responseBody)))
    }
}

// Bootstrap the HTTP server.
let app = try await Vapor.Application.make()
let transport = VaporTransport(routesBuilder: app)
let handler = Handler()
try handler.registerHandlers(on: transport)
try await app.execute()
