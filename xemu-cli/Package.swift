// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "XemuCLI",
    targets: [
        .executableTarget(
            name: "XemuCLI",
            dependencies: [
                "Clibedit"
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
