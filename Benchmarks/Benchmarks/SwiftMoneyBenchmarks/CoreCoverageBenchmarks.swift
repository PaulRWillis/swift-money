import Benchmark
import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization

// The rest of `SwiftMoneyCore`'s public API: every operation the main suite had no row for, so each
// public function has a number. Same rules as the main suite: every iteration reads a different operand,
// so no call can be hoisted, and results reach the harness through `blackHole` (7 instructions for an
// integer, 22 for a struct — read each row net of that).
func coreCoverageBenchmarks(configuration: Benchmark.Configuration) {
    let operands: [Int64] = [1, 2, 3, 5, 7, 10, 13, 17, 19, 23]
    let pounds = operands.map { GBP(minorUnits: $0) }
    let runtimePounds = operands.map { Money(minorUnits: $0, currency: .gbp) }
    let unroundedPounds = operands.map { GBP(minorUnits: $0 * 100).unrounded * "0.333333333333333333" }
    let runtimeUnroundedPounds = operands.map { Money(minorUnits: $0 * 100, currency: .gbp).unrounded * "0.333333333333333333" }
    let vat: Rate = "0.175"

    // MARK: MoneyOf, typed currency

    Benchmark("MoneyOf init exactly", configuration: configuration) { benchmark in
        var amount: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(exactly: amount))
            amount &+= 1
        }
    }

    Benchmark("MoneyOf init major units", configuration: configuration) { benchmark in
        var count = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(majorUnits: count))
            count &+= 1
        }
    }

    Benchmark("MoneyOf init major units, Int64", configuration: configuration) { benchmark in
        var count: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(majorUnits: count))
            count &+= 1
        }
    }

    Benchmark("MoneyOf init major units, UInt32", configuration: configuration) { benchmark in
        var count: UInt32 = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(majorUnits: count))
            count &+= 1
        }
    }

    Benchmark("MoneyOf addition in place", configuration: configuration) { benchmark in
        var accumulated = GBP.zero
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated += pounds[index % pounds.count]
            index &+= 1
        }

        blackHole(accumulated)
    }

    // `*=` takes `some BinaryInteger`, so it reaches the widening `Int128` overload rather than the
    // `Int` fast path `*` gets.
    Benchmark("MoneyOf scalar multiplication in place", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            var amount = pounds[index % pounds.count]
            amount *= 3
            blackHole(amount)
            index &+= 1
        }
    }

    Benchmark("MoneyOf scalar multiplication, Int32 operand", configuration: configuration) { benchmark in
        let factors: [Int32] = [1, 2, 3, 5, 7, 11, 13]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(pounds[index % pounds.count] * factors[index % factors.count])
            index &+= 1
        }
    }

    Benchmark("MoneyOf is negative", configuration: configuration) { benchmark in
        var index = 0
        var negatives = 0

        for _ in benchmark.scaledIterations {
            if (-pounds[index % pounds.count]).isNegative {
                negatives &+= 1
            }
            index &+= 1
        }

        blackHole(negatives)
    }

    Benchmark("MoneyOf is positive", configuration: configuration) { benchmark in
        let amounts = pounds + pounds.map { -$0 }
        var index = 0
        var positives = 0

        for _ in benchmark.scaledIterations {
            if amounts[index % amounts.count].isPositive {
                positives &+= 1
            }
            index &+= 1
        }

        blackHole(positives)
    }

    Benchmark("MoneyOf is zero", configuration: configuration) { benchmark in
        let amounts = [GBP.zero] + pounds
        var index = 0
        var zeroes = 0

        for _ in benchmark.scaledIterations {
            if amounts[index % amounts.count].isZero {
                zeroes &+= 1
            }
            index &+= 1
        }

        blackHole(zeroes)
    }

    // Reads `C.currency`, a `static let` on the currency type, across the module boundary.
    Benchmark("MoneyOf currency", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(pounds[index % pounds.count].currency)
            index &+= 1
        }
    }

    Benchmark("MoneyOf unrounded", configuration: configuration) { benchmark in
        var amount: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).unrounded)
            amount &+= 1
        }
    }

    Benchmark("MoneyOf applying a rate", configuration: configuration) { benchmark in
        var amount: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).applying(vat))
            amount &+= 1
        }
    }

    Benchmark("MoneyOf equality", configuration: configuration) { benchmark in
        var index = 0
        var equal = 0

        for _ in benchmark.scaledIterations {
            if pounds[index % pounds.count] == pounds[(index &+ 1) % pounds.count] {
                equal &+= 1
            }
            index &+= 1
        }

        blackHole(equal)
    }

    // A hasher round trip per iteration, so read these against the `Int` row rather than as absolutes.
    Benchmark("Int hashing", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            var hasher = Hasher()
            hasher.combine(operands[index % operands.count])
            blackHole(hasher.finalize())
            index &+= 1
        }
    }

    Benchmark("MoneyOf hashing", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            var hasher = Hasher()
            hasher.combine(pounds[index % pounds.count])
            blackHole(hasher.finalize())
            index &+= 1
        }
    }

    Benchmark("MoneyOf total of 1000", configuration: configuration) { benchmark in
        let amounts = (1 ... 1_000).map { GBP(minorUnits: Int64($0)) }

        for _ in benchmark.scaledIterations {
            blackHole(amounts.total())
        }
    }

    Benchmark("MoneyOf JSON decode, amount only", configuration: configuration) { benchmark in
        let decoder = JSONDecoder()
        decoder.userInfo[.moneyCodingFormat] = MoneyCodingFormat.amountOnly
        let payloads = operands.map { Data(#"\#($0)"#.utf8) }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try? decoder.decode(GBP.self, from: payloads[index % payloads.count]))
            index &+= 1
        }
    }

    // MARK: Edge magnitudes

    // Alternates a near-maximum amount with its negation, so the running total swings between zero and
    // just under `max` without overflowing.
    Benchmark("MoneyOf addition near the maximum", configuration: configuration) { benchmark in
        let extremes = [GBP(minorUnits: Int64.max - 1), GBP(minorUnits: -(Int64.max - 1))]
        var accumulated = GBP.zero
        var index = 0

        for _ in benchmark.scaledIterations {
            accumulated = accumulated + extremes[index & 1]
            index &+= 1
        }

        blackHole(accumulated)
    }

    Benchmark("MoneyOf scalar multiplication near the maximum", configuration: configuration) { benchmark in
        let large = operands.map { GBP(minorUnits: Int64.max / 4 - $0) }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(large[index % large.count] * 3)
            index &+= 1
        }
    }

    Benchmark("MoneyOf description, large negative", configuration: configuration) { benchmark in
        let large = operands.map { GBP(minorUnits: -(Int64.max - $0)) }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(large[index % large.count].description)
            index &+= 1
        }
    }

    Benchmark("MoneyOf scaled and rounded, large amount", configuration: configuration) { benchmark in
        var amount = Int64.max / 4

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).applying(vat).rounded(.toNearestOrEven))
            amount &-= 1
        }
    }

    // MARK: MoneyOf.Unrounded, typed currency

    Benchmark("MoneyOf unrounded rounded", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(unroundedPounds[index % unroundedPounds.count].rounded(.toNearestOrEven))
            index &+= 1
        }
    }

    Benchmark("MoneyOf unrounded times an integer", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(unroundedPounds[index % unroundedPounds.count] * 31)
            index &+= 1
        }
    }

    Benchmark("MoneyOf unrounded from minor units", configuration: configuration) { benchmark in
        let rates: [Rate] = ["2.3", "0.5", "17.25", "100", "0.001"]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(GBP.Unrounded(minorUnits: rates[index % rates.count]))
            index &+= 1
        }
    }

    Benchmark("MoneyOf unrounded converted", configuration: configuration) { benchmark in
        guard let eurGbp = ExchangeRate<Currencies.EUR, Currencies.GBP>("0.8765262907") else {
            preconditionFailure("0.8765262907 is a positive rate")
        }
        let euros = operands.map { EUR(minorUnits: $0 * 100).unrounded * "0.333333333333333333" }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(euros[index % euros.count].converted(using: eurGbp))
            index &+= 1
        }
    }

    // MARK: Money, runtime currency

    Benchmark("Money init exactly", configuration: configuration) { benchmark in
        var amount: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(Money(exactly: amount, currency: .gbp))
            amount &+= 1
        }
    }

    Benchmark("Money init major units", configuration: configuration) { benchmark in
        var count = 1

        for _ in benchmark.scaledIterations {
            blackHole(Money(majorUnits: count, currency: .gbp))
            count &+= 1
        }
    }

    Benchmark("Money init major units, Int64", configuration: configuration) { benchmark in
        var count: Int64 = 1

        for _ in benchmark.scaledIterations {
            blackHole(Money(majorUnits: count, currency: .gbp))
            count &+= 1
        }
    }

    Benchmark("Money init major units, UInt32", configuration: configuration) { benchmark in
        var count: UInt32 = 1

        for _ in benchmark.scaledIterations {
            blackHole(Money(majorUnits: count, currency: .gbp))
            count &+= 1
        }
    }

    Benchmark("Money from MoneyOf", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money(pounds[index % pounds.count]))
            index &+= 1
        }
    }

    // The typed twin of `Money from MoneyOf`: the check that the runtime currency is this type's.
    Benchmark("MoneyOf from Money, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try GBP(runtimePounds[index % runtimePounds.count]))
                index &+= 1
            }
        } catch {
            fatalError("these amounts are all in pounds, so this cannot happen: \(error)")
        }
    }

    Benchmark("Money subtraction in place, throwing", configuration: configuration) { benchmark in
        var accumulated = Money(minorUnits: 0, currency: .gbp)
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                try accumulated -= runtimePounds[index % runtimePounds.count]
                index &+= 1
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }

        blackHole(accumulated)
    }

    Benchmark("Money equality", configuration: configuration) { benchmark in
        var index = 0
        var equal = 0

        for _ in benchmark.scaledIterations {
            if runtimePounds[index % runtimePounds.count] == runtimePounds[(index &+ 1) % runtimePounds.count] {
                equal &+= 1
            }
            index &+= 1
        }

        blackHole(equal)
    }

    Benchmark("Money hashing", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            var hasher = Hasher()
            hasher.combine(runtimePounds[index % runtimePounds.count])
            blackHole(hasher.finalize())
            index &+= 1
        }
    }

    Benchmark("Money total of 1000, throwing", configuration: configuration) { benchmark in
        let amounts = (1 ... 1_000).map { Money(minorUnits: Int64($0), currency: .gbp) }

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try amounts.total())
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    Benchmark("Money split into 1000, materialized", configuration: configuration) { benchmark in
        var amount: Int64 = 100_00

        for _ in benchmark.scaledIterations {
            blackHole(Array(Money(minorUnits: amount, currency: .gbp).split(into: 1_000).amounts))
            amount &+= 1
        }
    }

    Benchmark("Money parsing, caller's currency", configuration: configuration) { benchmark in
        guard let points = Currency(code: "LTY", unitScale: 1) else {
            preconditionFailure("LTY is not a currency the library ships")
        }
        let strings = operands.map { "LTY \($0 * 25)" }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money(string: strings[index % strings.count], currency: points))
            index &+= 1
        }
    }

    Benchmark("Money unrounded minus settled, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try runtimeUnroundedPounds[index % runtimeUnroundedPounds.count] - runtimePounds[index % runtimePounds.count])
                index &+= 1
            }
        } catch {
            fatalError("these amounts share a currency, so this cannot happen: \(error)")
        }
    }

    if #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) {
        Benchmark("Money bytes encode", configuration: configuration) { benchmark in
            var index = 0

            for _ in benchmark.scaledIterations {
                blackHole(runtimePounds[index % runtimePounds.count].bytes)
                index &+= 1
            }
        }

        Benchmark("MoneyOf bytes encode, extremes", configuration: configuration) { benchmark in
            let extremes = [GBP.min, GBP.max, GBP(minorUnits: Int64.min + 1), GBP(minorUnits: Int64.max - 1)]
            var index = 0

            for _ in benchmark.scaledIterations {
                blackHole(extremes[index & 3].bytes)
                index &+= 1
            }
        }
    }

    // MARK: Currency and its parts

    Benchmark("Currency equality", configuration: configuration) { benchmark in
        let currencies: [Currency] = [.gbp, .eur, .usd, .jpy, .gbp, .chf]
        var index = 0
        var equal = 0

        for _ in benchmark.scaledIterations {
            if currencies[index % currencies.count] == currencies[(index &+ 4) % currencies.count] {
                equal &+= 1
            }
            index &+= 1
        }

        blackHole(equal)
    }

    Benchmark("Currency description", configuration: configuration) { benchmark in
        let currencies: [Currency] = [.gbp, .eur, .usd, .jpy, .chf, .aud]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(currencies[index % currencies.count].description)
            index &+= 1
        }
    }

    Benchmark("CurrencyCode validation, lowercase", configuration: configuration) { benchmark in
        let strings = ["gbp", "eur", "usd", "jpy", "chf", "aud"]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(CurrencyCode(string: strings[index % strings.count]))
            index &+= 1
        }
    }

    Benchmark("AnyCurrency storage for a custom field", configuration: configuration) { benchmark in
        let fields: [CurrencyField] = [
            .custom(code: "LTY", rawScale: 0), .custom(code: "GEMS", rawScale: 2), .code("GBP"),
            .custom(code: "BTC", rawScale: 8), .custom(code: "USDT", rawScale: 6),
        ]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(AnyCurrency.storage(for: fields[index % fields.count]))
            index &+= 1
        }
    }

    Benchmark("UnitScale from decimal places", configuration: configuration) { benchmark in
        var places = 0

        for _ in benchmark.scaledIterations {
            blackHole(UnitScale(decimalPlaces: places % 19))
            places &+= 1
        }
    }

    // MARK: Refinement types

    Benchmark("PartCount construction", configuration: configuration) { benchmark in
        var count = 1

        for _ in benchmark.scaledIterations {
            blackHole(PartCount(exactly: count))
            count &+= 1
        }
    }

    Benchmark("Weight construction", configuration: configuration) { benchmark in
        var weight = 0

        for _ in benchmark.scaledIterations {
            blackHole(Weight(exactly: weight))
            weight &+= 1
        }
    }

    Benchmark("FractionLength construction", configuration: configuration) { benchmark in
        var length = 0

        for _ in benchmark.scaledIterations {
            blackHole(FractionLength(exactly: length % 19))
            length &+= 1
        }
    }

    // MARK: Rate and FX

    Benchmark("Rate equality", configuration: configuration) { benchmark in
        let rates: [Rate] = ["0.175", "0.2", "1/4", "0.05", "0.175"]
        var index = 0
        var equal = 0

        for _ in benchmark.scaledIterations {
            if rates[index % rates.count] == rates[(index &+ 4) % rates.count] {
                equal &+= 1
            }
            index &+= 1
        }

        blackHole(equal)
    }

    Benchmark("ExchangeRate construction", configuration: configuration) { benchmark in
        let quotes: [Rate] = ["0.87", "0.8765262907", "1.17", "0.91", "1.2345"]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(ExchangeRate<Currencies.EUR, Currencies.GBP>(quotes[index % quotes.count]))
            index &+= 1
        }
    }

    // Different scales on each side, so the quote is rescaled from major to minor units.
    Benchmark("ExchangeRate construction, across scales", configuration: configuration) { benchmark in
        let quotes: [Rate] = ["149.5", "150.25", "148", "151.125", "147.8"]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(ExchangeRate<Currencies.USD, Currencies.JPY>(quotes[index % quotes.count]))
            index &+= 1
        }
    }

    // MARK: Splitting

    Benchmark("MoneyOf split into 1000, materialized", configuration: configuration) { benchmark in
        var amount: Int64 = 100_00

        for _ in benchmark.scaledIterations {
            blackHole(Array(GBP(minorUnits: amount).split(into: 1_000).amounts))
            amount &+= 1
        }
    }

    Benchmark("MoneyOf split by 10 weights", configuration: configuration) { benchmark in
        let weights: Weights = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3]
        var amount: Int64 = 100_00

        for _ in benchmark.scaledIterations {
            blackHole(GBP(minorUnits: amount).split(by: weights))
            amount &+= 1
        }
    }

    Benchmark("WeightedSplit count", configuration: configuration) { benchmark in
        let splits = operands.map { GBP(minorUnits: $0 * 100).split(by: [60, 30, 10]) }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(splits[index % splits.count].count)
            index &+= 1
        }
    }

    // MARK: Ranges and steps

    // Typed rows sit beside their runtime twins; a typed row should cost no more than its twin, which
    // also compares currencies. The typed rows that exercise only the standard library (`...`,
    // `contains`) are the floor the runtime ranges are measured against.
    let lowerPounds = operands.map { GBP(minorUnits: $0 * 100) }
    let upperPounds = operands.map { GBP(minorUnits: $0 * 100 + 250_00) }
    let runtimeLowerPounds = lowerPounds.map { Money($0) }
    let runtimeUpperPounds = upperPounds.map { Money($0) }
    let closedPounds = operands.map { GBP(minorUnits: $0 * 100) ... GBP(minorUnits: $0 * 100 + 250_00) }
    let runtimeClosedPounds = closedPounds.map { ClosedMoneyRange($0) }
    let probePounds = operands.map { GBP(minorUnits: $0 * 1_000) }
    let runtimeProbePounds = probePounds.map { Money($0) }

    Benchmark("ClosedRange of MoneyOf construction", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(lowerPounds[index % lowerPounds.count] ... upperPounds[index % upperPounds.count])
            index &+= 1
        }
    }

    Benchmark("ClosedMoneyRange construction, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try runtimeLowerPounds[index % runtimeLowerPounds.count] ... runtimeUpperPounds[index % runtimeUpperPounds.count])
                index &+= 1
            }
        } catch {
            fatalError("these bounds share a currency and are ordered, so this cannot happen: \(error)")
        }
    }

    Benchmark("ClosedMoneyRange from checked bounds, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try ClosedMoneyRange(checkedBounds: (
                    lower: runtimeLowerPounds[index % runtimeLowerPounds.count],
                    upper: runtimeUpperPounds[index % runtimeUpperPounds.count]
                )))
                index &+= 1
            }
        } catch {
            fatalError("these bounds share a currency and are ordered, so this cannot happen: \(error)")
        }
    }

    Benchmark("ClosedMoneyRange from a typed range", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(ClosedMoneyRange(closedPounds[index % closedPounds.count]))
            index &+= 1
        }
    }

    Benchmark("ClosedRange of MoneyOf contains", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        for _ in benchmark.scaledIterations {
            if closedPounds[index % closedPounds.count].contains(probePounds[(index / 10) % probePounds.count]) {
                hits &+= 1
            }
            index &+= 1
        }

        blackHole(hits)
    }

    Benchmark("ClosedMoneyRange contains, throwing", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try runtimeClosedPounds[index % runtimeClosedPounds.count]
                    .contains(runtimeProbePounds[(index / 10) % runtimeProbePounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these amounts share the ranges' currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("ClosedMoneyRange currency", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeClosedPounds[index % runtimeClosedPounds.count].currency)
            index &+= 1
        }
    }

    Benchmark("ClosedMoneyRange lower bound", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeClosedPounds[index % runtimeClosedPounds.count].lowerBound)
            index &+= 1
        }
    }

    Benchmark("ClosedMoneyRange upper bound", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeClosedPounds[index % runtimeClosedPounds.count].upperBound)
            index &+= 1
        }
    }

    Benchmark("ClosedMoneyRange is empty", configuration: configuration) { benchmark in
        var index = 0
        var empties = 0

        for _ in benchmark.scaledIterations {
            if runtimeClosedPounds[index % runtimeClosedPounds.count].isEmpty {
                empties &+= 1
            }
            index &+= 1
        }

        blackHole(empties)
    }

    Benchmark("ClosedMoneyRange description", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeClosedPounds[index % runtimeClosedPounds.count].description)
            index &+= 1
        }
    }

    Benchmark("ClosedMoneyRange debug description", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeClosedPounds[index % runtimeClosedPounds.count].debugDescription)
            index &+= 1
        }
    }

    // The typed twin of `ClosedMoneyRange from checked bounds, throwing`.
    Benchmark("ClosedRange from checked bounds, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try ClosedRange(checkedBounds: (
                    lower: lowerPounds[index % lowerPounds.count],
                    upper: upperPounds[index % upperPounds.count]
                )))
                index &+= 1
            }
        } catch {
            fatalError("these bounds are ordered, so this cannot happen: \(error)")
        }
    }

    // The typed twin of `MoneyRange from checked bounds, throwing`.
    Benchmark("Range from checked bounds, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try Range(checkedBounds: (
                    lower: lowerPounds[index % lowerPounds.count],
                    upper: upperPounds[index % upperPounds.count]
                )))
                index &+= 1
            }
        } catch {
            fatalError("these bounds are ordered, so this cannot happen: \(error)")
        }
    }

    let halfOpenPounds = operands.map { GBP(minorUnits: $0 * 100) ..< GBP(minorUnits: $0 * 100 + 250_00) }
    let runtimeHalfOpenPounds = halfOpenPounds.map { MoneyRange($0) }

    Benchmark("Range of MoneyOf construction", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(lowerPounds[index % lowerPounds.count] ..< upperPounds[index % upperPounds.count])
            index &+= 1
        }
    }

    Benchmark("MoneyRange construction, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try runtimeLowerPounds[index % runtimeLowerPounds.count] ..< runtimeUpperPounds[index % runtimeUpperPounds.count])
                index &+= 1
            }
        } catch {
            fatalError("these bounds share a currency and are ordered, so this cannot happen: \(error)")
        }
    }

    Benchmark("MoneyRange from checked bounds, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try MoneyRange(checkedBounds: (
                    lower: runtimeLowerPounds[index % runtimeLowerPounds.count],
                    upper: runtimeUpperPounds[index % runtimeUpperPounds.count]
                )))
                index &+= 1
            }
        } catch {
            fatalError("these bounds share a currency and are ordered, so this cannot happen: \(error)")
        }
    }

    Benchmark("MoneyRange from a typed range", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(MoneyRange(halfOpenPounds[index % halfOpenPounds.count]))
            index &+= 1
        }
    }

    Benchmark("Range of MoneyOf contains", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        for _ in benchmark.scaledIterations {
            if halfOpenPounds[index % halfOpenPounds.count].contains(probePounds[(index / 10) % probePounds.count]) {
                hits &+= 1
            }
            index &+= 1
        }

        blackHole(hits)
    }

    Benchmark("MoneyRange contains, throwing", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count]
                    .contains(runtimeProbePounds[(index / 10) % runtimeProbePounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these amounts share the ranges' currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("MoneyRange currency", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count].currency)
            index &+= 1
        }
    }

    Benchmark("MoneyRange lower bound", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count].lowerBound)
            index &+= 1
        }
    }

    Benchmark("MoneyRange upper bound", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count].upperBound)
            index &+= 1
        }
    }

    Benchmark("MoneyRange is empty", configuration: configuration) { benchmark in
        let ranges = runtimeHalfOpenPounds + [MoneyRange(GBP.zero ..< GBP.zero)]
        var index = 0
        var empties = 0

        for _ in benchmark.scaledIterations {
            if ranges[index % ranges.count].isEmpty {
                empties &+= 1
            }
            index &+= 1
        }

        blackHole(empties)
    }

    Benchmark("MoneyRange description", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count].description)
            index &+= 1
        }
    }

    Benchmark("MoneyRange debug description", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count].debugDescription)
            index &+= 1
        }
    }

    Benchmark("ClosedRange from ClosedMoneyRange, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try ClosedRange<GBP>(runtimeClosedPounds[index % runtimeClosedPounds.count]))
                index &+= 1
            }
        } catch {
            fatalError("these ranges are all in pounds, so this cannot happen: \(error)")
        }
    }

    Benchmark("Range from MoneyRange, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try Range<GBP>(runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count]))
                index &+= 1
            }
        } catch {
            fatalError("these ranges are all in pounds, so this cannot happen: \(error)")
        }
    }

    Benchmark("ClosedRange from a half-open range", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(ClosedRange(halfOpenPounds[index % halfOpenPounds.count]))
            index &+= 1
        }
    }

    Benchmark("ClosedMoneyRange from a half-open range", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(ClosedMoneyRange(runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count]))
            index &+= 1
        }
    }

    Benchmark("Range from a closed range", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Range(closedPounds[index % closedPounds.count]))
            index &+= 1
        }
    }

    Benchmark("MoneyRange from a closed range", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(MoneyRange(runtimeClosedPounds[index % runtimeClosedPounds.count]))
            index &+= 1
        }
    }

    Benchmark("PartialRangeUpTo of MoneyOf construction", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(..<upperPounds[index % upperPounds.count])
            index &+= 1
        }
    }

    Benchmark("PartialMoneyRangeUpTo construction", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(..<runtimeUpperPounds[index % runtimeUpperPounds.count])
            index &+= 1
        }
    }

    Benchmark("PartialMoneyRangeThrough construction", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(...runtimeUpperPounds[index % runtimeUpperPounds.count])
            index &+= 1
        }
    }

    Benchmark("PartialMoneyRangeFrom construction", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(runtimeLowerPounds[index % runtimeLowerPounds.count]...)
            index &+= 1
        }
    }

    Benchmark("PartialRangeUpTo of MoneyOf contains", configuration: configuration) { benchmark in
        let limits = upperPounds.map { ..<$0 }
        var index = 0
        var hits = 0

        for _ in benchmark.scaledIterations {
            if limits[index % limits.count].contains(probePounds[(index / 10) % probePounds.count]) {
                hits &+= 1
            }
            index &+= 1
        }

        blackHole(hits)
    }

    Benchmark("PartialMoneyRangeUpTo contains, throwing", configuration: configuration) { benchmark in
        let limits = runtimeUpperPounds.map { ..<$0 }
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try limits[index % limits.count].contains(runtimeProbePounds[(index / 10) % runtimeProbePounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these amounts share the ranges' currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("PartialMoneyRangeThrough contains, throwing", configuration: configuration) { benchmark in
        let limits = runtimeUpperPounds.map { ...$0 }
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try limits[index % limits.count].contains(runtimeProbePounds[(index / 10) % runtimeProbePounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these amounts share the ranges' currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("PartialMoneyRangeFrom contains, throwing", configuration: configuration) { benchmark in
        let limits = runtimeLowerPounds.map { $0... }
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try limits[index % limits.count].contains(runtimeProbePounds[(index / 10) % runtimeProbePounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these amounts share the ranges' currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("PartialMoneyRangeFrom from a typed range", configuration: configuration) { benchmark in
        let limits = lowerPounds.map { $0... }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(PartialMoneyRangeFrom(limits[index % limits.count]))
            index &+= 1
        }
    }

    Benchmark("PartialMoneyRangeThrough from a typed range", configuration: configuration) { benchmark in
        let limits = upperPounds.map { ...$0 }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(PartialMoneyRangeThrough(limits[index % limits.count]))
            index &+= 1
        }
    }

    Benchmark("PartialMoneyRangeUpTo from a typed range", configuration: configuration) { benchmark in
        let limits = upperPounds.map { ..<$0 }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(PartialMoneyRangeUpTo(limits[index % limits.count]))
            index &+= 1
        }
    }

    Benchmark("PartialRangeFrom from PartialMoneyRangeFrom, throwing", configuration: configuration) { benchmark in
        let limits = runtimeLowerPounds.map { $0... }
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try PartialRangeFrom<GBP>(limits[index % limits.count]))
                index &+= 1
            }
        } catch {
            fatalError("these ranges are all in pounds, so this cannot happen: \(error)")
        }
    }

    Benchmark("PartialRangeThrough from PartialMoneyRangeThrough, throwing", configuration: configuration) { benchmark in
        let limits = runtimeUpperPounds.map { ...$0 }
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try PartialRangeThrough<GBP>(limits[index % limits.count]))
                index &+= 1
            }
        } catch {
            fatalError("these ranges are all in pounds, so this cannot happen: \(error)")
        }
    }

    Benchmark("PartialRangeUpTo from PartialMoneyRangeUpTo, throwing", configuration: configuration) { benchmark in
        let limits = runtimeUpperPounds.map { ..<$0 }
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try PartialRangeUpTo<GBP>(limits[index % limits.count]))
                index &+= 1
            }
        } catch {
            fatalError("these ranges are all in pounds, so this cannot happen: \(error)")
        }
    }

    Benchmark("PartialMoneyRangeFrom currency", configuration: configuration) { benchmark in
        let limits = runtimeLowerPounds.map { $0... }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(limits[index % limits.count].currency)
            index &+= 1
        }
    }

    Benchmark("PartialMoneyRangeThrough currency", configuration: configuration) { benchmark in
        let limits = runtimeUpperPounds.map { ...$0 }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(limits[index % limits.count].currency)
            index &+= 1
        }
    }

    Benchmark("PartialMoneyRangeUpTo currency", configuration: configuration) { benchmark in
        let limits = runtimeUpperPounds.map { ..<$0 }
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(limits[index % limits.count].currency)
            index &+= 1
        }
    }

    // Each range meets a neighbour three along, so the pairs nest, overlap and sit apart in turn.
    Benchmark("ClosedRange of MoneyOf contains a closed range", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        for _ in benchmark.scaledIterations {
            if closedPounds[index % closedPounds.count].contains(closedPounds[(index &+ 3) % closedPounds.count]) {
                hits &+= 1
            }
            index &+= 1
        }

        blackHole(hits)
    }

    Benchmark("ClosedMoneyRange contains a closed range, throwing", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try runtimeClosedPounds[index % runtimeClosedPounds.count]
                    .contains(runtimeClosedPounds[(index &+ 3) % runtimeClosedPounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these ranges share a currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("ClosedRange of MoneyOf contains a half-open range", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        for _ in benchmark.scaledIterations {
            if closedPounds[index % closedPounds.count].contains(halfOpenPounds[(index &+ 3) % halfOpenPounds.count]) {
                hits &+= 1
            }
            index &+= 1
        }

        blackHole(hits)
    }

    Benchmark("ClosedMoneyRange contains a half-open range, throwing", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try runtimeClosedPounds[index % runtimeClosedPounds.count]
                    .contains(runtimeHalfOpenPounds[(index &+ 3) % runtimeHalfOpenPounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these ranges share a currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("ClosedRange of MoneyOf overlaps", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        for _ in benchmark.scaledIterations {
            if closedPounds[index % closedPounds.count].overlaps(closedPounds[(index &+ 3) % closedPounds.count]) {
                hits &+= 1
            }
            index &+= 1
        }

        blackHole(hits)
    }

    Benchmark("ClosedMoneyRange overlaps, throwing", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try runtimeClosedPounds[index % runtimeClosedPounds.count]
                    .overlaps(runtimeClosedPounds[(index &+ 3) % runtimeClosedPounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these ranges share a currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("ClosedMoneyRange overlaps a half-open range, throwing", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try runtimeClosedPounds[index % runtimeClosedPounds.count]
                    .overlaps(runtimeHalfOpenPounds[(index &+ 3) % runtimeHalfOpenPounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these ranges share a currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("ClosedRange of MoneyOf clamped", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(closedPounds[index % closedPounds.count].clamped(to: closedPounds[(index &+ 3) % closedPounds.count]))
            index &+= 1
        }
    }

    Benchmark("ClosedMoneyRange clamped, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try runtimeClosedPounds[index % runtimeClosedPounds.count]
                    .clamped(to: runtimeClosedPounds[(index &+ 3) % runtimeClosedPounds.count]))
                index &+= 1
            }
        } catch {
            fatalError("these ranges share a currency, so this cannot happen: \(error)")
        }
    }

    Benchmark("MoneyRange contains a half-open range, throwing", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count]
                    .contains(runtimeHalfOpenPounds[(index &+ 3) % runtimeHalfOpenPounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these ranges share a currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("MoneyRange contains a closed range, throwing", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count]
                    .contains(runtimeClosedPounds[(index &+ 3) % runtimeClosedPounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these ranges share a currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("MoneyRange overlaps, throwing", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count]
                    .overlaps(runtimeHalfOpenPounds[(index &+ 3) % runtimeHalfOpenPounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these ranges share a currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("MoneyRange overlaps a closed range, throwing", configuration: configuration) { benchmark in
        var index = 0
        var hits = 0

        do {
            for _ in benchmark.scaledIterations {
                if try runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count]
                    .overlaps(runtimeClosedPounds[(index &+ 3) % runtimeClosedPounds.count]) {
                    hits &+= 1
                }
                index &+= 1
            }
        } catch {
            fatalError("these ranges share a currency, so this cannot happen: \(error)")
        }

        blackHole(hits)
    }

    Benchmark("MoneyRange clamped, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try runtimeHalfOpenPounds[index % runtimeHalfOpenPounds.count]
                    .clamped(to: runtimeHalfOpenPounds[(index &+ 3) % runtimeHalfOpenPounds.count]))
                index &+= 1
            }
        } catch {
            fatalError("these ranges share a currency, so this cannot happen: \(error)")
        }
    }

    // Probes spread from well below to well above the £10–£250 limits, so all three outcomes occur.
    let clampProbes = operands.map { GBP(minorUnits: $0 * 1_500) }
    let runtimeClampProbes = clampProbes.map { Money($0) }
    let typedClampLimits = GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)
    let runtimeClampLimits = ClosedMoneyRange(typedClampLimits)

    Benchmark("MoneyOf clamped to a closed range", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(clampProbes[index % clampProbes.count].clamped(to: typedClampLimits))
            index &+= 1
        }
    }

    Benchmark("Money clamped to a closed range, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try runtimeClampProbes[index % runtimeClampProbes.count].clamped(to: runtimeClampLimits))
                index &+= 1
            }
        } catch {
            fatalError("these amounts share the limits' currency, so this cannot happen: \(error)")
        }
    }

    Benchmark("MoneyOf clamped to a lower bound", configuration: configuration) { benchmark in
        let limit = typedClampLimits.lowerBound...
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(clampProbes[index % clampProbes.count].clamped(to: limit))
            index &+= 1
        }
    }

    Benchmark("Money clamped to a lower bound, throwing", configuration: configuration) { benchmark in
        let limit = runtimeClampLimits.lowerBound...
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try runtimeClampProbes[index % runtimeClampProbes.count].clamped(to: limit))
                index &+= 1
            }
        } catch {
            fatalError("these amounts share the limit's currency, so this cannot happen: \(error)")
        }
    }

    Benchmark("MoneyOf clamped to an upper bound", configuration: configuration) { benchmark in
        let limit = ...typedClampLimits.upperBound
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(clampProbes[index % clampProbes.count].clamped(to: limit))
            index &+= 1
        }
    }

    Benchmark("Money clamped to an upper bound, throwing", configuration: configuration) { benchmark in
        let limit = ...runtimeClampLimits.upperBound
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try runtimeClampProbes[index % runtimeClampProbes.count].clamped(to: limit))
                index &+= 1
            }
        } catch {
            fatalError("these amounts share the limit's currency, so this cannot happen: \(error)")
        }
    }

    // Some operands are negative, so both signs of stride occur; none is zero.
    let strideAmounts = operands.map { GBP(minorUnits: $0 % 2 == 0 ? $0 * 100 : -$0 * 100) }
    let runtimeStrideAmounts = strideAmounts.map { Money($0) }
    let typedStrides = strideAmounts.compactMap { GBP.Stride(exactly: $0) }
    let runtimeStrides = typedStrides.map { Money.Stride($0) }
    let strideCurrencies: [Currency] = [.gbp, .jpy, .eur, .bhd, .usd]

    Benchmark("MoneyOf.Stride init exactly", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(GBP.Stride(exactly: strideAmounts[index % strideAmounts.count]))
            index &+= 1
        }
    }

    Benchmark("Money.Stride init exactly", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money.Stride(exactly: runtimeStrideAmounts[index % runtimeStrideAmounts.count]))
            index &+= 1
        }
    }

    Benchmark("MoneyOf.Stride major unit", configuration: configuration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(GBP.Stride.majorUnit)
        }
    }

    Benchmark("Money.Stride major unit of a currency", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money.Stride.majorUnit(of: strideCurrencies[index % strideCurrencies.count]))
            index &+= 1
        }
    }

    Benchmark("Money.Stride major unit of an amount", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money.Stride.majorUnit(of: runtimeStrideAmounts[index % runtimeStrideAmounts.count]))
            index &+= 1
        }
    }

    Benchmark("MoneyOf.Stride minor unit", configuration: configuration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(GBP.Stride.minorUnit)
        }
    }

    Benchmark("Money.Stride minor unit of a currency", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money.Stride.minorUnit(of: strideCurrencies[index % strideCurrencies.count]))
            index &+= 1
        }
    }

    Benchmark("Money.Stride minor unit of an amount", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money.Stride.minorUnit(of: runtimeStrideAmounts[index % runtimeStrideAmounts.count]))
            index &+= 1
        }
    }

    Benchmark("MoneyOf.Stride major units", configuration: configuration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(GBP.Stride.majorUnits(5))
        }
    }

    Benchmark("Money.Stride major units of a currency", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money.Stride.majorUnits(5, of: strideCurrencies[index % strideCurrencies.count]))
            index &+= 1
        }
    }

    Benchmark("MoneyOf.Stride minor units", configuration: configuration) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(GBP.Stride.minorUnits(50))
        }
    }

    Benchmark("Money.Stride minor units of a currency", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money.Stride.minorUnits(50, of: strideCurrencies[index % strideCurrencies.count]))
            index &+= 1
        }
    }

    Benchmark("Money.Stride minor units of an amount", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money.Stride.minorUnits(50, of: runtimeStrideAmounts[index % runtimeStrideAmounts.count]))
            index &+= 1
        }
    }

    Benchmark("Money.Stride major units of an amount", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money.Stride.majorUnits(5, of: runtimeStrideAmounts[index % runtimeStrideAmounts.count]))
            index &+= 1
        }
    }

    Benchmark("Money.Stride from a typed stride", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(Money.Stride(typedStrides[index % typedStrides.count]))
            index &+= 1
        }
    }

    Benchmark("MoneyOf.Stride from a runtime stride, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                blackHole(try GBP.Stride(runtimeStrides[index % runtimeStrides.count]))
                index &+= 1
            }
        } catch {
            fatalError("these strides are in pounds, so this cannot happen: \(error)")
        }
    }

    // Each row walks the whole sequence: £250 by £25 from a moving start, eleven amounts through the end
    // and ten up to it. The `Int64` row is the standard library's own stride, the reference for the rest.
    let strideByMajorUnits = GBP.Stride.majorUnits(25)
    let runtimeStrideByMajorUnits = Money.Stride(strideByMajorUnits)
    let rawLowerBounds = operands.map { $0 * 100 }

    Benchmark("stride through Int64, £250 by £25", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            let lower = rawLowerBounds[index % rawLowerBounds.count]
            var last: Int64 = 0
            for minorUnits in stride(from: lower, through: lower + 250_00, by: 25_00) {
                last = minorUnits
            }
            blackHole(last)
            index &+= 1
        }
    }

    Benchmark("stride through MoneyOf, £250 by £25", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            var last = GBP.zero
            for amount in stride(from: lowerPounds[index % lowerPounds.count], through: upperPounds[index % upperPounds.count], by: strideByMajorUnits) {
                last = amount
            }
            blackHole(last)
            index &+= 1
        }
    }

    Benchmark("stride through Money, £250 by £25, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                var last = runtimeLowerPounds[0]
                for amount in try stride(from: runtimeLowerPounds[index % runtimeLowerPounds.count], through: runtimeUpperPounds[index % runtimeUpperPounds.count], by: runtimeStrideByMajorUnits) {
                    last = amount
                }
                blackHole(last)
                index &+= 1
            }
        } catch {
            fatalError("these amounts and the stride share a currency, so this cannot happen: \(error)")
        }
    }

    Benchmark("stride to MoneyOf, £250 by £25", configuration: configuration) { benchmark in
        var index = 0

        for _ in benchmark.scaledIterations {
            var last = GBP.zero
            for amount in stride(from: lowerPounds[index % lowerPounds.count], to: upperPounds[index % upperPounds.count], by: strideByMajorUnits) {
                last = amount
            }
            blackHole(last)
            index &+= 1
        }
    }

    Benchmark("stride to Money, £250 by £25, throwing", configuration: configuration) { benchmark in
        var index = 0

        do {
            for _ in benchmark.scaledIterations {
                var last = runtimeLowerPounds[0]
                for amount in try stride(from: runtimeLowerPounds[index % runtimeLowerPounds.count], to: runtimeUpperPounds[index % runtimeUpperPounds.count], by: runtimeStrideByMajorUnits) {
                    last = amount
                }
                blackHole(last)
                index &+= 1
            }
        } catch {
            fatalError("these amounts and the stride share a currency, so this cannot happen: \(error)")
        }
    }

    // MARK: Serialization configuration

    Benchmark("MoneyCodingFormat custom fields", configuration: configuration) { benchmark in
        let currencyKeys: [CurrencyKey] = ["ccy", "currency_code", "cur"]
        let amountKeys: [AmountKey] = ["amt", "value", "minor"]
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(try? MoneyCodingFormat.fields(
                currencyKey: currencyKeys[index % currencyKeys.count],
                amountKey: amountKeys[(index / 3) % amountKeys.count]
            ))
            index &+= 1
        }
    }

    // MARK: MoneyFormat options, engine only

    guard let engineGBP = MoneyLocalization.moneyFormat(for: .gbp, locale: "en-GB") else {
        fatalError("en-GB is a covered locale, so it must resolve a format")
    }
    let formatted = operands.map { GBP(minorUnits: 4_00 + $0) }
    let negativeFormatted = formatted.map { -$0 }

    Benchmark("Engine format, accounting, en_GB [engine]", configuration: configuration) { benchmark in
        let options = MoneyFormatOptions(sign: .accounting)
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(engineGBP.format(negativeFormatted[index % negativeFormatted.count], options: options))
            index &+= 1
        }
    }

    Benchmark("Engine format, precision 1dp, en_GB [engine]", configuration: configuration) { benchmark in
        let options = MoneyFormatOptions(precision: .fixed(1, rounding: .toNearestOrEven))
        var index = 0

        for _ in benchmark.scaledIterations {
            blackHole(engineGBP.format(formatted[index % formatted.count], options: options))
            index &+= 1
        }
    }
}
