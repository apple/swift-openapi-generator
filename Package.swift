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
import Foundation
import PackageDescription

// General Swift-settings for all targets.
var swiftSettings: [SwiftSetting] = []

#if swift(>=5.9)
swiftSettings.append(
    // https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md
    // Require `any` for existential types.
    .enableUpcomingFeature("ExistentialAny")
)

// Strict concurrency is enabled in CI; use this environment variable to enable it locally.
if ProcessInfo.processInfo.environment["SWIFT_OPENAPI_STRICT_CONCURRENCY"].flatMap(Bool.init) ?? false {
    swiftSettings.append(contentsOf: [
        .define("SWIFT_OPENAPI_STRICT_CONCURRENCY"),
        .enableExperimentalFeature("StrictConcurrency"),
    ])
}
#endif

let package = Package(
    name: "swift-openapi-generator",
    platforms: [
        .macOS(.v10_15),

        // The platforms below are not currently supported for running
        // the generator itself. We include them here to allow the generator
        // to emit a more descriptive compiler error.
        .iOS(.v13), .tvOS(.v13), .watchOS(.v6),
    ],
    products: [
        .executable(name: "swift-openapi-generator", targets: ["swift-openapi-generator"]),
        .plugin(name: "OpenAPIGenerator", targets: ["OpenAPIGenerator"]),
        .plugin(name: "OpenAPIGeneratorCommand", targets: ["OpenAPIGeneratorCommand"]),
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
            exact: "3.0.0-rc.2"
        ),
        .package(
            url: "https://github.com/jpsim/Yams.git",
            "4.0.0"..<"6.0.0"
        ),

        // CLI Tool
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.0.1"
        ),

        // Tests-only: Runtime library linked by generated code, and also
        // helps keep the runtime library new enough to work with the generated
        // code.
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "0.3.2")),

        // Build and preview docs
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [

        // Generator Core
        .target(
            name: "_OpenAPIGeneratorCore",
            dependencies: [
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "OpenAPIKit30", package: "OpenAPIKit"),
                .product(name: "OpenAPIKitCompat", package: "OpenAPIKit"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftFormat", package: "swift-format"),
                .product(name: "SwiftFormatConfiguration", package: "swift-format"),
            ],
            swiftSettings: swiftSettings
        ),

        // Generator Core Tests
        .testTarget(
            name: "OpenAPIGeneratorCoreTests",
            dependencies: [
                "_OpenAPIGeneratorCore"
            ],
            swiftSettings: swiftSettings
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
                .copy("Resources")
            ],
            swiftSettings: swiftSettings
        ),

        // Common types for concrete PetstoreConsumer*Tests test targets.
        .target(
            name: "PetstoreConsumerTestCore",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ],
            swiftSettings: swiftSettings
        ),

        // PetstoreConsumerTests
        // Builds and tests the reference code from GeneratorReferenceTests
        // to ensure it actually works correctly at runtime.
        .testTarget(
            name: "PetstoreConsumerTests",
            dependencies: [
                "PetstoreConsumerTestCore"
            ],
            swiftSettings: swiftSettings
        ),

        // Generator CLI
        .executableTarget(
            name: "swift-openapi-generator",
            dependencies: [
                "_OpenAPIGeneratorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: swiftSettings
        ),

        // Build Plugin
        .plugin(
            name: "OpenAPIGenerator",
            capability: .buildTool(),
            dependencies: [
                "swift-openapi-generator"
            ]
        ),

        // Command Plugin
        .plugin(
            name: "OpenAPIGeneratorCommand",
            capability: .command(
                intent: .custom(
                    verb: "generate-code-from-openapi",
                    description: "Generate Swift code from an OpenAPI document."
                ),
                permissions: [
                    .writeToPackageDirectory(
                        reason: "To write the generated Swift files back into the source directory of the package."
                    )
                ]
            ),
            dependencies: [
                "swift-openapi-generator"
            ]
        ),
    ]
)
