// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "GreetingServiceClient",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6),
    ],
    targets: [
        .executableTarget(
            name: "GreetingServiceClient",
            path: "Sources"
        )
    ]
)
