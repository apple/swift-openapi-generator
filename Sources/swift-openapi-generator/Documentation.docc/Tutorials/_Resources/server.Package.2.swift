// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "GreetingService",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/swift-server/swift-openapi-vapor", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/vapor/vapor", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "GreetingService",
            path: "Sources"
        )
    ]
)
