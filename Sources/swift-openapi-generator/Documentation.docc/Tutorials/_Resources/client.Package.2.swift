// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GreetingServiceClient",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", exact: "1.0.0-alpha.1"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", exact: "1.0.0-alpha.1"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", exact: "1.0.0-alpha.1"),
    ],
    targets: [
        .executableTarget(
            name: "GreetingServiceClient"
        )
    ]
)
