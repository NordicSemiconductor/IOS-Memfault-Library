// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOS-nRF-Memfault-Library",
    platforms: [
        .iOS("17.0"),
        .macOS("14.0")
    ],
    products: [
        .library(
            name: "iOS-nRF-Memfault-Library",
            targets: ["iOS-nRF-Memfault-Library"]),
    ],
    dependencies: [
        .package(url: "https://github.com/NordicPlayground/IOS-BLE-Library", revision: "2778b4400e079d2472306bd3d3ac5460e7277272"),
        .package(url: "https://github.com/NordicPlayground/IOS-Common-Libraries", branch: "main"),
    ],
    targets: [
        .target(
            name: "iOS-nRF-Memfault-Library",
            dependencies: [
                .product(name: "iOS-BLE-Library", package: "iOS-BLE-Library"),
                .product(name: "iOSCommonLibraries", package: "ios-common-libraries")
            ]),
        .testTarget(
            name: "iOS-nRF-Memfault-LibraryTests",
            dependencies: ["iOS-nRF-Memfault-Library"]),
    ]
)
