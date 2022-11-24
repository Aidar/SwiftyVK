// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyVK",
    products: [
        .library(
            name: "SwiftyVK",
            targets: ["SwiftyVK_macOS", "SwiftyVK_iOS"]
        ),
        targets: [
        .target(name: "SwiftyVK_macOS", dependencies: ["SwiftyVK_resources_macOS"]),
        .target(name: "SwiftyVK_iOS", dependencies: ["SwiftyVK_resources_iOS"]),
        .testTarget(name: "SwiftyVK_tests_macOS", dependencies: ["SwiftyVK_macOS"]),
        .testTarget(name: "SwiftyVK_tests_iOS", dependencies: ["SwiftyVK_iOS"])
        ]
    ]
)
