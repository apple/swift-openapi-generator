//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftOpenAPIGenerator project authors
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

@main struct HelloWorldURLSessionClient {
    static func main() async throws {
        let client = Client(serverURL: URL(string: "http://localhost:8080/api")!, transport: URLSessionTransport())
        let response = try await client.getGreeting()
        print(try response.ok.body.json.boxed().message)
    }
}
