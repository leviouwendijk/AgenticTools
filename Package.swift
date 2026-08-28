// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "AgenticTools",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "AgenticTools",
            targets: [
                "AgenticTools",
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Agentic.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/AgenticExecution.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/AgenticWorkspace.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Primitives.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Search.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "AgenticTools",
            dependencies: [
                .product(
                    name: "Agentic",
                    package: "Agentic"
                ),
                .product(
                    name: "AgenticExecution",
                    package: "AgenticExecution"
                ),
                .product(
                    name: "AgenticWorkspace",
                    package: "AgenticWorkspace"
                ),
                .product(
                    name: "Primitives",
                    package: "Primitives"
                ),
                .product(
                    name: "Search",
                    package: "Search"
                ),
            ]
        ),
    ],
    swiftLanguageModes: [
        .v6,
    ]
)
