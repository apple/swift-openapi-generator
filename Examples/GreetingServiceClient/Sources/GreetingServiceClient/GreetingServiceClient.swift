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

@main
struct GreetingServiceClient {

    static func main() async throws {
        // Create an instance of the generated client type.
        let client: APIProtocol = Client(
            // Server.server1() is generated, derived from the server URL in the OpenAPI document.
            serverURL: try Servers.server1(),
            // URLSessionTransport conforms to ClientTransport and is provided by a separate package.
            transport: URLSessionTransport()
        )

        // Make an API call using generated type-safe Operations.getGreeting.Input.
        let response = try await client.getGreeting(.init(query: .init(name: "Jane")))

        // Operations.getGreeting.Output is an enum that models all the documented responses.
        switch response {
        case .ok(let response):
            // The response body is also an enum value that models all the documented content-types.
            switch response.body {
            case .json(let greeting):
                // The associated enum value is a generated value type derived from the OpenAPI document.
                print(greeting.message)
            }
        // In the event the server responds with something that isn't in its documented API.
        case .undocumented(statusCode: let statusCode, let undocumentedPayload):
            print("Undocumented response \(statusCode) from server: \(undocumentedPayload).")
        }

        // Use shorthand APIs to get an expected response or otherwise throw a runtime error.
        print(try await client.getGreeting().ok.body.json.message)
        //                     ^             ^       ^
        //                     |             |       `- Throws if body did not parse as documented JSON.
        //                     |             |
        //                     |             `- Throws if HTTP response is not 200 (OK).
        //                     |
        //                     `- Throws if there is an error making the API call.
    }
}
