// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-grpc-server",
    products: [
        .library(
            name: "GRPCServer",
            targets: ["GRPCServer"]),
        .library(
            name: "GRPCServerLogger",
            targets: ["GRPCServerLogger"]),
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.15.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
    ],
    targets: [
        .target(
            name: "GRPCServer",
            dependencies: [
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "GRPCServerLogger",
            dependencies: [
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "Logging", package: "swift-log")
            ]
        )
    ]
)
