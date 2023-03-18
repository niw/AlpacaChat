// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AlpacaChat",
    products: [
        .library(
            name: "AlpacaChat",
            targets: [
                "AlpacaChat",
                "AlpacaChatObjC"
            ]
        )
    ],
    targets: [
        .target(
            name: "AlpacaChat",
            dependencies: [
                .target(name: "AlpacaChatObjC")
            ]
        ),
        .target(
            name: "AlpacaChatObjC",
            dependencies: [
                .target(name: "alpaca.cpp")
            ]
        ),
        .target(
            name: "alpaca.cpp"
        )
    ],
    cxxLanguageStandard: .cxx11
)
