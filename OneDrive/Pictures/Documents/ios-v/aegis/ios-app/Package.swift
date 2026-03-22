// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "AegisApp",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "AegisApp", targets: ["AegisApp"]),
    ],
    targets: [
        .target(name: "AegisApp", path: "Sources/AegisApp")
    ]
)
