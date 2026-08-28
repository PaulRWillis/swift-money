// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftMoney",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "SwiftMoney",
            targets: ["SwiftMoney"]
        ),
        .library(
            name: "SwiftMoneyCore",
            targets: ["SwiftMoneyCore"]
        ),
        .library(
            name: "SwiftMoneyFoundation",
            targets: ["SwiftMoneyFoundation"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftMoney",
            dependencies: ["SwiftMoneyCore", "SwiftMoneyFoundation"]
        ),
        .target(
            name: "SwiftMoneyCore"
        ),
        .target(
            name: "SwiftMoneyFoundation",
            dependencies: ["SwiftMoneyCore"]
        ),
        .testTarget(
            name: "SwiftMoneyTests",
            dependencies: ["SwiftMoney"]
        ),
        .testTarget(
            name: "SwiftMoneyCoreTests",
            dependencies: ["SwiftMoneyCore"]
        ),
        .testTarget(
            name: "SwiftMoneyFoundationTests",
            dependencies: ["SwiftMoneyFoundation"]
        ),
    ]
)
