// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GreetingService",
    platforms: [
        .macOS(.v10_15)
    ],
    targets: [
        .executableTarget(
            name: "GreetingService"
        )
    ]
)
