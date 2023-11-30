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
import OpenAPIHummingbird
import Hummingbird

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
    static func main() throws {
        // Create a Hummingbird application.
        let app = HBApplication()

        // Create a ServerTransport using the Hummingbird application.
        let transport = HBOpenAPITransport(app)

        // Create an instance of the handler type that conforms the generated APIProtocol.
        let handler = Handler()

        // Call the generated protocol function on the handler to configure the Hummingbird application.
        try handler.registerHandlers(on: transport, serverURL: Servers.server2())

        // Start the Hummingbird application, in the same way as if it was manually configured.
        try app.run()
    }
}
