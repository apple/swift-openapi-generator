// swift-tools-version:5.10
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftOpenAPIGenerator project authors
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
    name: "type-overrides-example",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Types", targets: ["Types"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "Types",
            dependencies: [
                "ExternalLibrary",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")]
        ),
        .target(
            name: "ExternalLibrary"
        ),
    ]
)
