import Benchmark
import Foundation
import POCMoney

// Three baselines, because one number on its own says nothing. `Int` is what the type safety costs,
// `Double` is the fast answer that is wrong at scale, and `Decimal` is the exact answer that is slow.
//
// Benchmark names are distinct from the SwiftMoney target's, since results are keyed by name across a
// whole run.
let benchmarks: @Sendable () -> Void = {
    let defaultMetrics: [BenchmarkMetric] = [
        .wallClock,
        .mallocCountTotal,
        .instructions,
    ]

    let defaultConfiguration = Benchmark.Configuration(
        metrics: defaultMetrics,
        scalingFactor: .mega
    )

    // MARK: - Addition

    Benchmark("MoneyOf addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = GBP(0)
        let delta = GBP(1)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated + delta
        }
    }

    Benchmark("Int addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = 0
        let delta = 1

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated + delta
        }
    }

    Benchmark("Double addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = 0.0
        let delta = 0.01

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated + delta
        }
    }

    Benchmark("Decimal addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = Decimal.zero
        let delta = Decimal(1) / Decimal(100)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated + delta
        }
    }

    // MARK: - Subtraction

    Benchmark("MoneyOf subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = GBP(999_999_999)
        let delta = GBP(1)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated - delta
        }
    }

    Benchmark("Int subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = 999_999_999
        let delta = 1

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated - delta
        }
    }

    Benchmark("Double subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = 9_999_999.99
        let delta = 0.01

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated - delta
        }
    }

    Benchmark("Decimal subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = Decimal(999_999_999) / Decimal(100)
        let delta = Decimal(1) / Decimal(100)

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated - delta
        }
    }

    // MARK: - Scalar Multiplication

    // Cycling through a spread of factors rather than one, so the result cannot be hoisted.
    let factors = [1, 2, 3, 5, 7, 10, 13, 17, 19, 23]

    Benchmark("MoneyOf scalar multiplication", configuration: defaultConfiguration) { benchmark in
        let price = GBP(12_50)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(price * factors[index % factors.count])
            index &+= 1
        }
    }

    Benchmark("Int scalar multiplication", configuration: defaultConfiguration) { benchmark in
        let price = 12_50
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(price * factors[index % factors.count])
            index &+= 1
        }
    }

    Benchmark("Double scalar multiplication", configuration: defaultConfiguration) { benchmark in
        let price = 12.50
        let doubles = factors.map(Double.init)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(price * doubles[index % doubles.count])
            index &+= 1
        }
    }

    Benchmark("Decimal scalar multiplication", configuration: defaultConfiguration) { benchmark in
        let price = Decimal(1250) / Decimal(100)
        let decimals = factors.map { Decimal($0) }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(price * decimals[index % decimals.count])
            index &+= 1
        }
    }

    // MARK: - Scale and Round

    // 17.5% of an amount, resolved to a whole unit. The operation this library exists for, and the one
    // where the three baselines diverge most: `Int` cannot round at all, `Double` rounds a value it
    // cannot represent, and `Decimal` is exact but pays for it.

    Benchmark("MoneyOf scaled and rounded", configuration: defaultConfiguration) { benchmark in
        let vat = Ratio(7, 40)
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(amount).scaled(by: vat, rounding: .toNearestOrEven))
            amount &+= 1
        }
    }

    Benchmark("Int scaled, truncating", configuration: defaultConfiguration) { benchmark in
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(amount * 7 / 40)
            amount &+= 1
        }
    }

    Benchmark("Double scaled and rounded", configuration: defaultConfiguration) { benchmark in
        var amount = 1.0

        for _ in benchmark.scaledIterations {
            blackHole((amount * 7.0 / 40.0).rounded(.toNearestOrEven))
            amount += 1.0
        }
    }

    Benchmark("Decimal scaled and rounded", configuration: defaultConfiguration) { benchmark in
        let numerator = Decimal(7)
        let denominator = Decimal(40)
        var amount = 1

        for _ in benchmark.scaledIterations {
            var scaled = Decimal(amount) * numerator / denominator
            var rounded = Decimal()
            NSDecimalRound(&rounded, &scaled, 0, .bankers)
            blackHole(rounded)
            amount &+= 1
        }
    }

    // MARK: - Comparison

    Benchmark("MoneyOf comparison", configuration: defaultConfiguration) { benchmark in
        let a = GBP(10_00)
        let b = GBP(20_00)
        var count = 0

        for _ in benchmark.scaledIterations where a < b {
            count &+= 1
        }
        blackHole(count)
    }

    Benchmark("Int comparison", configuration: defaultConfiguration) { benchmark in
        let a = 10_00
        let b = 20_00
        var count = 0

        for _ in benchmark.scaledIterations where a < b {
            count &+= 1
        }
        blackHole(count)
    }

    Benchmark("Double comparison", configuration: defaultConfiguration) { benchmark in
        let a = 10.00
        let b = 20.00
        var count = 0

        for _ in benchmark.scaledIterations where a < b {
            count &+= 1
        }
        blackHole(count)
    }

    Benchmark("Decimal comparison", configuration: defaultConfiguration) { benchmark in
        let a = Decimal(1000) / Decimal(100)
        let b = Decimal(2000) / Decimal(100)
        var count = 0

        for _ in benchmark.scaledIterations where a < b {
            count &+= 1
        }
        blackHole(count)
    }
}
