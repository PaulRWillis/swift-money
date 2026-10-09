// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftMoney",
    platforms: [
        .macOS("13.3"),
        .iOS("16.4"),
        .watchOS("9.4"),
        .tvOS("16.4"),
        .visionOS(.v1),
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
            name: "SwiftMoneyFX",
            targets: ["SwiftMoneyFX"]
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
    dependencies: [
        // Dev-only, reached by CLDRPluralParsing alone. No library product depends on it, so a
        // consumer of SwiftMoney never resolves it. No traits: its default one parses enums through
        // CasePaths, which nothing here needs and which would pull in swift-syntax to build.
        .package(url: "https://github.com/pointfreeco/swift-parsing", .upToNextMinor(from: "0.15.2"), traits: []),
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
            name: "SwiftMoneyFX",
            dependencies: ["SwiftMoneyCore"]
        ),
        .target(
            name: "SwiftMoneyLocalization",
            dependencies: ["SwiftMoneyCore"],
            // The generator writes its report of the locales it left out beside the tables, so that
            // regenerating and diffing one directory covers both. It is documentation, not a resource.
            exclude: ["Generated/UnsupportedLocales.md"]
        ),
        .target(
            name: "SwiftMoneyFoundation",
            dependencies: ["SwiftMoneyCore", "SwiftMoneyLocalization"]
        ),
        // Dev-only. The property-test generators and test helpers, shared by the Core, FX and
        // Foundation test suites. Not in any library product.
        .target(
            name: "SwiftMoneyCoreTestSupport",
            dependencies: ["SwiftMoneyCore"]
        ),
        // Dev-only. Shares the format-matrix inputs between the golden test and the ICU deviation
        // report, so they can't drift apart. Not in any library product.
        .target(
            name: "SwiftMoneyFormatMatrix",
            dependencies: ["SwiftMoneyCore", "SwiftMoneyFoundation", "SwiftMoneyLocalization"]
        ),
        // Dev-only. Reads CLDR's plural rule text for the generator, so the shipped library never
        // inherits a parsing dependency. Not in any library product.
        .target(
            name: "CLDRPluralParsing",
            dependencies: [
                "SwiftMoneyLocalization",
                .product(name: "Parsing", package: "swift-parsing"),
            ]
        ),
        // Dev-only. Reads the shape of CLDR's currency format patterns for the generator, and says
        // which shapes the generated tables cannot represent. Not in any library product.
        .target(
            name: "CLDRCurrencyPatterns"
        ),
        // Dev-only. Groups CLDR locale folders and works out every name each is filed under.
        // Not in any library product.
        .target(
            name: "CLDRLocaleIdentifiers",
            dependencies: ["SwiftMoneyLocalization"]
        ),
        // Dev-only. Names why the generator cannot build tables for a CLDR locale, decides which of
        // a locale's currency codes the tables can hold, and renders the committed report of what
        // it left out. Not in any library product.
        .target(
            name: "CLDRLocaleSkips",
            dependencies: ["CLDRCurrencyPatterns", "SwiftMoneyCore", "SwiftMoneyLocalization"]
        ),
        .testTarget(
            name: "SwiftMoneyTests",
            dependencies: ["SwiftMoney"]
        ),
        .testTarget(
            name: "SwiftMoneyCoreTests",
            dependencies: ["SwiftMoneyCore", "SwiftMoneyCoreTestSupport"],
            exclude: ["Resources/UPDATING.md"],
            // The General Decimal Arithmetic conformance corpus, parsed at runtime by GDATests.
            // Not the whole folder: codesign rejects a top-level Resources folder in an iOS bundle.
            resources: [.copy("Resources/GDA")]
        ),
        .testTarget(
            name: "SwiftMoneyFXTests",
            dependencies: ["SwiftMoneyFX", "SwiftMoneyCore", "SwiftMoneyCoreTestSupport"]
        ),
        .testTarget(
            name: "SwiftMoneyLocalizationTests",
            dependencies: ["SwiftMoneyLocalization"]
        ),
        .testTarget(
            name: "SwiftMoneyFoundationTests",
            dependencies: [
                "SwiftMoneyFoundation",
                "SwiftMoneyFormatMatrix",
                "SwiftMoneyLocalization",
                "SwiftMoneyCoreTestSupport",
            ]
        ),
        .testTarget(
            name: "SwiftMoneyFormatMatrixTests",
            dependencies: ["SwiftMoneyFormatMatrix", "SwiftMoneyCore", "SwiftMoneyLocalization"]
        ),
        .testTarget(
            name: "CLDRPluralParsingTests",
            dependencies: ["CLDRPluralParsing", "SwiftMoneyLocalization"]
        ),
        .testTarget(
            name: "CLDRCurrencyPatternsTests",
            dependencies: ["CLDRCurrencyPatterns"]
        ),
        .testTarget(
            name: "CLDRLocaleIdentifiersTests",
            dependencies: ["CLDRLocaleIdentifiers", "SwiftMoneyLocalization"]
        ),
        .testTarget(
            name: "CLDRLocaleSkipsTests",
            dependencies: [
                "CLDRLocaleSkips",
                "CLDRCurrencyPatterns",
                "SwiftMoneyCore",
                "SwiftMoneyLocalization",
            ]
        ),
        // Dev-only. Reads the pinned CLDR JSON (Tools/cldr/node_modules) and regenerates
        // SwiftMoneyLocalization's data tables. Not in any library product.
        .executableTarget(
            name: "GenerateSwiftMoneyLocalization",
            dependencies: [
                "CLDRCurrencyPatterns",
                "CLDRLocaleIdentifiers",
                "CLDRLocaleSkips",
                "CLDRPluralParsing",
                "SwiftMoneyCore",
                "SwiftMoneyLocalization",
            ],
            path: "Tools/GenerateLocalization"
        ),
        // Dev-only. Prints where the engine and ICU disagree; always exits 0. Not in any library
        // product.
        .executableTarget(
            name: "CompareFormattingToICU",
            dependencies: ["SwiftMoneyCore", "SwiftMoneyFormatMatrix"],
            path: "Tools/CompareFormattingToICU"
        ),
        // Dev-only. Writes the committed golden digests the MoneyFormatStyle golden test reads. Not in
        // any library product.
        .executableTarget(
            name: "RecordGoldenDigests",
            dependencies: ["SwiftMoneyFormatMatrix"],
            path: "Tools/RecordGoldenDigests"
        ),
    ]
)
