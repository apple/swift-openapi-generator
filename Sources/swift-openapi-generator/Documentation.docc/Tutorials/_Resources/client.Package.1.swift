// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GreetingServiceClient",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)],
    targets: [
        .executableTarget(
            name: "GreetingServiceClient"
        )
    ]
)
