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
    name: "hello-world-hummingbird-server-example",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-hummingbird", from: "2.0.1"),
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "2.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "HelloWorldHummingbirdServer",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIHummingbird", package: "swift-openapi-hummingbird"),
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        ), .testTarget(name: "HelloWorldHummingbirdServerTests", dependencies: ["HelloWorldHummingbirdServer"]),
    ]
)
