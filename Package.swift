// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SingleRunnable",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_13),
        .tvOS(.v11),
        .watchOS(.v4),
    ],
    products: [
        .library(
            name: "SingleRunnable",
            targets: ["SingleRunnable"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SingleRunnable",
            dependencies: []),
        .testTarget(
            name: "SingleRunnableTests",
            dependencies: ["SingleRunnable"]),
    ]
)
