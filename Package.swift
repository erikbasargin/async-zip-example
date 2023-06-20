// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncZip",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "AsyncZip",
            targets: ["AsyncZip"]),
    ],
    targets: [
        .target(
            name: "AsyncZip"),
        .testTarget(
            name: "AsyncZipTests",
            dependencies: ["AsyncZip"]),
    ]
)
