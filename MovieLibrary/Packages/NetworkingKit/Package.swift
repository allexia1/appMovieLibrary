// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetworkingKit",
    platforms: [.iOS(.v17), .macOS(.v12)],
    products: [
        .library(name: "NetworkingKit", targets: ["NetworkingKit"])
    ],
    targets: [
        .target(name: "NetworkingKit"),
        .testTarget(name: "NetworkingKitTests", dependencies: ["NetworkingKit"])
    ]
)
