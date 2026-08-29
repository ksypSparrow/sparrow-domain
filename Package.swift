// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "SparrowDomain",
    platforms: [.iOS(.v27), .macOS(.v27)],
    products: [
        .library(name: "SparrowDomain", targets: ["SparrowDomain"]),
    ],
    targets: [
        .target(name: "SparrowDomain"),
        .testTarget(
            name: "SparrowDomainTests",
            dependencies: ["SparrowDomain"]
        ),
    ]
)
