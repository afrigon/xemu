// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "xemu",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(name: "XemuLib", path: "../xemu-lib"),
        .package(url: "https://github.com/afrigon/Prism", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "XemuCLI",
            dependencies: [
                "Clibedit",
                .product(name: "Prism", package: "Prism"),
                .product(name: "XemuAsm", package: "XemuLib"),
                .product(name: "XemuCore", package: "XemuLib"),
                .product(name: "XemuDebugger", package: "XemuLib"),
                .product(name: "XemuFoundation", package: "XemuLib"),
                .product(name: "XemuNES", package: "XemuLib")
            ],
            path: "Sources"
        ),
        
        .systemLibrary(
            name: "Clibedit",
            path: "lib/libedit",
            pkgConfig: "libedit",
            providers: [
                .brew(["libedit"]),
                .apt(["libedit-dev"])
            ]
        )
    ]
)
