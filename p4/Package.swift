// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YizhenCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "YizhenCore", targets: ["YizhenCore"]),
        .library(name: "YizhenContract", targets: ["YizhenContract"]),
    ],
    targets: [
        .target(name: "YizhenContract"),
        .target(name: "YizhenCore", dependencies: ["YizhenContract"]),
        .testTarget(name: "YizhenCoreTests", dependencies: ["YizhenCore", "YizhenContract"]),
    ]
)