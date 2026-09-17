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
            name: "SwiftMoneyLocalization",
            targets: ["SwiftMoneyLocalization"]
        ),
        .library(
            name: "SwiftMoneyFoundation",
            targets: ["SwiftMoneyFoundation"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftMoney",
            dependencies: ["SwiftMoneyCore", "SwiftMoneyLocalization", "SwiftMoneyFoundation"]
        ),
        .target(
            name: "SwiftMoneyCore"
        ),
        .target(
            name: "SwiftMoneyLocalization",
            dependencies: ["SwiftMoneyCore"]
        ),
        .target(
            name: "SwiftMoneyFoundation",
            dependencies: ["SwiftMoneyCore", "SwiftMoneyLocalization"]
        ),
        // Dev-only. Shares the format-matrix inputs between the golden test and the ICU deviation
        // report, so they can't drift apart. Not in any library product.
        .target(
            name: "SwiftMoneyFormatMatrix",
            dependencies: ["SwiftMoneyCore", "SwiftMoneyFoundation"]
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
            name: "SwiftMoneyLocalizationTests",
            dependencies: ["SwiftMoneyLocalization"]
        ),
        .testTarget(
            name: "SwiftMoneyFoundationTests",
            dependencies: ["SwiftMoneyFoundation", "SwiftMoneyFormatMatrix"]
        ),
        .testTarget(
            name: "SwiftMoneyFormatMatrixTests",
            dependencies: ["SwiftMoneyFormatMatrix", "SwiftMoneyCore"]
        ),
        // Dev-only. Reads the pinned CLDR JSON (Tools/cldr/node_modules) and regenerates
        // SwiftMoneyLocalization's data tables. Not in any library product.
        .executableTarget(
            name: "GenerateSwiftMoneyLocalization",
            path: "Tools/GenerateLocalization"
        ),
        // Dev-only. Prints where the engine and ICU disagree; always exits 0. Not in any library
        // product.
        .executableTarget(
            name: "CompareFormattingToICU",
            dependencies: ["SwiftMoneyCore", "SwiftMoneyFormatMatrix"],
            path: "Tools/CompareFormattingToICU"
        ),
    ]
)
