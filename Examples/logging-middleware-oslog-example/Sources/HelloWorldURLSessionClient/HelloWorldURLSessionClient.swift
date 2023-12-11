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
import OpenAPIURLSession
import Foundation
import LoggingMiddleware

@main struct HelloWorldURLSessionClient {
    static func main() async throws {
        #if canImport(Darwin)
        let client = Client(
            serverURL: URL(string: "http://localhost:8080/api")!,
            transport: URLSessionTransport(),
            middlewares: [LoggingMiddleware(bodyLoggingConfiguration: .upTo(maxBytes: 1024))]
        )
        let response = try await client.getGreeting()
        print(try response.ok.body.json.message)
        #else  //canImport(Darwin)
        print("This example uses OSLog, so is only supported on Apple platforms")
        exit(EXIT_FAILURE)
        #endif  //canImport(Darwin)
    }
}
