// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LLL",
    platforms: [
        .iOS(.v17),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LLL",
            targets: ["LLL"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LLL"
        ),
        .testTarget(
            name: "LLLTests",
            dependencies: ["LLL"]
        ),
    ]
)
