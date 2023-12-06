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

@main struct ContentTypesClient {
    static func main() async throws {
        let client = Client(serverURL: URL(string: "http://localhost:8080/api")!, transport: URLSessionTransport())
        do {
            let response = try await client.getExampleJSON(query: .init(name: "CLI"))
            let greeting = try response.ok.body.json
            print("Received greeting: \(greeting.message)")
        }
        do {
            let message = "Hello, Stranger!"
            let response = try await client.postExampleJSON(body: .json(.init(message: message)))
            _ = try response.accepted
            print("Sent JSON greeting: \(message)")
        }
        do {
            let response = try await client.getExamplePlainText()
            let plainText = try response.ok.body.plainText
            let bufferedText = try await String(collecting: plainText, upTo: 1024)
            print("Received text: \(bufferedText)")
        }
        do {
            let response = try await client.postExamplePlainText(
                body: .plainText(
                    """
                    A snow log.
                    ---
                    [2023-12-24] It snowed.
                    [2023-12-25] It snowed even more.
                    """
                )
            )
            _ = try response.accepted
            print("Sent plain text")
        }
        do {
            // The Accept header field lets the client communicate which response content type it prefers, by giving
            // each content type a "quality" (in other words, a preference), from 0.0 to 1.0, from least to most preferred.
            // However, the server is still in charge of choosing the response content type and uses the Accept header
            // as a hint only.
            //
            // As a client, here we declare that we prefer to receive JSON, with preference 1.0, and our second choice
            // is plain text, with preference 0.8.
            let response = try await client.getExampleMultipleContentTypes(
                headers: .init(accept: [
                    .init(contentType: .json, quality: 1.0), .init(contentType: .plainText, quality: 0.8),
                ])
            )
            let body = try response.ok.body
            switch body {
            case .json(let json): print("Received a JSON greeting with the message: \(json.message)")
            case .plainText(let body):
                let text = try await String(collecting: body, upTo: 1024)
                print("Received a text greeting with the message: \(text)")
            }
        }
        do {
            let response = try await client.postExampleMultipleContentTypes(
                body: .json(.init(message: "Hello, Stranger!"))
            )
            _ = try response.accepted
            print("Sent multiple content types: JSON")
        }
        do {
            let message = "Hello, Stranger!"
            let response = try await client.postExampleURLEncoded(body: .urlEncodedForm(.init(message: message)))
            _ = try response.accepted
            print("Sent URLEncoded greeting: \(message)")
        }
        do {
            let response = try await client.getExampleRawBytes()
            let binary = try response.ok.body.binary
            // Processes each chunk as it comes in, avoids buffering the whole body into memory.
            for try await chunk in binary { print("Received chunk: \(chunk)") }
        }
        do {
            let response = try await client.postExampleRawBytes(body: .binary([0x73, 0x6e, 0x6f, 0x77, 0x0a]))
            _ = try response.accepted
            print("Sent binary")
        }
        do {
            let response = try await client.getExampleMultipart()
            let multipartBody = try response.ok.body.multipartForm
            for try await part in multipartBody {
                switch part {
                case .greetingTemplate(let template):
                    let message = template.payload.body.message
                    print("Received a template message: \(message)")
                case .names(let name):
                    let stringName = try await String(collecting: name.payload.body, upTo: 1024)
                    // Multipart parts can have headers.
                    let locale = name.payload.headers.x_hyphen_name_hyphen_locale ?? "<nil>"
                    print("Received a name: '\(stringName)', header value: '\(locale)'")
                case .undocumented(let part):
                    // Any part with a raw HTTPBody body must have its body consumed before moving on to the next part.
                    let bytes = try await [UInt8](collecting: part.body, upTo: 1024 * 1024)
                    print(
                        "Received an undocumented part with \(part.headerFields.count) headers and \(bytes.count) bytes."
                    )
                }
            }
        }
        do {
            let multipartBody: MultipartBody<Operations.postExampleMultipart.Input.Body.multipartFormPayload> = [
                .greetingTemplate(.init(payload: .init(body: .init(message: "Hello, {name}!")))),
                .names(.init(payload: .init(headers: .init(x_hyphen_name_hyphen_locale: "en_US"), body: "Frank"))),
                .names(.init(payload: .init(body: "Not Frank"))),
            ]
            let response = try await client.postExampleMultipart(body: .multipartForm(multipartBody))
            _ = try response.accepted
            print("Sent multipart")
        }
    }
}
