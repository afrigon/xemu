// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "XemuLib",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18)
    ],
    products: [
        .library(name: "XemuCore", targets: ["XemuCore"]),
        .library(name: "XemuSwiftUI", targets: ["XemuSwiftUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/afrigon/XKit", branch: "main"),
        .package(url: "https://github.com/afrigon/stylx", branch: "main"),
    ],
    targets: [
        // MARK: XemuCore
        .target(
            name: "XemuCore",
            path: "Sources/XemuCore"
        ),
        .testTarget(
            name: "XemuCoreTests",
            dependencies: [
                "XemuCore"
            ],
            path: "Tests/XemuCore"
        ),
        
        // MARK: XemuCore
        .target(
            name: "XemuSwiftUI",
            dependencies: [
                "XemuCore",
                "XemuNES",
                "stylx"
            ],
            path: "Sources/XemuSwiftUI"
        ),
        .testTarget(
            name: "XemuSwiftUITests",
            dependencies: [
                "XemuSwiftUI"
            ],
            path: "Tests/XemuSwiftUI"
        ),

        // MARK: XemuNES
        .target(
            name: "XemuNES",
            path: "Sources/XemuNES"
        ),
        .testTarget(
            name: "XemuNESTests",
            dependencies: [
                "XemuNES"
            ],
            path: "Tests/XemuNES"
        )
    ]
)
