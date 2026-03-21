// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "EdgeClamp",
    targets: [
        .executableTarget(
            name: "EdgeClamp",
            path: "Sources/EdgeClamp"
        )
    ]
)