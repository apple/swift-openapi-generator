// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "linkage-test",
    dependencies: [
        .package(name: "swift-openapi-generator", path: "../.."),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.11.0", traits: []),
    ],
    targets: [
        .executableTarget(
            name: "linkageTest",
            dependencies: [.product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        )
    ]
)
