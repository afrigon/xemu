// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "xemu-runtime",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(name: "XemuLib", path: "../xemu-lib"),
    ],
    targets: [
        .executableTarget(name: "xemu-runtime")
    ]
)
