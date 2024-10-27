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
        .library(name: "XemuFoundation", targets: ["XemuFoundation"]),
        .library(name: "XemuCore", targets: ["XemuCore"]),
        .library(name: "XemuDebugger", targets: ["XemuDebugger"]),
        .library(name: "XemuAsm", targets: ["XemuAsm"]),
        .library(name: "XemuNES", targets: ["XemuNES"])
    ],
    dependencies: [
        .package(url: "https://github.com/afrigon/XKit", branch: "main"),
        .package(url: "https://github.com/afrigon/stylx", branch: "main"),
    ],
    targets: [
        // MARK: XemuFoundation
        .target(
            name: "XemuFoundation",
            path: "Sources/XemuFoundation"
        ),
        .testTarget(
            name: "XemuFoundationTests",
            dependencies: [
                "XemuFoundation"
            ],
            path: "Tests/XemuFoundation"
        ),

        // MARK: XemuCore
        .target(
            name: "XemuCore",
            dependencies: [
                "XemuFoundation"
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
                "XemuAsm",
                "XemuCore",
                "XemuFoundation"
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
        
        // MARK: XemuAsm
        .target(
            name: "XemuAsm",
            dependencies: [
                "XemuFoundation"
            ],
            path: "Sources/XemuAsm"
        ),
        .testTarget(
            name: "XemuAsmTests",
            dependencies: [
                "XemuAsm"
            ],
            path: "Tests/XemuAsm"
        ),

        // MARK: XemuNES
        .target(
            name: "XemuNES",
            dependencies: [
                "XemuAsm",
                "XemuDebugger"
            ],
            path: "Sources/XemuNES",
            exclude: ["References"]
        ),
        .testTarget(
            name: "XemuNESTests",
            dependencies: [
                "XemuNES"
            ],
            path: "Tests/XemuNES",
            resources: [
                .copy("Data")
            ]
        )
    ]
)
