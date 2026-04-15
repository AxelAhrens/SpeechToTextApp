// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SpeechToTextApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SpeechToTextApp",
            targets: ["SpeechToTextApp"]
        ),
    ],
    dependencies: [
        // API Client
        // Add later: .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SpeechToTextApp",
            dependencies: [],
            path: "Sources"
        ),
    ]
)
