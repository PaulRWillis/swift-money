import Benchmark
import FixedPointDecimal
import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation

// Five baselines, because one number on its own says nothing. `Int` is what the type safety costs,
// `Double` is the fast answer that is wrong at scale, and `Decimal` is the exact answer that is slow.
// `Int128` is the same storage width the scaling engine works in, so the gap to it is the cost of
// renormalizing after a multiply rather than of the wider arithmetic. `FixedPointDecimal` (ordo-one's
// Int64-backed, 8-fraction-digit type) is the closest published peer — same class of type, same
// benchmark harness — so it is the realistic yardstick for the fractional operations.
//
// Benchmark names are distinct from the SwiftMoney target's, since results are keyed by name across a
// whole run.
let benchmarks: @Sendable () -> Void = {
    let defaultMetrics: [BenchmarkMetric] = [
        .wallClock,
        .mallocCountTotal,
        .instructions,
    ]

    // Wall clock is the only metric CI can judge, since no hosted runner exposes instruction
    // counters, and the runners' own noise is 5% to 16%: comparing `main` against itself reports
    // regressions at the 5% default. 20% clears that and still catches anything worth catching,
    // the regressions this library has actually seen being tenfold and worse.
    // Allocations are judged in absolute terms and not as a percentage. On Linux the harness itself
    // allocates around sixteen times per run and jitters by two, so a 5% relative threshold flags a
    // difference of one, while what matters is an allocation appearing where there was none. A
    // per-iteration allocation would show up in the thousands, so four is a sensitive tolerance.
    let defaultThresholds: [BenchmarkMetric: BenchmarkThresholds] = [
        .wallClock: BenchmarkThresholds(
            relative: [
                .p25: 20.0,
                .p50: 20.0,
                .p75: 20.0,
            ]
        ),
        .mallocCountTotal: BenchmarkThresholds(
            absolute: [
                .p25: 4,
                .p50: 4,
                .p75: 4,
            ]
        ),
    ]

    let defaultConfiguration = Benchmark.Configuration(
        metrics: defaultMetrics,
        scalingFactor: .mega,
        thresholds: defaultThresholds
    )

    // Whatever keeps a result alive is inside every number below, so here is what it costs on its
    // own. These two are the reason the cheap operations chain their results rather than handing
    // each one to `blackHole`.
    Benchmark("Harness floor, an integer", configuration: defaultConfiguration) { benchmark in
        let value: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(value)
        }
    }

    Benchmark("Harness floor, a struct", configuration: defaultConfiguration) { benchmark in
        let value = GBP(minorUnits: 1)

        for _ in benchmark.scaledIterations {
            blackHole(value)
        }
    }

    // A result has to be kept alive or the optimizer deletes the work, and the cheapest way to do
    // that differs by type. Handing a value to `blackHole` costs 7 instructions for an integer and
    // 22 for a struct, which swamped operations costing 1, so the cheap types chain instead: each
    // operation feeds the next and only the final value reaches the harness. `Decimal` keeps the
    // barrier, because an accumulator would add a `Decimal` addition of about 7,000 instructions
    // where the barrier costs a handful.
    //
    // The operands come from an array because the optimizer folds a loop adding a constant into a
    // multiplication, and the benchmark then measures nothing: an attempt at this read zero.
    let operands = [1, 2, 3, 5, 7, 10, 13, 17, 19, 23]
    let doubleOperands: [Double] = operands.map(Double.init)
    let decimalOperands: [Decimal] = operands.map { Decimal($0) }
    let moneyOperands: [GBP] = operands.map { GBP(minorUnits: $0) }
    let int128Operands: [Int128] = operands.map { Int128($0) }
    let fixedOperands: [FixedPointDecimal] = operands.map { FixedPointDecimal(integerValue: Int64($0)) }

    Benchmark("MoneyOf addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = GBP(minorUnits: 0)
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + moneyOperands[index % moneyOperands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Int addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = 0
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + operands[index % operands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Double addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = 0.0
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + doubleOperands[index % doubleOperands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Decimal addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = Decimal.zero
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated + decimalOperands[index % decimalOperands.count]
            index &+= 1
        }
    }

    Benchmark("Int128 addition", configuration: defaultConfiguration) { benchmark in
        var accumulated: Int128 = 0
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + int128Operands[index % int128Operands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("FixedPoint addition", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(integerValue: 0)
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + fixedOperands[index % fixedOperands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("MoneyOf subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = GBP(minorUnits: 999_999_999)
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated - moneyOperands[index % moneyOperands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Int subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = 999_999_999
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated - operands[index % operands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Double subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = 999_999_999.0
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated - doubleOperands[index % doubleOperands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Decimal subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = Decimal(999_999_999)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(accumulated)
            accumulated = accumulated - decimalOperands[index % decimalOperands.count]
            index &+= 1
        }
    }

    Benchmark("Int128 subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated: Int128 = 999_999_999
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated - int128Operands[index % int128Operands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("FixedPoint subtraction", configuration: defaultConfiguration) { benchmark in
        var accumulated = FixedPointDecimal(integerValue: 999_999_999)
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated - fixedOperands[index % fixedOperands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    // Summing the products keeps each one alive without handing it to the harness, and costs every
    // variant the same addition, which the addition benchmarks above have already priced.
    Benchmark("MoneyOf scalar multiplication", configuration: defaultConfiguration) { benchmark in
        let price = GBP(minorUnits: 12_50)
        var accumulated = GBP(minorUnits: 0)
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + price * operands[index % operands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Int scalar multiplication", configuration: defaultConfiguration) { benchmark in
        let price = 12_50
        var accumulated = 0
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + price * operands[index % operands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Double scalar multiplication", configuration: defaultConfiguration) { benchmark in
        let price = 12.50
        var accumulated = 0.0
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + price * doubleOperands[index % doubleOperands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Decimal scalar multiplication", configuration: defaultConfiguration) { benchmark in
        let price = Decimal(1250) / Decimal(100)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(price * decimalOperands[index % decimalOperands.count])
            index &+= 1
        }
    }

    Benchmark("Int128 scalar multiplication", configuration: defaultConfiguration) { benchmark in
        let price: Int128 = 12_50
        var accumulated: Int128 = 0
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + price * int128Operands[index % int128Operands.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("FixedPoint scalar multiplication", configuration: defaultConfiguration) { benchmark in
        let price = FixedPointDecimal("12.50")!
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(price * fixedOperands[index % fixedOperands.count])
            index &+= 1
        }
    }

    // 17.5% of an amount, resolved to a whole unit. The operation this library exists for, and the one
    // where the baselines diverge most: `Int`/`Int128` cannot round at all (they truncate), `Double`
    // rounds a value it cannot represent, `Decimal` is exact but pays for it, and `FixedPointDecimal`
    // does the same fixed-point multiply-and-round the engine does.

    Benchmark("MoneyOf scaled and rounded", configuration: defaultConfiguration) { benchmark in
        let vat: Rate = "7/40"
        var accumulated = GBP(minorUnits: 0)
        var amount = 1

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + GBP(minorUnits: amount).applying(vat).rounded(.toNearestOrEven)
            amount &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Int scaled, truncating", configuration: defaultConfiguration) { benchmark in
        var accumulated = 0
        var amount = 1

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + amount * 7 / 40
            amount &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Int128 scaled, truncating", configuration: defaultConfiguration) { benchmark in
        let numerator: Int128 = 7, denominator: Int128 = 40
        var accumulated: Int128 = 0
        var amount: Int128 = 1

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + amount * numerator / denominator
            amount &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("Double scaled and rounded", configuration: defaultConfiguration) { benchmark in
        var accumulated = 0.0
        var amount = 1.0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + (amount * 7.0 / 40.0).rounded(.toNearestOrEven)
            amount += 1.0
        }

        blackHole(accumulated)
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

    Benchmark("FixedPoint scaled and rounded", configuration: defaultConfiguration) { benchmark in
        let vat = FixedPointDecimal("0.175")!
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole((FixedPointDecimal(integerValue: Int64(amount)) * vat).rounded(.toNearestOrEven))
            amount &+= 1
        }
    }

    // A 10% discount, then 20% VAT, then 31 days of a year. Only the unrounded chain is exact: the
    // others settle, truncate or drift at every step, so the timings carry a correctness result too.

    Benchmark("MoneyOf unrounded scaling", configuration: defaultConfiguration) { benchmark in
        let vat: Rate = "7/40"
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).unrounded * vat)
            amount &+= 1
        }
    }

    Benchmark("MoneyOf unrounded divided", configuration: defaultConfiguration) { benchmark in
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).unrounded.divided(by: 365))
            amount &+= 1
        }
    }

    Benchmark("MoneyOf unrounded chain", configuration: defaultConfiguration) { benchmark in
        let discount: Rate = "9/10"
        let vat: Rate = "6/5"
        let dayCount: Rate = "0.085"
        var amount = 1

        for _ in benchmark.scaledIterations {
            let chained = GBP(minorUnits: amount).unrounded * discount * vat * dayCount
            blackHole(chained.rounded(.toNearestOrEven))
            amount &+= 1
        }
    }

    Benchmark("MoneyOf chain, rounding each step", configuration: defaultConfiguration) { benchmark in
        let discount: Rate = "9/10"
        let vat: Rate = "6/5"
        let dayCount: Rate = "0.085"
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(
                GBP(minorUnits: amount)
                    .applying(discount).rounded(.toNearestOrEven)
                    .applying(vat).rounded(.toNearestOrEven)
                    .applying(dayCount).rounded(.toNearestOrEven)
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

    Benchmark("Int128 chained scaling, truncating", configuration: defaultConfiguration) { benchmark in
        let discountNum: Int128 = 9, discountDen: Int128 = 10
        let vatNum: Int128 = 6, vatDen: Int128 = 5
        let dayNum: Int128 = 31, dayDen: Int128 = 365
        var amount: Int128 = 1

        for _ in benchmark.scaledIterations {
            blackHole(amount * discountNum / discountDen * vatNum / vatDen * dayNum / dayDen)
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

    Benchmark("FixedPoint chained scaling", configuration: defaultConfiguration) { benchmark in
        let discount = FixedPointDecimal("0.9")!
        let vat = FixedPointDecimal("1.2")!
        let dayCount = FixedPointDecimal("0.084931506")!
        var amount = 1

        for _ in benchmark.scaledIterations {
            let scaled = FixedPointDecimal(integerValue: Int64(amount)) * discount * vat * dayCount
            blackHole(scaled.rounded(.toNearestOrEven))
            amount &+= 1
        }
    }

    // Cycling through pre-built operands, so neither the addition nor the scaling that produced them
    // can be hoisted out of the loop.
    let thirds = (1 ... 16).map { GBP(minorUnits: $0 * 100).unrounded * "0.333333333333333333" }

    Benchmark("MoneyOf unrounded addition", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(thirds[index % thirds.count] + thirds[(index &+ 1) % thirds.count])
            index &+= 1
        }
    }

    Benchmark("MoneyOf unrounded subtraction", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(thirds[index % thirds.count] - thirds[(index &+ 1) % thirds.count])
            index &+= 1
        }
    }

    // Adding a settled amount to a running unrounded total widens the settled side to `Unrounded`, the
    // shape an interest or fee accrual takes. The `-` and reversed and compound-assign forms share this
    // widen-then-add path.
    Benchmark("MoneyOf unrounded plus settled", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(thirds[index % thirds.count] + moneyOperands[index % moneyOperands.count])
            index &+= 1
        }
    }

    Benchmark("MoneyOf unrounded minus settled", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(thirds[index % thirds.count] - moneyOperands[index % moneyOperands.count])
            index &+= 1
        }
    }

    Benchmark("MoneyOf unrounded divided exactly", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(thirds[index % thirds.count].divided(byExactly: 3))
            index &+= 1
        }
    }

    // `Money.Unrounded` (the runtime-currency unrounded type) had no coverage at all. Its operands are
    // prebuilt like `thirds` so the scaling that makes them cannot be hoisted. The mismatch-checking
    // additions throw, so they take the do/catch shape; the scalings do not. The `*=`, reversed-operand,
    // and `applying` (which is `self * rate`) forms delegate to these primitives.
    let carriedThirds = (1 ... 16).map { Money(minorUnits: $0 * 100, currency: .gbp).unrounded * "0.333333333333333333" }
    let carriedVAT: Rate = "7/40"

    Benchmark("Money unrounded scaling by a rate", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(carriedThirds[index % carriedThirds.count] * carriedVAT)
            index &+= 1
        }
    }

    Benchmark("Money unrounded scaling by an integer", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(carriedThirds[index % carriedThirds.count] * 3)
            index &+= 1
        }
    }

    Benchmark("Money unrounded applying a rate", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(carriedThirds[index % carriedThirds.count].applying(carriedVAT))
            index &+= 1
        }
    }

    Benchmark("Money unrounded divided by an integer", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(carriedThirds[index % carriedThirds.count].divided(by: 365))
            index &+= 1
        }
    }

    Benchmark("Money unrounded divided exactly", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(carriedThirds[index % carriedThirds.count].divided(byExactly: 4))
            index &+= 1
        }
    }

    Benchmark("Money unrounded rounded", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(carriedThirds[index % carriedThirds.count].rounded(.toNearestOrEven))
            index &+= 1
        }
    }

    Benchmark("Money unrounded addition, throwing", configuration: defaultConfiguration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try carriedThirds[index % carriedThirds.count] + carriedThirds[(index &+ 1) % carriedThirds.count])
                index &+= 1
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    Benchmark("Money unrounded subtraction, throwing", configuration: defaultConfiguration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try carriedThirds[index % carriedThirds.count] - carriedThirds[(index &+ 1) % carriedThirds.count])
                index &+= 1
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    // Adding a settled `Money` to a running unrounded total, the runtime-currency accrual shape. The
    // reversed, `-`, and compound-assign forms share this widen-then-add path.
    Benchmark("Money unrounded plus settled, throwing", configuration: defaultConfiguration) { benchmark in
        let settled = Money(minorUnits: 1, currency: .gbp)
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try carriedThirds[index % carriedThirds.count] + settled)
                index &+= 1
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    // Two constant operands let the optimizer hoist the comparison out of the loop, leaving nothing
    // to measure, so one side cycles through the shared operands. Every variant hands `blackHole` a
    // `Bool`, so the harness costs the same in all four and what separates them is the comparison.

    Benchmark("MoneyOf comparison", configuration: defaultConfiguration) { benchmark in
        let threshold = GBP(minorUnits: 10)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(moneyOperands[index % moneyOperands.count] < threshold)
            index &+= 1
        }
    }

    Benchmark("Int comparison", configuration: defaultConfiguration) { benchmark in
        let threshold = 10
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(operands[index % operands.count] < threshold)
            index &+= 1
        }
    }

    Benchmark("Double comparison", configuration: defaultConfiguration) { benchmark in
        let threshold = 10.0
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(doubleOperands[index % doubleOperands.count] < threshold)
            index &+= 1
        }
    }

    Benchmark("Decimal comparison", configuration: defaultConfiguration) { benchmark in
        let threshold = Decimal(10)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(decimalOperands[index % decimalOperands.count] < threshold)
            index &+= 1
        }
    }

    Benchmark("Int128 comparison", configuration: defaultConfiguration) { benchmark in
        let threshold: Int128 = 10
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(int128Operands[index % int128Operands.count] < threshold)
            index &+= 1
        }
    }

    Benchmark("FixedPoint comparison", configuration: defaultConfiguration) { benchmark in
        let threshold = FixedPointDecimal(integerValue: 10)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(fixedOperands[index % fixedOperands.count] < threshold)
            index &+= 1
        }
    }

    // `description` is what `print`, interpolation and a failing test all reach for, so it runs in
    // places nobody profiles. Every variant hands `blackHole` a `String`, so the harness costs the
    // same in each and what separates them is the rendering.
    let carriedPounds = operands.map { Money(minorUnits: $0, currency: .gbp) }

    Benchmark("MoneyOf description", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(moneyOperands[index % moneyOperands.count].description)
            index &+= 1
        }
    }

    Benchmark("Money description", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(carriedPounds[index % carriedPounds.count].description)
            index &+= 1
        }
    }

    Benchmark("Int description", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(operands[index % operands.count].description)
            index &+= 1
        }
    }

    Benchmark("Double description", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(doubleOperands[index % doubleOperands.count].description)
            index &+= 1
        }
    }

    Benchmark("Decimal description", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(decimalOperands[index % decimalOperands.count].description)
            index &+= 1
        }
    }

    // Every variant hands `blackHole` a `Bool`, so the harness costs the same in each and what
    // separates them is the parse.
    //
    // Every variant also reads the same three digits, since parsing costs more the more digits it
    // is given: `Int64` reads 91 over three and 70 over one or two.
    let amountStrings = operands.map { "GBP 4.\($0 < 10 ? "0" : "")\($0)" }
    let bareStrings = operands.map { "4.\($0 < 10 ? "0" : "")\($0)" }
    let minorUnitStrings = operands.map { "4\($0 < 10 ? "0" : "")\($0)" }

    Benchmark("Money parsing", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money(string: amountStrings[index % amountStrings.count]) != nil)
            index &+= 1
        }
    }

    Benchmark("MoneyOf parsing", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(GBP(string: bareStrings[index % bareStrings.count]) != nil)
            index &+= 1
        }
    }

    Benchmark("Int parsing", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Int64(minorUnitStrings[index % minorUnitStrings.count]) != nil)
            index &+= 1
        }
    }

    Benchmark("Double parsing", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Double(bareStrings[index % bareStrings.count]) != nil)
            index &+= 1
        }
    }

    Benchmark("Decimal parsing", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Decimal(string: bareStrings[index % bareStrings.count]) != nil)
            index &+= 1
        }
    }

    // The parsing rows above use small positive amounts. These dimension the amount parser across scale
    // and sign: large amounts near `Int64.max` minor units, which exercise the per-digit overflow guards,
    // and negative amounts through the sign branch. Pinned not-nil, since a value past the range parses to
    // nil and would measure the failure path.
    let largeAmountStrings = operands.map { "922337203685477\($0 < 10 ? "0" : "")\($0)" }
    let negativeAmountStrings = operands.map { "-4.\($0 < 10 ? "0" : "")\($0)" }
    precondition(largeAmountStrings.allSatisfy { GBP(string: $0) != nil },
                 "the large amount fixtures must parse")

    Benchmark("MoneyOf parsing a large amount", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(GBP(string: largeAmountStrings[index % largeAmountStrings.count]) != nil)
            index &+= 1
        }
    }

    Benchmark("MoneyOf parsing a negative amount", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(GBP(string: negativeAmountStrings[index % negativeAmountStrings.count]) != nil)
            index &+= 1
        }
    }

    // The Foundation bridge between `Decimal` and money. `MoneyOf parsing` and `MoneyOf
    // description` are the string peers: the gap between a pair is what the `Decimal` route costs
    // against the string route. Every variant hands `blackHole` a `Bool`, so the harness costs the
    // same in each.
    let decimalAmounts = bareStrings.compactMap { Decimal(string: $0) }

    Benchmark("MoneyOf from Decimal", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(GBP(majorUnits: decimalAmounts[index % decimalAmounts.count]) != nil)
            index &+= 1
        }
    }

    Benchmark("Money from Decimal", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money(majorUnits: decimalAmounts[index % decimalAmounts.count], currency: .gbp) != nil)
            index &+= 1
        }
    }

    // The negative-sign branch of the Decimal bridge.
    let negativeDecimalAmounts = negativeAmountStrings.compactMap { Decimal(string: $0) }

    Benchmark("MoneyOf from a negative Decimal", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(GBP(majorUnits: negativeDecimalAmounts[index % negativeDecimalAmounts.count]) != nil)
            index &+= 1
        }
    }

    // `isFinite` rather than `!= nil`, this direction no longer being failable. What matters is that
    // every variant still hands `blackHole` a `Bool`.
    Benchmark("Decimal from MoneyOf", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Decimal(majorUnitsOf: moneyOperands[index % moneyOperands.count]).isFinite)
            index &+= 1
        }
    }

    // Reading the minor-unit count back out to an integer — the peer of the Decimal read-out above.
    Benchmark("Int from MoneyOf minor units", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Int(minorUnitsOf: moneyOperands[index % moneyOperands.count]))
            index &+= 1
        }
    }

    // The `FormatStyle` and `ParseStrategy` surface delegates to Foundation's
    // `Decimal.FormatStyle.Currency`, so the `Decimal` rows here run the exact engine underneath:
    // the gap between a pair is what the library adds on top of ICU. Part of that gap is a
    // rebuild: the library builds the underlying `Decimal` style again on every format call, and
    // its parse strategy again on every parse call. The locale is pinned to `en_GB`, so the
    // numbers do not depend on the machine's locale setting. Styles and strategies are built
    // once, outside the loops, because the rows measure the call and not the setup. Every variant
    // reads the same digits as `decimalAmounts`, 4.01 to 4.23.
    let britishEnglish = Locale(identifier: "en_GB")
    let typedCurrencyStyle = GBP.FormatStyle().locale(britishEnglish)
    let runtimeCurrencyStyle = Money.FormatStyle().locale(britishEnglish)
    // `fractionLength(2)` mirrors the precision the library pins internally, so the peer style is
    // configuration-identical to the one the library builds. It is not redundant: dropping it
    // silently unmatches the peer.
    let decimalCurrencyStyle = Decimal.FormatStyle.Currency(code: "GBP", locale: britishEnglish)
        .precision(.fractionLength(2))
    let fourPoundAmounts = operands.map { GBP(minorUnits: 4_00 + $0) }
    let carriedFourPoundAmounts = operands.map { Money(minorUnits: 4_00 + $0, currency: .gbp) }

    // Every format variant hands `blackHole` a `String`, so the harness costs the same in each.
    Benchmark("MoneyOf currency formatting, en_GB", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(typedCurrencyStyle.format(fourPoundAmounts[index % fourPoundAmounts.count]))
            index &+= 1
        }
    }

    Benchmark("Money currency formatting, en_GB", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeCurrencyStyle.format(carriedFourPoundAmounts[index % carriedFourPoundAmounts.count]))
            index &+= 1
        }
    }

    Benchmark("Decimal currency formatting, en_GB", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(decimalCurrencyStyle.format(decimalAmounts[index % decimalAmounts.count]))
            index &+= 1
        }
    }

    // Formatting with a rounding increment (five smallest units, as Swiss cash rounding uses) runs the
    // whole snap-to-increment computation the plain format skips. The amounts carry nonzero remainders so
    // the rounding always has work to do.
    let fivePenceRoundedStyle = typedCurrencyStyle.rounded(increment: 5)

    Benchmark("MoneyOf currency formatting with an increment, en_GB", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(fivePenceRoundedStyle.format(fourPoundAmounts[index % fourPoundAmounts.count]))
            index &+= 1
        }
    }

    // Every parse variant hands `blackHole` a `Bool`, so the harness costs the same in each. All read the
    // same strings, `bareStrings` behind a pound sign. The runtime route, `parseStrategy(for:)`, has its
    // own row below; it shares the typed parse path and only the final construction differs.
    let poundStrings = bareStrings.map { "£" + $0 }
    let typedCurrencyStrategy = typedCurrencyStyle.parseStrategy
    let decimalCurrencyStrategy = decimalCurrencyStyle.parseStrategy

    // A failed parse also walks ICU and reports a plausible number, so the zero scan cannot catch
    // a fixture that stops parsing. These pin the success path once, at registration.
    precondition((try? typedCurrencyStrategy.parse(poundStrings[0])) != nil,
                 "the typed strategy must parse the fixtures")
    precondition((try? decimalCurrencyStrategy.parse(poundStrings[0])) != nil,
                 "the Decimal strategy must parse the fixtures")

    Benchmark("MoneyOf currency parsing, en_GB", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole((try? typedCurrencyStrategy.parse(poundStrings[index % poundStrings.count])) != nil)
            index &+= 1
        }
    }

    Benchmark("Decimal currency parsing, en_GB", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole((try? decimalCurrencyStrategy.parse(poundStrings[index % poundStrings.count])) != nil)
            index &+= 1
        }
    }

    // The runtime-currency parse route, `parseStrategy(for:)`. It shares the typed parse path and differs
    // only in the final construction, so it reads close to the typed row above — measured here to close
    // the coverage gap, not because a large gap is expected.
    let runtimeCurrencyStrategy = runtimeCurrencyStyle.parseStrategy(for: .gbp)
    precondition((try? runtimeCurrencyStrategy.parse(poundStrings[0])) != nil,
                 "the runtime strategy must parse the fixtures")

    Benchmark("Money currency parsing, en_GB", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole((try? runtimeCurrencyStrategy.parse(poundStrings[index % poundStrings.count])) != nil)
            index &+= 1
        }
    }

    // A spread across the alphabet, because the table is searched in order: AED is the first case
    // and ZWG the last.
    let lookupCodes: [CurrencyCode] = ["AED", "EUR", "GBP", "JPY", "MRU", "USD", "ZWG"]

    Benchmark("ISO currency lookup", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Currency(iso: lookupCodes[index % lookupCodes.count]))
            index &+= 1
        }
    }

    // Building a custom currency — a code the library does not ship, so it takes the branch that skips the
    // shipped-table scale check (the conflict branch is priced by "Money addition, separately built
    // currencies"). Cycles codes so the construction cannot be hoisted.
    let customCodes: [CurrencyCode] = ["LTY", "PTS", "GLD", "XYZ", "QQQ", "ZZZ"]

    Benchmark("Currency construction, custom", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Currency(code: customCodes[index % customCodes.count], unitScale: 1))
            index &+= 1
        }
    }

    // `Money` throws where `MoneyOf` traps, so this is the price of typed throws: a currency check and
    // an error return path that never fires. `BenchmarkClosure` cannot throw, hence the surrounding
    // `do`; the `catch` is unreachable with matching currencies.
    Benchmark("Money addition, throwing", configuration: defaultConfiguration) { benchmark in
        var accumulated = Money(minorUnits: 0, currency: .gbp)
        let delta = Money(minorUnits: 1, currency: .gbp)

        do {
            for _ in benchmark.scaledIterations {
                blackHole(accumulated)
                accumulated = try accumulated + delta
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    // The benchmark above adds two amounts sharing one `Currency.gbp`, which is the cheapest case a
    // currency check ever sees. Amounts decoded from a payload or read from a database carry equal
    // currencies built separately, and that is what this measures. Built through the failable
    // initialiser at GBP's own scale, so the values always exist.
    guard
        let firstPounds = Currency(code: "GBP", unitScale: 100),
        let secondPounds = Currency(code: "GBP", unitScale: 100)
    else {
        preconditionFailure("GBP at 100 is a valid currency")
    }
    let separatelyBuiltPounds = [firstPounds, secondPounds]

    Benchmark("Money addition, separately built currencies", configuration: defaultConfiguration) { benchmark in
        var accumulated = Money(minorUnits: 0, currency: separatelyBuiltPounds[0])
        let delta = Money(minorUnits: 1, currency: separatelyBuiltPounds[1])

        do {
            for _ in benchmark.scaledIterations {
                blackHole(accumulated)
                accumulated = try accumulated + delta
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }


    // The runtime-currency twins of the typed `MoneyOf` arithmetic above. Each shares one `Currency.gbp`
    // instance, the cheapest a currency check sees; the separately-built case is priced once at the row
    // above. `Money` arithmetic throws on a currency mismatch, so these take the do/catch shape and a
    // per-iteration barrier rather than chaining.
    let poundOperands = operands.map { Money(minorUnits: $0, currency: .gbp) }

    Benchmark("Money subtraction, throwing", configuration: defaultConfiguration) { benchmark in
        var accumulated = Money(minorUnits: 999_999_999, currency: .gbp)
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(accumulated)
                accumulated = try accumulated - poundOperands[index % poundOperands.count]
                index &+= 1
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    Benchmark("Money addition in place, throwing", configuration: defaultConfiguration) { benchmark in
        var accumulated = Money(minorUnits: 0, currency: .gbp)
        let delta = Money(minorUnits: 1, currency: .gbp)

        do {
            for _ in benchmark.scaledIterations {
                blackHole(accumulated)
                try accumulated += delta
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    Benchmark("Money scalar multiplication, amount times integer", configuration: defaultConfiguration) { benchmark in
        let price = Money(minorUnits: 12_50, currency: .gbp)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(price * operands[index % operands.count])
            index &+= 1
        }
    }

    Benchmark("Money scalar multiplication, integer times amount", configuration: defaultConfiguration) { benchmark in
        let price = Money(minorUnits: 12_50, currency: .gbp)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(operands[index % operands.count] * price)
            index &+= 1
        }
    }

    Benchmark("Money applying a rate", configuration: defaultConfiguration) { benchmark in
        let vat: Rate = "7/40"
        var amount: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(Money(minorUnits: amount, currency: .gbp).applying(vat))
            amount &+= 1
        }
    }

    Benchmark("Money is less than, throwing", configuration: defaultConfiguration) { benchmark in
        let threshold = Money(minorUnits: 10, currency: .gbp)
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try poundOperands[index % poundOperands.count].isLessThan(threshold))
                index &+= 1
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    Benchmark("Money proportion, throwing", configuration: defaultConfiguration) { benchmark in
        let whole = Money(minorUnits: 100_00, currency: .gbp)
        var amount: Int64 = 1

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try Money(minorUnits: amount, currency: .gbp).proportion(of: whole))
                amount &+= 1
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }


    // Divides the two amounts into a rate. The whole is fixed, as a budget or an order total would be.
    Benchmark("MoneyOf proportion", configuration: defaultConfiguration) { benchmark in
        let whole = GBP(minorUnits: 100_00)
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).proportion(of: whole))
            amount &+= 1
        }
    }

    // Large amounts on both sides, where the division works at full width. A proportion of a few pence
    // against a vast total is the cheap case the benchmark above measures; this is the dear one.
    Benchmark("MoneyOf proportion of large amounts", configuration: defaultConfiguration) { benchmark in
        let whole = GBP.max
        var amount = Int64.max / 3

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).proportion(of: whole))
            amount &+= 1
        }
    }

    // The validation gate for a weighted split: the emptiness, sign, zero and overflow checks,
    // plus one pass to sum. Splitting itself never re-checks, so this cost is paid once per
    // weights value however many amounts it splits.
    Benchmark("Weights construction", configuration: defaultConfiguration) { benchmark in
        var weight = 1

        for _ in benchmark.scaledIterations {
            blackHole(Weights([Weight(integerLiteral: weight % 100), 30, 10]))
            weight &+= 1
        }
    }

    Benchmark("MoneyOf split into 3", configuration: defaultConfiguration) { benchmark in
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).split(into: 3))
            amount &+= 1
        }
    }

    // The same split on the runtime-currency type. Both run the same algorithm, so a gap between them
    // is not arithmetic: it is what `MoneyOf` pays for being generic.
    Benchmark("Money split into 3", configuration: defaultConfiguration) { benchmark in
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(Money(minorUnits: amount, currency: .gbp).split(into: 3))
            amount &+= 1
        }
    }

    // The weighted split's general path: most amounts leave minor units over, so this includes
    // ranking the remainders and distributing the leftover. The weights are built once, as a
    // caller splitting many amounts by one recipe would build them.
    Benchmark("MoneyOf split by weights", configuration: defaultConfiguration) { benchmark in
        let weights: Weights = [60, 30, 10]
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).split(by: weights))
            amount &+= 1
        }
    }

    // The same split on the runtime-currency type. Both run the same algorithm, so a gap between
    // them is not arithmetic: it is what `MoneyOf` pays for being generic.
    Benchmark("Money split by weights", configuration: defaultConfiguration) { benchmark in
        let weights: Weights = [60, 30, 10]
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(Money(minorUnits: amount, currency: .gbp).split(by: weights))
            amount &+= 1
        }
    }

    // Every amount here divides exactly, so nothing is left to distribute. Today the remainder
    // ranking still runs on this path, which is why it is measured apart from the general one.
    Benchmark("MoneyOf split by weights that divide exactly", configuration: defaultConfiguration) { benchmark in
        let weights: Weights = [3, 2, 1]
        var amount = 6

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).split(by: weights))
            amount &+= 6
        }
    }

    // The accessors a caller reads after splitting. Each maps the parts into a fresh array every call —
    // that allocation is the operation, so the row blackHoles the array rather than chaining, and its
    // baseline captures the allocation as the ±4 tolerance measures a change against.
    let weightedSplitToRead = GBP(minorUnits: 100_00).split(by: [60, 30, 10])

    Benchmark("WeightedSplit amounts", configuration: defaultConfiguration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(weightedSplitToRead.amounts)
        }
    }

    Benchmark("WeightedSplit weights", configuration: defaultConfiguration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(weightedSplitToRead.weights)
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
        let split = GBP(minorUnits: 100_00).split(into: 3)
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
        let amounts = (1...10).map { GBP(minorUnits: $0 * 100) }

        for _ in benchmark.scaledIterations {
            blackHole(amounts.total())
        }
    }

    // The runtime-currency total throws on a currency mismatch and returns an optional; the two unrounded
    // totals sum the round-once type (the interest-accrual pattern). Peers of "MoneyOf total of 10".
    Benchmark("Money total of 10, throwing", configuration: defaultConfiguration) { benchmark in
        let amounts = (1...10).map { Money(minorUnits: $0 * 100, currency: .gbp) }

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try amounts.total())
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    Benchmark("MoneyOf unrounded total of 10", configuration: defaultConfiguration) { benchmark in
        let amounts = (1...10).map { GBP(minorUnits: $0 * 100).unrounded }

        for _ in benchmark.scaledIterations {
            blackHole(amounts.total())
        }
    }

    Benchmark("Money unrounded total of 10, throwing", configuration: defaultConfiguration) { benchmark in
        let amounts = (1...10).map { Money(minorUnits: $0 * 100, currency: .gbp).unrounded }

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try amounts.total())
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
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

    // The longest codes the type accepts, so the packing loop runs its full length — the scale analog for
    // a code, where a numeric value would vary by magnitude.
    Benchmark("CurrencyCode validation, eight characters", configuration: defaultConfiguration) { benchmark in
        let codes = ["ABCDEFGH", "abcdefgh", "12345678", "GBPUSDXY", "lty12345", "ZzZzZzZz"]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(CurrencyCode(string: codes[index % codes.count]))
            index &+= 1
        }
    }

    // `JSONEncoder` and `JSONDecoder` cost thousands of instructions, so a round trip through them
    // says almost nothing about this library. Three measurements separate the two costs:
    //
    // 1. A round trip through JSON, which is the number a caller pays and the only one comparable
    //    with another library.
    // 2. The same round trip for a bare `String` of the same content, so the difference is what the
    //    money conformance adds.
    // 3. `encode(to:)` alone, through `RecordingEncoder`, with no JSON in the number at all.
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()

    let fieldsEncoder = JSONEncoder()
    let fieldsDecoder = JSONDecoder()

    fieldsEncoder.userInfo[.moneyCodingFormat] = MoneyCodingFormat.fields
    fieldsDecoder.userInfo[.moneyCodingFormat] = MoneyCodingFormat.fields

    // The same bytes for both the money row and the control row, so only the type they decode into
    // differs. The operands are whole pence, so each amount writes as "GBP 1" and reads back as one.
    let codedStringPayloads = operands.map { Data("\"GBP \($0)\"".utf8) }
    let fieldPayloads = operands.map { Data(#"{"currency":"GBP","amount":\#($0)}"#.utf8) }

    Benchmark("Money JSON encode", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try jsonEncoder.encode(moneyOperands[index % moneyOperands.count]))
            index &+= 1
        }
    }

    Benchmark("Money JSON decode", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try jsonDecoder.decode(GBP.self, from: codedStringPayloads[index % codedStringPayloads.count]))
            index &+= 1
        }
    }

    Benchmark("Money JSON encode, two fields", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try fieldsEncoder.encode(moneyOperands[index % moneyOperands.count]))
            index &+= 1
        }
    }

    Benchmark("Money JSON decode, two fields", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try fieldsDecoder.decode(GBP.self, from: fieldPayloads[index % fieldPayloads.count]))
            index &+= 1
        }
    }

    // The other wire shapes. Major units renders the amount in the currency's major unit (a decimal
    // divide on encode); amount-only writes the bare number and so needs a type that names its currency —
    // a runtime `Money` throws for it by design, so this row uses typed `GBP`.
    let majorUnitsEncoder = JSONEncoder()
    majorUnitsEncoder.userInfo[.moneyCodingFormat] = MoneyCodingFormat.codedString(.majorUnits)
    let amountOnlyEncoder = JSONEncoder()
    amountOnlyEncoder.userInfo[.moneyCodingFormat] = MoneyCodingFormat.amountOnly

    Benchmark("Money JSON encode, major units", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try majorUnitsEncoder.encode(moneyOperands[index % moneyOperands.count]))
            index &+= 1
        }
    }

    Benchmark("MoneyOf JSON encode, amount only", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try amountOnlyEncoder.encode(fourPoundAmounts[index % fourPoundAmounts.count]))
            index &+= 1
        }
    }

    // The control. `ControlAmount` takes the same route through the coder as money and does no money
    // work, so the difference between the two rows is what this library contributes.
    Benchmark("Control JSON encode", configuration: defaultConfiguration) { benchmark in
        let controls = operands.map { ControlAmount("GBP \($0)") }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try jsonEncoder.encode(controls[index % controls.count]))
            index &+= 1
        }
    }

    Benchmark("Control JSON decode", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try jsonDecoder.decode(ControlAmount.self, from: codedStringPayloads[index % codedStringPayloads.count]))
            index &+= 1
        }
    }

    // The peer measurement, in this harness rather than quoted from another suite.
    Benchmark("Decimal JSON encode", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try jsonEncoder.encode(decimalOperands[index % decimalOperands.count]))
            index &+= 1
        }
    }

    Benchmark("Decimal JSON decode", configuration: defaultConfiguration) { benchmark in
        let payloads = operands.map { Data("\($0)".utf8) }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try jsonDecoder.decode(Decimal.self, from: payloads[index % payloads.count]))
            index &+= 1
        }
    }

    // What the conformance costs with no coder around it.
    Benchmark("Money encode, no coder", configuration: defaultConfiguration) { benchmark in
        let recorder = RecordingEncoder()
        var index = 0

        for _ in benchmark.scaledIterations {
            try moneyOperands[index % moneyOperands.count].encode(to: recorder)
            blackHole(recorder.text)
            index &+= 1
        }
    }

    Benchmark("Money encode, no coder, two fields", configuration: defaultConfiguration) { benchmark in
        let recorder = RecordingEncoder(format: .fields)
        var index = 0

        for _ in benchmark.scaledIterations {
            try moneyOperands[index % moneyOperands.count].encode(to: recorder)
            blackHole(recorder.integer)
            index &+= 1
        }
    }

    // The binary serializer: the Embedded-safe, allocation-free counterpart to the JSON rows above.
    // Fifteen fixed bytes, no coder and no `String`, so it sits orders of magnitude below every
    // `Money JSON` row and allocates nothing. `InlineArray` exists only on the newest systems, so these
    // rows register there and are absent elsewhere — there is no serializer to price on older ones.
    if #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) {
        let encodedPounds = moneyOperands.map { $0.bytes }

        Benchmark("MoneyOf bytes encode", configuration: defaultConfiguration) { benchmark in
            var index = 0

            for _ in benchmark.scaledIterations {
                blackHole(moneyOperands[index % moneyOperands.count].bytes)
                index &+= 1
            }
        }

        Benchmark("MoneyOf bytes decode", configuration: defaultConfiguration) { benchmark in
            var index = 0

            for _ in benchmark.scaledIterations {
                blackHole(GBP(bytes: encodedPounds[index % encodedPounds.count]))
                index &+= 1
            }
        }

        // The runtime-currency decode rebuilds the `Currency` from the code and scale, where the typed
        // decode above only checks them, so this prices that rebuild.
        Benchmark("Money bytes decode", configuration: defaultConfiguration) { benchmark in
            var index = 0

            for _ in benchmark.scaledIterations {
                blackHole(Money(bytes: encodedPounds[index % encodedPounds.count]))
                index &+= 1
            }
        }

        // The unrounded serializer, twenty-three bytes. Operands are the prebuilt fractional `thirds`,
        // whose fraction the encoding must carry. `unroundedBytes` writes a settled amount straight into
        // this form.
        let encodedThirds = thirds.map { $0.bytes }
        let encodedCarriedThirds = carriedThirds.map { $0.bytes }

        Benchmark("MoneyOf Unrounded bytes encode", configuration: defaultConfiguration) { benchmark in
            var index = 0

            for _ in benchmark.scaledIterations {
                blackHole(thirds[index % thirds.count].bytes)
                index &+= 1
            }
        }

        Benchmark("MoneyOf Unrounded bytes decode", configuration: defaultConfiguration) { benchmark in
            var index = 0

            for _ in benchmark.scaledIterations {
                blackHole(GBP.Unrounded(bytes: encodedThirds[index % encodedThirds.count]))
                index &+= 1
            }
        }

        Benchmark("Money Unrounded bytes decode", configuration: defaultConfiguration) { benchmark in
            var index = 0

            for _ in benchmark.scaledIterations {
                blackHole(Money.Unrounded(bytes: encodedCarriedThirds[index % encodedCarriedThirds.count]))
                index &+= 1
            }
        }

        Benchmark("MoneyOf unroundedBytes", configuration: defaultConfiguration) { benchmark in
            var index = 0

            for _ in benchmark.scaledIterations {
                blackHole(moneyOperands[index % moneyOperands.count].unroundedBytes)
                index &+= 1
            }
        }
    }

    // Rate is the fixed-point engine's first public consumer, so these are where its cost first shows.
    // Basis points and percent are significand construction; the string forms add parsing, and the
    // fraction form runs the divide. Double and Decimal parsing are the peers for the string forms.
    Benchmark("Rate from basis points", configuration: defaultConfiguration) { benchmark in
        var bp = 1

        for _ in benchmark.scaledIterations {
            blackHole(Rate.basisPoints(bp % 10_000))
            bp &+= 1
        }
    }

    Benchmark("Rate from percent", configuration: defaultConfiguration) { benchmark in
        var percent = 1

        for _ in benchmark.scaledIterations {
            blackHole(Rate.percent(percent % 100))
            percent &+= 1
        }
    }

    let decimalStrings = operands.map { "0.0\($0)" }
    let percentStrings = operands.map { "\($0).5%" }
    let fractionStrings = operands.map { "1/\($0)" }

    Benchmark("Rate from a decimal string", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Rate(string: decimalStrings[index % decimalStrings.count]))
            index &+= 1
        }
    }

    Benchmark("Rate from a percent string", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Rate(string: percentStrings[index % percentStrings.count]))
            index &+= 1
        }
    }

    Benchmark("Rate from a fraction string", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Rate(string: fractionStrings[index % fractionStrings.count]))
            index &+= 1
        }
    }

    // The parse rows above are all small positive values. These dimension the same decimal parser (which
    // the percent form also runs) across scale and sign: values near the representable bound (about
    // ±1.7 × 10²⁰), and negative values through the sign branch. The large strings are pinned not-nil at
    // registration, since a value past the bound parses to nil and would measure the failure path.
    let largeDecimalStrings = operands.map { "1234567890123456\($0)" }
    let negativeDecimalStrings = operands.map { "-0.0\($0)" }
    let negativeFractionStrings = operands.map { "-1/\($0)" }
    precondition(largeDecimalStrings.allSatisfy { Rate(string: $0) != nil },
                 "the large decimal fixtures must parse")

    Benchmark("Rate from a large decimal string", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Rate(string: largeDecimalStrings[index % largeDecimalStrings.count]))
            index &+= 1
        }
    }

    Benchmark("Rate from a negative decimal string", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Rate(string: negativeDecimalStrings[index % negativeDecimalStrings.count]))
            index &+= 1
        }
    }

    Benchmark("Rate from a negative fraction string", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Rate(string: negativeFractionStrings[index % negativeFractionStrings.count]))
            index &+= 1
        }
    }

    // The literal form runs the same parse plus an exactness check that traps on an inexact value, so its
    // fixtures must be exactly representable — all terminating binary-free decimals here. Pinned not-nil,
    // and the literals below trap at registration anyway if any were inexact.
    let exactRateLiterals = ["0.5", "0.25", "0.125", "0.2", "0.05", "0.8", "0.4", "0.64", "0.1", "0.32"]
    precondition(exactRateLiterals.allSatisfy { Rate(string: $0) != nil },
                 "the rate literal fixtures must parse")

    Benchmark("Rate from a string literal", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Rate(stringLiteral: exactRateLiterals[index % exactRateLiterals.count]))
            index &+= 1
        }
    }

    Benchmark("Double from a decimal string", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Double(decimalStrings[index % decimalStrings.count]))
            index &+= 1
        }
    }

    Benchmark("Decimal from a decimal string", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Decimal(string: decimalStrings[index % decimalStrings.count]))
            index &+= 1
        }
    }

    let rateOperands = operands.map { Rate.basisPoints($0 * 137) }

    Benchmark("Rate to whole basis points", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(rateOperands[index % rateOperands.count].wholeBasisPoints)
            index &+= 1
        }
    }

    Benchmark("Rate to basis points, rounded", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(rateOperands[index % rateOperands.count].basisPoints(rounding: .toNearestOrEven))
            index &+= 1
        }
    }

    Benchmark("Rate from a Double", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Rate(approximating: doubleOperands[index % doubleOperands.count] / 100))
            index &+= 1
        }
    }

    // A single-hop conversion: scale the amount by the rate and keep it unrounded. Against Double and
    // Decimal doing the same multiply, this is what the exact fixed-point path costs.
    //
    // The rate is a literal, which traps if it is ever not a valid rate; the exchange rate is built at
    // registration and fails loudly, rather than an `if let` that would silently drop this row — the
    // only coverage `converted(using:)` has.
    let eurGbpRate: Rate = "0.8765262907"
    guard let eurGbp = ExchangeRate<Currencies.EUR, Currencies.GBP>(eurGbpRate) else {
        preconditionFailure("0.8765262907 is a positive EUR/GBP rate")
    }

    Benchmark("MoneyOf converted", configuration: defaultConfiguration) { benchmark in
        var amount: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(EUR(minorUnits: amount).converted(using: eurGbp))
            amount &+= 1
        }
    }

    let eurUsdRate: Rate = "1.1"
    let usdGbpRate: Rate = "0.8"
    guard let eurUsd = ExchangeRate<Currencies.EUR, Currencies.USD>(eurUsdRate),
          let usdGbp = ExchangeRate<Currencies.USD, Currencies.GBP>(usdGbpRate) else {
        preconditionFailure("1.1 and 0.8 are positive rates")
    }

    Benchmark("ExchangeRate crossed", configuration: defaultConfiguration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(eurUsd.crossed(with: usdGbp))
        }
    }

    // Applying a provider's spread to a mid-market rate — the customer-rate step. The margin is built at
    // registration (it is failable), like the rates above.
    guard let providerMargin = Margin(.percent(2)) else {
        preconditionFailure("2% is a valid margin")
    }

    Benchmark("ExchangeRate applying a margin", configuration: defaultConfiguration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(eurGbp.applyingMargin(providerMargin))
        }
    }

    // Constructing the margin itself: validation that the rate is in [0, 1). Cycles the prebuilt rates so
    // the construction cannot be hoisted.
    Benchmark("Margin construction", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Margin(rateOperands[index % rateOperands.count]))
            index &+= 1
        }
    }

    let rateAsDouble = 0.8765262907

    Benchmark("Double multiplied by a rate", configuration: defaultConfiguration) { benchmark in
        var amount = 1.0

        for _ in benchmark.scaledIterations {
            blackHole(amount * rateAsDouble)
            amount += 1.0
        }
    }

    Benchmark("Decimal multiplied by a rate", configuration: defaultConfiguration) { benchmark in
        let rate = Decimal(string: "0.8765262907") ?? .zero
        var amount = Decimal(1)

        for _ in benchmark.scaledIterations {
            blackHole(amount * rate)
            amount += 1
        }
    }

    // A sub-minor-unit tariff resolved to a total. No Int/Double/Decimal peer: this is a money-domain
    // operation (a price finer than a minor unit, kept exact until settled), so it stands alone.
    let tariff = UnitPrice<Currencies.GBP, String>(GBP.Unrounded(majorUnits: "0.023"), per: "kWh")

    Benchmark("UnitPrice total for a whole quantity", configuration: defaultConfiguration) { benchmark in
        var quantity: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(tariff.total(for: quantity))
            quantity &+= 1
        }
    }

    // A literal quantity, which traps if it is ever not a valid rate, rather than an `if let` that would
    // silently drop this row.
    let fractionalQuantity: Rate = "350.5"

    Benchmark("UnitPrice total for a fractional quantity", configuration: defaultConfiguration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(tariff.total(for: fractionalQuantity))
        }
    }

    // Edge cases: value-type accessors and arithmetic that do real work but had no row. These are not on
    // the hot path, but a regression in any of them would otherwise go unseen.

    // `Split.count` switches on the split shape and converts, unlike the trivial stored count elsewhere.
    let unevenSplit = GBP(minorUnits: 100_00).split(into: 3)

    Benchmark("Split counting the parts", configuration: defaultConfiguration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(unevenSplit.count)
        }
    }

    // `UnitScale(exactly:)` runs the factor-out-twos-and-fives reduction, so it does real validation work,
    // unlike the trivial >= 1 checks of PartCount and RoundingIncrement.
    Benchmark("UnitScale construction", configuration: defaultConfiguration) { benchmark in
        let scales: [Int64] = [1, 10, 100, 1_000, 10_000, 100_000]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(UnitScale(exactly: scales[index % scales.count]))
            index &+= 1
        }
    }

    // Building an unrounded amount from fractional major units, which multiplies by the currency's scale.
    Benchmark("MoneyOf unrounded from major units", configuration: defaultConfiguration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(GBP.Unrounded(majorUnits: "0.023"))
        }
    }

    // Negation and magnitude read from a signed operand array so the optimizer cannot fold them and so
    // `magnitude` has a sign to strip.
    let signedOperands = operands.enumerated().map { GBP(minorUnits: $0.isMultiple(of: 2) ? Int64($1) : -Int64($1)) }

    Benchmark("MoneyOf negation", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(-signedOperands[index % signedOperands.count])
            index &+= 1
        }
    }

    Benchmark("MoneyOf magnitude", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(signedOperands[index % signedOperands.count].magnitude)
            index &+= 1
        }
    }

    Benchmark("MoneyOf is multiple", configuration: defaultConfiguration) { benchmark in
        let divisor = GBP(minorUnits: 5)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(moneyOperands[index % moneyOperands.count].isMultiple(of: divisor))
            index &+= 1
        }
    }

    Benchmark("Money is multiple, throwing", configuration: defaultConfiguration) { benchmark in
        let divisor = Money(minorUnits: 5, currency: .gbp)
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try poundOperands[index % poundOperands.count].isMultiple(of: divisor))
                index &+= 1
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    // Rendering a currency code to a string, which writes into a small inline buffer.
    Benchmark("CurrencyCode description", configuration: defaultConfiguration) { benchmark in
        let codes: [CurrencyCode] = ["GBP", "EUR", "USD", "JPY", "CHF", "AUD"]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(codes[index % codes.count].description)
            index &+= 1
        }
    }
}
