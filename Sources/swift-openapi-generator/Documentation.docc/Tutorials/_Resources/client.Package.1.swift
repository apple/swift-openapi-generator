// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "GreetingServiceClient",
    platforms: [
        .macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9),
    ],
    targets: [
        .executableTarget(
            name: "GreetingServiceClient",
            path: "Sources"
        )
    ]
)
