// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "imgmap",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
        .package(url: "https://github.com/hexagons/PixelKit.git", from: "1.0.2"),
//        .package(path: "~/Code/Frameworks/Production/LiveValues"),
//        .package(path: "~/Code/Frameworks/Production/RenderKit"),
//        .package(path: "~/Code/Frameworks/Production/PixelKit"),
    ],
    targets: [
        .target(name: "imgmap",
                dependencies: ["ShellOut", "ArgumentParser", "PixelKit"]),
        .testTarget(name: "imgmapTests",
                    dependencies: ["imgmap"]),
    ]
)
