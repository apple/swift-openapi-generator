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

public struct GreetingServiceClient {

    private let client: any APIProtocol

    public init(transport: any ClientTransport) throws {
        // Create an instance of the generated client type.
        client = Client(
            // Server.server2() is generated, derived from the server URL in the OpenAPI document.
            serverURL: try Servers.server2(),
            transport: transport
        )
    }

    public func invoke() async throws -> String {
        do {
            // Make an API call using generated type-safe Operations.getGreeting.Input.
            let response = try await client.getGreeting(query: .init(name: "Jane"))

            // Operations.getGreeting.Output is an enum that models all the documented responses.
            switch response {
            case .ok(let response):
                // The response body is also an enum value that models all the documented content-types.
                switch response.body {
                case .json(let greeting):
                    // The associated enum value is a generated value type derived from the OpenAPI document.
                    return greeting.message
                }
            // In the event the server responds with something that isn't in its documented API.
            case .undocumented(statusCode: let statusCode, let undocumentedPayload):
                print("Undocumented response \(statusCode) from server: \(undocumentedPayload).")
            }
        }

        do {
            // Alternatively, use shorthand APIs to get an expected response or otherwise throw a runtime error.
            return try await client.getGreeting().ok.body.json.message

            //                      ^             ^       ^
            //                      |             |       `- Throws if body did not parse as documented JSON.
            //                      |             |
            //                      |             `- Throws if HTTP response is not 200 (OK).
            //                      |
            //                      `- Throws if there is an error making the API call.
        }
    }
}
