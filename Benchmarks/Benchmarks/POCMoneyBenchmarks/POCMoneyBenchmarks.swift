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

    // MARK: - What the library's own choices cost

    // `Money` throws where `MoneyOf` traps, so this is the price of typed throws — a currency check and
    // an error return path that never fires. `BenchmarkClosure` cannot throw, hence the surrounding
    // `do`; the `catch` is unreachable with matching currencies.
    Benchmark("Money addition, throwing", configuration: defaultConfiguration) { benchmark in
        var accumulated = Money(0, currency: .gbp)
        let delta = Money(1, currency: .gbp)

        do {
            for _ in benchmark.scaledIterations {
                blackHole(accumulated)
                accumulated = try accumulated + delta
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    // Reporting a remainder means constructing a `Ratio`, which reduces to lowest terms. Against
    // `scaled(by:rounding:)`, the difference is what the report itself costs.
    Benchmark("MoneyOf scaled, reporting a remainder", configuration: defaultConfiguration) { benchmark in
        let vat = Ratio(7, 40)
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(amount).scaled(by: vat))
            amount &+= 1
        }
    }

    // Construction reduces, so this measures the greatest common divisor. Denominators with many
    // factors are the expensive case, and the ones money actually uses.
    Benchmark("Ratio construction", configuration: defaultConfiguration) { benchmark in
        var numerator: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(Ratio(Ratio.Numerator(numerator % 40), 40))
            numerator &+= 1
        }
    }

    Benchmark("MoneyOf split into 3", configuration: defaultConfiguration) { benchmark in
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(amount).split(into: 3))
            amount &+= 1
        }
    }

    // A `Split` holds two groups rather than one amount per part, so iterating expands it on demand.
    // Against the split itself, this is what that expansion costs.
    Benchmark("MoneyOf split, iterating the parts", configuration: defaultConfiguration) { benchmark in
        let split = GBP(100_00).split(into: 3)
        var total = 0

        for _ in benchmark.scaledIterations {
            for part in split.amounts {
                blackHole(part)
                total &+= 1
            }
        }
        blackHole(total)
    }

    Benchmark("MoneyOf total of 10", configuration: defaultConfiguration) { benchmark in
        let amounts = (1...10).map { GBP($0 * 100) }

        for _ in benchmark.scaledIterations {
            blackHole(amounts.total())
        }
    }

    // Validation walks the string's bytes and normalizes case, so this is the boundary cost of
    // accepting a currency code from outside.
    Benchmark("CurrencyCode validation", configuration: defaultConfiguration) { benchmark in
        let codes = ["GBP", "eur", "usd", "JPY", "XBT", "LTY1"]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(CurrencyCode(string: codes[index % codes.count]))
            index &+= 1
        }
    }
}
