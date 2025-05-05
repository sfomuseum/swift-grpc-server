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
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "1.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
    ],
    targets: [
        .target(
            name: "GRPCServer",
            dependencies: [
                .product(name: "GRPCCore", package: "grpc-swift"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "GRPCServerLogger",
            dependencies: [
                .product(name: "GRPCCore", package: "grpc-swift"),
                .product(name: "Logging", package: "swift-log")
            ]
        )
    ]
)
