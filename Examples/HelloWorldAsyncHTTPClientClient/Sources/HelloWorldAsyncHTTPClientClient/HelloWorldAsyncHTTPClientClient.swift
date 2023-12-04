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

@main struct HelloWorldAsyncHTTPClientClient {
    static func main() async throws {
        let client = Client(serverURL: URL(string: "http://localhost:8080/api")!, transport: AsyncHTTPClientTransport())
        let response = try await client.getGreeting()
        print(try response.ok.body.json.message)
    }
}

// TODO: Remove this once 1.0.0 is released with https://github.com/swift-server/swift-openapi-async-http-client/pull/32.
extension AsyncHTTPClientTransport { init() { self.init(configuration: .init()) } }
