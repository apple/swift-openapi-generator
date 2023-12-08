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
import AuthenticationClientMiddleware

@main struct HelloWorldURLSessionClient {
    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count == 2 else {
            print("Requires a token")
            exit(1)
        }
        let client = Client(
            serverURL: URL(string: "http://localhost:8080/api")!,
            transport: URLSessionTransport(),
            middlewares: [AuthenticationMiddleware(authorizationHeaderFieldValue: args[1])]
        )
        let response = try await client.getGreeting()
        switch response {
        case .ok(let okResponse): print(try okResponse.body.json.message)
        case .unauthorized: print("Unauthorized")
        case .undocumented(statusCode: let statusCode, _): print("Undocumented status code: \(statusCode)")
        }
    }
}
