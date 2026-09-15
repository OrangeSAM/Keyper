// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Keyper",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Keyper",
            resources: [
                .copy("Resources/data")
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("Carbon"),
            ]
        )
    ]
)
