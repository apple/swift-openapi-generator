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
import OpenAPIHummingbird
import Hummingbird
import Foundation
import Types

struct Handler: APIProtocol {
    func getGreeting(_ input: Operations.GetGreeting.Input) async throws -> Operations.GetGreeting.Output {
        let name = input.query.name ?? "Stranger"
        let message = Components.Schemas.Greeting(message: "Hello, \(name)!")
        return .ok(.init(body: .json(message.boxed())))
    }
}

@main struct HelloWorldHummingbirdServer {
    static func main() async throws {
        let router = Router()
        let handler = Handler()
        try handler.registerHandlers(on: router, serverURL: URL(string: "/api")!)
        let app = Application(router: router, configuration: .init())
        try await app.run()
    }
}
