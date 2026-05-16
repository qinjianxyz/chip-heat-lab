// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChipHeatLab",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ChipHeatLab", targets: ["ChipHeatLabApp"])
    ],
    targets: [
        .executableTarget(
            name: "ChipHeatLabApp",
            resources: [.process("Resources")]
        )
    ]
)
