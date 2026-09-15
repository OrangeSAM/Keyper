// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TickeysX",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TickeysX",
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
