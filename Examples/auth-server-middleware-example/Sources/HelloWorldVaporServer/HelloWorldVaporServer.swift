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
import OpenAPIVapor
import Vapor
import AuthenticationServerMiddleware

struct Handler: APIProtocol {
    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        // Extract the authenticated user, if present.
        // If unauthenticated, return the 401 HTTP status code.
        // Note that the 401 is defined in the OpenAPI document, allowing the client
        // to easily detect this condition and provide the correct authentication credentails
        // on the next request.
        guard let user = AuthenticationServerMiddleware.User.current else { return .unauthorized(.init()) }
        let name = input.query.name ?? "Stranger"
        // Include the name of the authenticated user in the greeting.
        return .ok(.init(body: .json(.init(message: "Hello, \(name)! (Requested by: \(user.name))"))))
    }
}

@main struct HelloWorldVaporServer {
    static func main() async throws {
        let app = Vapor.Application()
        let transport = VaporTransport(routesBuilder: app)
        let handler = Handler()
        try handler.registerHandlers(
            on: transport,
            serverURL: URL(string: "/api")!,
            middlewares: [
                AuthenticationServerMiddleware(authenticate: { stringValue in
                    // Warning: this is an overly simplified authentication strategy, checking
                    // for well-known tokens.
                    //
                    // In your project, here you would likely call out to a library that performs
                    // a cryptographic validation, or similar.
                    //
                    // The code is for illustrative purposes only and should not be used directly.
                    switch stringValue {
                    case "token_for_Frank":
                        // A known user authenticated.
                        return .init(name: "Frank")
                    default:
                        // Unknown credentials, no authenticated user.
                        return nil
                    }
                })
            ]
        )
        try await app.execute()
    }
}
