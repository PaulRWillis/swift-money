import Benchmark
import Foundation
import SwiftMoney

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

    // MARK: - Chained Scaling

    // A 10% discount, then 20% VAT, then 31 days of a year. Only the unrounded chain is exact: the
    // others settle, truncate or drift at every step, so the timings carry a correctness result too.

    Benchmark("MoneyOf unrounded scaling", configuration: defaultConfiguration) { benchmark in
        let vat = Ratio(7, 40)
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(amount).unrounded * vat)
            amount &+= 1
        }
    }

    Benchmark("MoneyOf unrounded chain", configuration: defaultConfiguration) { benchmark in
        let discount = Ratio(9, 10)
        let vat = Ratio(6, 5)
        let dayCount = Ratio(31, 365)
        var amount = 1

        for _ in benchmark.scaledIterations {
            let chained = GBP(amount).unrounded * discount * vat * dayCount
            blackHole(chained.rounded(.toNearestOrEven))
            amount &+= 1
        }
    }

    Benchmark("MoneyOf chain, rounding each step", configuration: defaultConfiguration) { benchmark in
        let discount = Ratio(9, 10)
        let vat = Ratio(6, 5)
        let dayCount = Ratio(31, 365)
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(
                GBP(amount)
                    .scaled(by: discount, rounding: .toNearestOrEven)
                    .scaled(by: vat, rounding: .toNearestOrEven)
                    .scaled(by: dayCount, rounding: .toNearestOrEven)
            )
            amount &+= 1
        }
    }

    Benchmark("Int chained scaling, truncating", configuration: defaultConfiguration) { benchmark in
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(amount * 9 / 10 * 6 / 5 * 31 / 365)
            amount &+= 1
        }
    }

    Benchmark("Double chained scaling", configuration: defaultConfiguration) { benchmark in
        let dayCount = 31.0 / 365.0
        var amount = 1.0

        for _ in benchmark.scaledIterations {
            blackHole((amount * 0.9 * 1.2 * dayCount).rounded())
            amount += 1.0
        }
    }

    Benchmark("Decimal chained scaling", configuration: defaultConfiguration) { benchmark in
        let discount = Decimal(9) / Decimal(10)
        let vat = Decimal(6) / Decimal(5)
        let dayCount = Decimal(31) / Decimal(365)
        var amount = 1

        for _ in benchmark.scaledIterations {
            var scaled = Decimal(amount) * discount * vat * dayCount
            var rounded = Decimal()
            NSDecimalRound(&rounded, &scaled, 0, .bankers)
            blackHole(rounded)
            amount &+= 1
        }
    }

    // Cycling through pre-built operands, so neither the addition nor the scaling that produced them
    // can be hoisted out of the loop.
    let thirds = (1 ... 16).map { GBP($0 * 100).unrounded * Ratio(1, 3) }

    Benchmark("MoneyOf unrounded addition", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(thirds[index % thirds.count] + thirds[(index &+ 1) % thirds.count])
            index &+= 1
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

    // The same split on the runtime-currency type. Both run the same algorithm, so a gap between them
    // is not arithmetic — it is what `MoneyOf` pays for being generic.
    Benchmark("Money split into 3", configuration: defaultConfiguration) { benchmark in
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(Money(amount, currency: .gbp).split(into: 3))
            amount &+= 1
        }
    }

    // What splitting costs when the hardware does it unaided, and so the floor the others are measured
    // against. A split is a division that keeps its remainder rather than discarding it.
    Benchmark("Int quotient and remainder", configuration: defaultConfiguration) { benchmark in
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(amount.quotientAndRemainder(dividingBy: 3))
            amount &+= 1
        }
    }

    // Neither of the next two is doing the same job: they divide and drop whatever will not divide
    // evenly, where a split hands the leftover unit to one of the parts. They are here as the cost of
    // the arithmetic alone, not as an equivalent.
    Benchmark("Double divided by 3", configuration: defaultConfiguration) { benchmark in
        var amount = 1.0

        for _ in benchmark.scaledIterations {
            blackHole(amount / 3.0)
            amount += 1.0
        }
    }

    Benchmark("Decimal divided by 3", configuration: defaultConfiguration) { benchmark in
        let three = Decimal(3)
        var amount = Decimal(1)

        for _ in benchmark.scaledIterations {
            blackHole(amount / three)
            amount += 1
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
