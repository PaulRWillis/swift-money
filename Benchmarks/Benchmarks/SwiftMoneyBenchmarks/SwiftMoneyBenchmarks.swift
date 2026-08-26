import Benchmark
import Foundation
import SwiftMoney
import SwiftMoneyFoundation

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
    let doubleOperands = operands.map(Double.init)
    let decimalOperands = operands.map { Decimal($0) }
    let moneyOperands = operands.map { GBP(minorUnits: $0) }

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

    // 17.5% of an amount, resolved to a whole unit. The operation this library exists for, and the one
    // where the three baselines diverge most: `Int` cannot round at all, `Double` rounds a value it
    // cannot represent, and `Decimal` is exact but pays for it.

    Benchmark("MoneyOf scaled and rounded", configuration: defaultConfiguration) { benchmark in
        let vat: Ratio = "7/40"
        var accumulated = GBP(minorUnits: 0)
        var amount = 1

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + GBP(minorUnits: amount).scaled(by: vat, rounding: .toNearestOrEven)
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
        let discount: Ratio = "9/10"
        let vat: Ratio = "6/5"
        let dayCount: Ratio = "31/365"
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(
                GBP(minorUnits: amount)
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
    let thirds = (1 ... 16).map { GBP(minorUnits: $0 * 100).unrounded * "0.333333333333333333" }

    Benchmark("MoneyOf unrounded addition", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(thirds[index % thirds.count] + thirds[(index &+ 1) % thirds.count])
            index &+= 1
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

    // `isFinite` rather than `!= nil`, this direction no longer being failable. What matters is that
    // every variant still hands `blackHole` a `Bool`.
    Benchmark("Decimal from MoneyOf", configuration: defaultConfiguration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Decimal(majorUnitsOf: moneyOperands[index % moneyOperands.count]).isFinite)
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

    // Every parse variant hands `blackHole` a `Bool`, so the harness costs the same in each. Both
    // variants read the same strings, `bareStrings` behind a pound sign. The runtime route,
    // `parseStrategy(for:)`, has no row: it shares the typed parse path, and only the final
    // construction differs.
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
    // currencies built separately, and that is what this measures.
    let separatelyBuiltPounds = [
        Currency(code: "GBP", unitScale: 100),
        Currency(code: "GBP", unitScale: 100),
    ]

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

    // Reporting a remainder means constructing a `Ratio`, which reduces to lowest terms. Against
    // `scaled(by:rounding:)`, the difference is what the report itself costs.
    Benchmark("MoneyOf scaled, reporting a remainder", configuration: defaultConfiguration) { benchmark in
        let vat: Ratio = "7/40"
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).scaled(by: vat))
            amount &+= 1
        }
    }

    // Reduces the fraction it returns, so like `Ratio construction` this is mostly a greatest common
    // divisor. The whole is fixed, as a budget or an order total would be.
    Benchmark("MoneyOf proportion", configuration: defaultConfiguration) { benchmark in
        let whole = GBP(minorUnits: 100_00)
        var amount = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).proportion(of: whole))
            amount &+= 1
        }
    }

    // Euclid takes a step per digit, so its cost is bounded by the *smaller* operand: a few pence of a
    // vast total costs no more than the pence do. Both sides have to be large for the expensive case,
    // which is what this measures and the benchmark above cannot.
    Benchmark("MoneyOf proportion of large amounts", configuration: defaultConfiguration) { benchmark in
        let whole = GBP.max
        var amount = Int64.max / 3

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).proportion(of: whole))
            amount &+= 1
        }
    }

    // Construction reduces, so this measures the greatest common divisor, plus the denominator
    // check and the optional that `init(exactly:over:)` adds. Denominators with many factors are
    // the expensive case, and the ones money actually uses.
    Benchmark("Ratio construction", configuration: defaultConfiguration) { benchmark in
        var numerator: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(Ratio(exactly: numerator % 40, over: 40))
            numerator &+= 1
        }
    }

    // The validation gate for a weighted split: the emptiness, sign, zero and overflow checks,
    // plus one pass to sum. Splitting itself never re-checks, so this cost is paid once per
    // weights value however many amounts it splits.
    Benchmark("Weights construction", configuration: defaultConfiguration) { benchmark in
        var weight = 1

        for _ in benchmark.scaledIterations {
            blackHole(Weights(exactly: [weight % 100, 30, 10]))
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
}
