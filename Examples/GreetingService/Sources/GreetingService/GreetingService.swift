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

// User provides a type that adopts `APIProtocol` (a generated protocol).
struct Handler: APIProtocol {

    // This function is a protocol requirement, derived from the operation in the OpenAPI document.
    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        // Extract the query parameter from the input, using generated type-safe property.
        let name = input.query.name ?? "Stranger"

        // Return a OK response (HTTP status 200) with a JSON body, using a type-safe output.
        return .ok(.init(body: .json(.init(message: "Hello, \(name)!"))))
    }
}

@main struct Main {
    /// The entry point of the program.
    ///
    /// This is where the execution of the program begins. Any code you want to run
    /// when the program starts should be placed within this method.
    ///
    /// Example:
    /// ```
    /// public static func main() {
    ///     print("Hello, World!")
    /// }
    /// ```
    /// - Throws: An error of type `Error` if there's an issue creating or running the Vapor application.
    public static func main() async throws {
        // Create a Vapor application.
        let app = Vapor.Application()

        // Create a ServerTransport using the Vapor application.
        let transport = VaporTransport(routesBuilder: app)

        // Create an instance of the handler type that conforms the generated APIProtocol.
        let handler = Handler()

        // Call the generated protocol function on the handler to configure the Vapor application.
        try handler.registerHandlers(on: transport, serverURL: Servers.server2())

        // Start the Vapor application, in the same way as if it was manually configured.
        try await app.execute()
    }
}
