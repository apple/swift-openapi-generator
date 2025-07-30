// swift-tools-version:5.10
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
    name: "swift-openapi-integration-test",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "IntegrationTestLibrary",
            targets: ["Types", "Client", "Server", "MockTransportClient", "MockTransportServer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "Types",
            dependencies: [.product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        ),
        .target(
            name: "Client",
            dependencies: ["Types", .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        ),
        .target(
            name: "Server",
            dependencies: ["Types", .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        ),
        .target(
            name: "MockTransportClient",
            dependencies: ["Client", .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")]
        ),
        .target(
            name: "MockTransportServer",
            dependencies: ["Server", .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")]
        ),
        // Targets to integration test the command plugin
        .target(name: "Empty"),
        .target(
            name: "TypesAOT",
            dependencies: [.product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")]
        ),
        .target(
            name: "TypesAOTWithDependency",
            dependencies: ["Empty", .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")]
        ),
    ]
)
