// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "gclouder",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "gclouder",
            targets: ["Gclouder"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Gclouder",
            dependencies: ["LaunchAtLogin"]
        ),
        .testTarget(
            name: "GclouderTests",
            dependencies: ["Gclouder"]
        )
    ]
) 