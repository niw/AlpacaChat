// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AlpacaChatCLI",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "AlpacaChatCLI",
            targets: [
                "AlpacaChatCLI"
            ]
        )
    ],
    dependencies: [
        .package(name: "AlpacaChat", path: "../.."),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.2.2"))
    ],
    targets: [
        .executableTarget(
            name: "AlpacaChatCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AlpacaChat", package: "AlpacaChat")
            ]
        ),
    ]
)
