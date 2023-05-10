// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "GreetingService",
    targets: [
        .executableTarget(
            name: "GreetingService",
            path: "Sources"
        )
    ]
)
