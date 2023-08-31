// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "GreetingServiceClient",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", .upToNextMinor(from: "0.2.0")),
    ],
    targets: [
        .executableTarget(
            name: "GreetingServiceClient",
            dependencies: [
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                ),
                .product(
                    name: "OpenAPIURLSession",
                    package: "swift-openapi-urlsession"
                ),
            ],
            path: "Sources",
            plugins: [
                .plugin(
                    name: "OpenAPIGenerator",
                    package: "swift-openapi-generator"
                )
            ]
        )
    ]
)
