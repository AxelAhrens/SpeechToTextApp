// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SpeechToTextApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SpeechToTextApp",
            targets: ["SpeechToTextApp"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SpeechToTextApp",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "SpeechToTextAppTests",
            dependencies: ["SpeechToTextApp"],
            path: "Tests"
        ),
    ]
)
