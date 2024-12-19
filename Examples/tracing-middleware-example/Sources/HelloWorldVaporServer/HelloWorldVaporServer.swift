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
import OTel
import OTLPGRPC
import NIO

struct Handler: APIProtocol {
    func getGreeting(_ input: Operations.GetGreeting.Input) async throws -> Operations.GetGreeting.Output {
        let name = input.query.name ?? "Stranger"
        return .ok(.init(body: .json(.init(message: "Hello, \(name)!"))))
    }
}

@main struct HelloWorldVaporServer {
    static func main() async throws {
        let environment = OTelEnvironment.detected()
        let resourceDetection = OTelResourceDetection(detectors: [
            OTelProcessResourceDetector(), OTelEnvironmentResourceDetector(environment: environment),
        ])
        let resource = await resourceDetection.resource(environment: environment, logLevel: .trace)
        let exporter = try OTLPGRPCSpanExporter(configuration: .init(environment: environment))
        let processor = OTelBatchSpanProcessor(exporter: exporter, configuration: .init(environment: environment))
        let tracer = OTelTracer(
            idGenerator: OTelRandomIDGenerator(),
            sampler: OTelConstantSampler(isOn: true),
            propagator: OTelW3CPropagator(),
            processor: processor,
            environment: environment,
            resource: resource
        )
        InstrumentationSystem.bootstrap(tracer)
        let app = try await Vapor.Application.make()
        let transport = VaporTransport(routesBuilder: app)
        let handler = Handler()
        try handler.registerHandlers(on: transport, serverURL: URL(string: "/api")!, middlewares: [TracingMiddleware()])
        // Consider using Swift Service Lifecycle — https://github.com/swift-server/swift-service-lifecycle
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await app.execute() }
            group.addTask { try await tracer.run() }
            group.addTask { try await processor.run() }
            _ = try await group.next()
            group.cancelAll()
        }
    }
}
