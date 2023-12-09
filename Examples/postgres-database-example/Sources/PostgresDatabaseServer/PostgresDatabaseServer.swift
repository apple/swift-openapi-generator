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
import PostgresNIO
import Vapor

actor Handler: APIProtocol {
    let postgresConnection: PostgresConnection
    let logger: Logger

    init(eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup.singleton) async throws {
        self.logger = Logger(label: "greeting-service")
        self.postgresConnection = try await PostgresConnection.connect(
            on: eventLoopGroup.next(),
            configuration: .init(
                host: "localhost",
                port: 5432,
                username: "test_username",
                password: "test_password",
                database: "test_database",
                tls: .disable
            ),
            id: 1,
            logger: logger
        )
        _ = self.postgresConnection.simpleQuery(
            """
            CREATE TABLE IF NOT EXISTS messages (
                "id" serial primary key,
                "message" text
            );
            """
        )
    }

    deinit { try? self.postgresConnection.close().wait() }

    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        let name = input.query.name ?? "Stranger"
        let greeting = Components.Schemas.Greeting(message: "Hello, \(name)!")
        _ = try await self.postgresConnection.query(
            "INSERT INTO messages (message) VALUES (\(greeting.message))",
            logger: logger
        )
        return .ok(.init(body: .json(greeting)))
    }

    func getCount(_ input: Operations.getCount.Input) async throws -> Operations.getCount.Output {
        let count = try await self.postgresConnection.query("SELECT * FROM messages", logger: logger).collect().count
        return .ok(.init(body: .json(.init(count: count))))
    }

    func reset(_ input: Operations.reset.Input) async throws -> Operations.reset.Output {
        _ = try await self.postgresConnection.query("DELETE FROM messages", logger: logger)
        return .noContent(.init(body: .json(.init())))
    }
}

@main struct HelloWorldVaporServer {
    static func main() async throws {
        let app = Vapor.Application()
        let transport = VaporTransport(routesBuilder: app)
        let handler = try await Handler()
        try handler.registerHandlers(on: transport, serverURL: URL(string: "/api")!)
        try await app.execute()
    }
}
