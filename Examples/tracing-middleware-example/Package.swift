// swift-tools-version:5.9
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
import PackageDescription

let package = Package(
    name: "tracing-middleware-example",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-vapor", from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor", from: "4.89.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing", from: "1.0.1"),
        .package(url: "https://github.com/apple/swift-distributed-tracing-extras", exact: "1.0.0-beta.1"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.62.0"),
        .package(url: "https://github.com/slashmo/swift-otel", .upToNextMinor(from: "0.8.0")),
    ],
    targets: [
        .target(
            name: "TracingMiddleware",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .product(name: "TracingOpenTelemetrySemanticConventions", package: "swift-distributed-tracing-extras"),
            ]
        ),
        .executableTarget(
            name: "HelloWorldVaporServer",
            dependencies: [
                "TracingMiddleware", .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIVapor", package: "swift-openapi-vapor"),
                .product(name: "Vapor", package: "vapor"), .product(name: "NIO", package: "swift-nio"),
                .product(name: "OpenTelemetry", package: "swift-otel"),
                .product(name: "OtlpGRPCSpanExporting", package: "swift-otel"),
            ],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        ),
    ]
)
