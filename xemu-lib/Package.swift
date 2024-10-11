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
        .library(name: "XemuDebugger", targets: ["XemuDebugger"]),
        .library(name: "XemuRuntime", targets: ["XemuRuntime"]),
        .library(name: "XemuCore", targets: ["XemuCore"]),
        .library(name: "XemuPersistance", targets: ["XemuPersistance"])
    ],
    dependencies: [
        .package(url: "https://github.com/afrigon/XKit", branch: "main"),
        .package(url: "https://github.com/afrigon/stylx", branch: "main")
    ],
    targets: [
        // MARK: XemuCore
        .target(
            name: "XemuCore",
            dependencies: [
                "XemuNES"
            ],
            path: "Sources/XemuCore"
        ),
        .testTarget(
            name: "XemuCoreTests",
            dependencies: [
                "XemuCore"
            ],
            path: "Tests/XemuCore"
        ),
        
        // MARK: XemuDebugger
        .target(
            name: "XemuDebugger",
            dependencies: [
                "XemuCore"
            ],
            path: "Sources/XemuDebugger"
        ),
        .testTarget(
            name: "XemuDebuggerTests",
            dependencies: [
                "XemuDebugger"
            ],
            path: "Tests/XemuDebugger"
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
        ),

        // MARK: XemuRuntime
        .target(
            name: "XemuRuntime",
            dependencies: [
                "XemuCore"
            ],
            path: "Sources/XemuRuntime"
        ),
        .testTarget(
            name: "XemuRuntimeTests",
            dependencies: [
                "XemuRuntime"
            ],
            path: "Tests/XemuRuntime"
        ),

        // MARK: XemuPersistance
        .target(
            name: "XemuPersistance",
            dependencies: [
                "XemuCore"
            ],
            path: "Sources/XemuPersistance"
        ),
        .testTarget(
            name: "XemuPersistanceTests",
            dependencies: [
                "XemuPersistance"
            ],
            path: "Tests/XemuPersistance"
        )
    ]
)
