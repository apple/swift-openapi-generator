// swift-tools-version:6.0
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

let package = Package(
    name: "swift-openapi-generator",
    platforms: [
        .macOS(.v10_15),

        // The platforms below are not currently supported for running
        // the generator itself. We include them here to allow the generator
        // to emit a more descriptive compiler error.
        .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1),
    ],
    products: [
        .executable(name: "swift-openapi-generator", targets: ["swift-openapi-generator"]),
        .plugin(name: "OpenAPIGenerator", targets: ["OpenAPIGenerator"]),
        .plugin(name: "OpenAPIGeneratorCommand", targets: ["OpenAPIGeneratorCommand"]),
        .library(name: "_OpenAPIGeneratorCore", targets: ["_OpenAPIGeneratorCore"]),
    ],
    dependencies: [

        // General algorithms
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.1.4"),

        // Read OpenAPI documents
        .package(url: "https://github.com/mattpolzin/OpenAPIKit", from: "3.9.0"),
        .package(url: "https://github.com/jpsim/Yams", "4.0.0"..<"7.0.0"),

        // CLI Tool
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),

        // Tests-only: Runtime library linked by generated code, and also
        // helps keep the runtime library new enough to work with the generated
        // code.
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.10.1"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.0.2"),
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
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),

        // Generator Core Tests
        .testTarget(
            name: "OpenAPIGeneratorCoreTests",
            dependencies: ["_OpenAPIGeneratorCore"]
        ),

        // GeneratorReferenceTests
        .testTarget(
            name: "OpenAPIGeneratorReferenceTests",
            dependencies: ["_OpenAPIGeneratorCore"],
            resources: [.copy("Resources")]
        ),

        // Common types for concrete PetstoreConsumer*Tests test targets.
        .target(
            name: "PetstoreConsumerTestCore",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),

        // PetstoreConsumerTests
        // Builds and tests the reference code from GeneratorReferenceTests
        // to ensure it actually works correctly at runtime.
        .testTarget(
            name: "PetstoreConsumerTests",
            dependencies: ["PetstoreConsumerTestCore"]
        ),

        // Test Target for swift-openapi-generator
        .testTarget(
            name: "OpenAPIGeneratorTests",
            dependencies: [
                "_OpenAPIGeneratorCore",
                // Everything except windows: https://github.com/swiftlang/swift-package-manager/issues/6367
                .target(
                    name: "swift-openapi-generator",
                    condition: .when(platforms: [.android, .linux, .macOS, .openbsd, .wasi, .custom("freebsd")])
                ), .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            resources: [.copy("Resources")]
        ),

        // Generator CLI
        .executableTarget(
            name: "swift-openapi-generator",
            dependencies: [
                "_OpenAPIGeneratorCore", .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),

        // Build Plugin
        .plugin(name: "OpenAPIGenerator", capability: .buildTool(), dependencies: ["swift-openapi-generator"]),

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
            dependencies: ["swift-openapi-generator"]
        ),
    ]
)

for target in package.targets {
    switch target.type {
    case .executable, .regular, .test:
        break
    default:
        continue
    }

    var settings = target.swiftSettings ?? []

    // https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md
    // Require `any` for existential types.
    settings.append(.enableUpcomingFeature("ExistentialAny"))

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
    settings.append(.enableUpcomingFeature("MemberImportVisibility"))

    if target.name != "PetstoreConsumerTests" {
        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0409-access-level-on-imports.md
        settings.append(.enableUpcomingFeature("InternalImportsByDefault"))
    }

    target.swiftSettings = settings
}