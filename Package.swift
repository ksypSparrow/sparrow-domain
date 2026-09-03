// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "SparrowDomain",
    platforms: [.iOS(.v27), .macOS(.v27)],
    products: [
        // ⚠️ `.dynamic` so this can be packaged as an XCFramework: a static
        // product builds to an object file with no framework to wrap. It also
        // stops `ColdStorage` swallowing a private copy of these types — with a
        // static product they are linked *into* it, and the app then carries two
        // copies of the same module.
        //
        // Source consumers, the V2 Linux server included, are unaffected: this
        // package still builds and tests from source on every platform.
        .library(name: "SparrowDomain", type: .dynamic, targets: ["SparrowDomain"]),
    ],
    targets: [
        .target(name: "SparrowDomain"),
        .testTarget(
            name: "SparrowDomainTests",
            dependencies: ["SparrowDomain"]
        ),
    ]
)
