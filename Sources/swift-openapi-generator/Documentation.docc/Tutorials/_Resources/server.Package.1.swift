// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "GreetingService",
    platforms: [
        .macOS(.v10_15)
    ],
    targets: [
        .executableTarget(
            name: "GreetingService",
            path: "Sources"
        )
    ]
)
