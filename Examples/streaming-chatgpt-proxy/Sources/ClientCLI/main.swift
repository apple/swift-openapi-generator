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

// https://github.com/swiftlang/swift/issues/77866
#if canImport(Glibc)
@preconcurrency import Glibc
#endif
import OpenAPIRuntime
import OpenAPIURLSession
import Foundation

// Create a client.
let client = Client(
    serverURL: URL(string: "http://localhost:8080")!,
    transport: URLSessionTransport()
)

let userInput = CommandLine.arguments.dropFirst().first ?? "Any team!"

// Print some placeholder to the console.
setbuf(stdout, nil)  // Don't buffer stdout.
print("🧑‍💼: \(userInput)")
print("---")
print("🤖: ", terminator: "")

// Make the request.
let response = try await client.createChant(
    body: .json(.init(userInput: userInput))
)

// Decode JSON Lines into an async sequence of typed values.
let messages = try response.ok.body.applicationJsonl
    .asDecodedJSONLines(of: Components.Schemas.ChantMessage.self)

for try await message in messages {
    print(message.delta, terminator: "")
}
