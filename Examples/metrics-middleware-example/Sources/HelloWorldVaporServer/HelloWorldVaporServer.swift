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
import MetricsMiddleware
import Metrics
import Prometheus

struct Handler: APIProtocol {
    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        let name = input.query.name ?? "Stranger"
        return .ok(.init(body: .json(.init(message: "Hello, \(name)!"))))
    }
}

@main struct HelloWorldVaporServer {
    static func main() async throws {
        let registry = PrometheusCollectorRegistry()
        MetricsSystem.bootstrap(PrometheusMetricsFactory(registry: registry))

        let app = Vapor.Application()

        app.get("metrics") { request in
            var buffer: [UInt8] = []
            buffer.reserveCapacity(1024)
            registry.emit(into: &buffer)
            return String(decoding: buffer, as: UTF8.self)
        }

        let transport = VaporTransport(routesBuilder: app)
        let handler = Handler()
        try handler.registerHandlers(
            on: transport,
            serverURL: URL(string: "/api")!,
            middlewares: [MetricsMiddleware(counterPrefix: "HelloWorldServer")]
        )

        let host = ProcessInfo.processInfo.environment["HOST"] ?? "localhost"
        let port = ProcessInfo.processInfo.environment["PORT"].flatMap(Int.init) ?? 8080
        app.http.server.configuration.address = .hostname(host, port: port)
        try await app.execute()
    }
}
