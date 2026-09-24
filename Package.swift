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
        // Dev-only. Works out the identifier a locale's data has to be filed under to be found.
        // Not in any library product.
        .target(
            name: "CLDRLocaleIdentifiers"
        ),
        // Dev-only. Names why the generator cannot build tables for a CLDR locale, and renders the
        // committed report of the ones it left out. Not in any library product.
        .target(
            name: "CLDRLocaleSkips",
            dependencies: ["CLDRCurrencyPatterns", "SwiftMoneyLocalization"]
        ),
        .testTarget(
            name: "SwiftMoneyTests",
            dependencies: ["SwiftMoney"]
        ),
        .testTarget(
            name: "SwiftMoneyCoreTests",
            dependencies: ["SwiftMoneyCore"],
            // The General Decimal Arithmetic conformance corpus, parsed at runtime by GDATests.
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "SwiftMoneyLocalizationTests",
            dependencies: ["SwiftMoneyLocalization"]
        ),
        .testTarget(
            name: "SwiftMoneyFoundationTests",
            dependencies: ["SwiftMoneyFoundation", "SwiftMoneyFormatMatrix", "SwiftMoneyLocalization"]
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
            dependencies: ["CLDRLocaleIdentifiers"]
        ),
        .testTarget(
            name: "CLDRLocaleSkipsTests",
            dependencies: ["CLDRLocaleSkips", "CLDRCurrencyPatterns", "SwiftMoneyLocalization"]
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
