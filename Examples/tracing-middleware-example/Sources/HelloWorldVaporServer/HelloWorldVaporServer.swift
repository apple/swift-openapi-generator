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
import TracingMiddleware
import Tracing
import OpenTelemetry
import OtlpGRPCSpanExporting
import NIO

struct Handler: APIProtocol {
    func getGreeting(_ input: Operations.getGreeting.Input) async throws -> Operations.getGreeting.Output {
        let name = input.query.name ?? "Stranger"
        return .ok(.init(body: .json(.init(message: "Hello, \(name)!"))))
    }
}

@main struct HelloWorldVaporServer {
    static func main() async throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup.singleton
        let otel = OTel(
            serviceName: "HelloWorldServer",
            eventLoopGroup: eventLoopGroup,
            processor: OTel.BatchSpanProcessor(
                exportingTo: OtlpGRPCSpanExporter(config: .init(eventLoopGroup: eventLoopGroup)),
                eventLoopGroup: eventLoopGroup
            )
        )
        try await otel.start().get()
        defer { try? otel.shutdown().wait() }
        InstrumentationSystem.bootstrap(otel.tracer())

        let app = Vapor.Application()
        let transport = VaporTransport(routesBuilder: app)
        let handler = Handler()
        try handler.registerHandlers(on: transport, serverURL: URL(string: "/api")!, middlewares: [TracingMiddleware()])
        try await app.execute()
    }
}
