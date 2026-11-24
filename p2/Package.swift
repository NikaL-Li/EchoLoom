// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureScenes",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "FeatureScenes", targets: ["FeatureScenes"])
    ],
    targets: [
        .target(name: "FeatureScenes"),
        .testTarget(name: "FeatureScenesTests", dependencies: ["FeatureScenes"])
    ]
)