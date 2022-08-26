// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOS-nRF-Memfault-Library",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "iOS-nRF-Memfault-Library",
            targets: ["iOS-nRF-Memfault-Library"]),
    ],
    dependencies: [
        .package(url: "https://github.com/NordicPlayground/IOS-BLE-Library", branch: "main"),
    ],
    targets: [
        .target(
            name: "iOS-nRF-Memfault-Library",
            dependencies: [.product(name: "iOS-BLE-Library", package: "iOS-BLE-Library")]),
        .testTarget(
            name: "iOS-nRF-Memfault-LibraryTests",
            dependencies: ["iOS-nRF-Memfault-Library"]),
    ]
)
