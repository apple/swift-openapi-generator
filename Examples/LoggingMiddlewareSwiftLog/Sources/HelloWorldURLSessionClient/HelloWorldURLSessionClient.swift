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
import Logging

@main struct HelloWorldURLSessionClient {
    static func main() async throws {
        var logger = Logger(label: "HelloWorldURLSessionClient")
        logger.logLevel = .debug
        let client = Client(
            serverURL: URL(string: "http://localhost:8080/api")!,
            transport: URLSessionTransport(),
            middlewares: [LoggingMiddleware(logger: logger, bodyLoggingConfiguration: .upTo(maxBytes: 1024))]
        )
        let response = try await client.getGreeting()
        print(try response.ok.body.json.message)
    }
}
