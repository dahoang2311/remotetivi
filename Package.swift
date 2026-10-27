// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SamsungRemote",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SamsungRemote",
            targets: ["SamsungRemote"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SamsungRemote",
            dependencies: [],
            path: "SamsungRemote",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
