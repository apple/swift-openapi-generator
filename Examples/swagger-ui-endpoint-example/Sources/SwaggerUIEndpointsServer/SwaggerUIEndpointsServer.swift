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

struct Handler: APIProtocol {
    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        let name = input.query.name ?? "Stranger"
        return .ok(.init(body: .json(.init(message: "Hello, \(name)!"))))
    }
}

@main struct SwaggerUIEndpointsServer {
    static func main() async throws {
        let app = Vapor.Application()
        let transport = VaporTransport(routesBuilder: app)

        // Register the handlers generated from the OpenAPI document.
        let handler = Handler()
        try handler.registerHandlers(on: transport, serverURL: URL(string: "/api")!)

        // Register the raw file middleware, which serves files from the Public directory, including
        // the openapi.yaml and openapi.html files.
        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

        // Redirect `GET /openapi` to `GET /openapi.html`, for convenience.
        app.get("openapi") { request in request.redirect(to: "openapi.html", redirectType: .permanent) }

        try await app.execute()
    }
}
