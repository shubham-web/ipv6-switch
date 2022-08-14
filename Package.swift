// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "IPv6Switch",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "IPv6Switch", targets: ["IPv6Switch"]),
    ],
    targets: [
        // Network inspection and control. No UI, so it can be unit tested.
        .target(name: "IPv6SwitchCore"),
        // The SwiftUI app.
        .executableTarget(name: "IPv6Switch", dependencies: ["IPv6SwitchCore"]),
        .testTarget(name: "IPv6SwitchCoreTests", dependencies: ["IPv6SwitchCore"]),
    ]
)
