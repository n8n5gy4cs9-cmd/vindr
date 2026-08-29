// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "vindR",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "vindR",
            resources: [
                .copy("Resources/AppIcon.png"),
                .copy("Resources/AppIcon.icns")
            ]
        ),
        .testTarget(name: "vindRTests", dependencies: ["vindR"])
    ]
)
