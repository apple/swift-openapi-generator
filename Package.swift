// swift-tools-version:5.8
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
    name: "swift-openapi-generator",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "swift-openapi-generator", targets: ["swift-openapi-generator"]),
        .plugin(name: "OpenAPIGenerator", targets: ["OpenAPIGenerator"]),
        .library(name: "_OpenAPIGeneratorCore", targets: ["_OpenAPIGeneratorCore"]),
    ],
    dependencies: [

        // Generate Swift code
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            from: "508.0.1"
        ),

        // Format Swift code
        .package(
            url: "https://github.com/apple/swift-format.git",
            from: "508.0.1"
        ),

        // General algorithms
        .package(
            url: "https://github.com/apple/swift-algorithms",
            from: "1.0.0"
        ),

        // Read OpenAPI documents
        .package(
            url: "https://github.com/mattpolzin/OpenAPIKit.git",
            exact: "3.0.0-alpha.7"
        ),
        .package(
            url: "https://github.com/jpsim/Yams.git",
            from: "4.0.0"
        ),

        // CLI Tool
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.0.1"
        ),

        // Tests-only: Runtime library linked by generated code
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "0.1.3")),

        // Build and preview docs
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // Generator Core
        .target(
            name: "_OpenAPIGeneratorCore",
            dependencies: [
                .product(name: "OpenAPIKit30", package: "OpenAPIKit"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftFormat", package: "swift-format"),
                .product(name: "SwiftFormatConfiguration", package: "swift-format"),
            ]
        ),

        // Generator Core Tests
        .testTarget(
            name: "OpenAPIGeneratorCoreTests",
            dependencies: [
                "_OpenAPIGeneratorCore",
            ]
        ),

        // GeneratorReferenceTests
        .testTarget(
            name: "OpenAPIGeneratorReferenceTests",
            dependencies: [
                "_OpenAPIGeneratorCore",
                .product(name: "SwiftFormat", package: "swift-format"),
                .product(name: "SwiftFormatConfiguration", package: "swift-format"),
            ],
            resources: [
                .copy("Resources"),
            ]
        ),

        // PetstoreConsumerTests
        // Builds and tests the reference code from GeneratorReferenceTests
        // to ensure it actually works correctly at runtime.
        .testTarget(
            name: "PetstoreConsumerTests",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ]
        ),

        // Generator CLI
        .executableTarget(
            name: "swift-openapi-generator",
            dependencies: [
                "_OpenAPIGeneratorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),

        // Build Plugin
        .plugin(
            name: "OpenAPIGenerator",
            capability: .buildTool(),
            dependencies: [
                "swift-openapi-generator",
            ]
        ),
    ]
)
