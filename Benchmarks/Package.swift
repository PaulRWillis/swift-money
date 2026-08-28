// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Benchmarks",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.27.0"),
        .package(url: "https://github.com/ordo-one/FixedPoint.git", from: "2.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftMoneyBenchmarks",
            dependencies: [
                .product(name: "SwiftMoneyCore", package: "swift-money"),
                .product(name: "SwiftMoneyFoundation", package: "swift-money"),
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "FixedPointDecimal", package: "FixedPoint"),
            ],
            path: "Benchmarks/SwiftMoneyBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
    ]
)
