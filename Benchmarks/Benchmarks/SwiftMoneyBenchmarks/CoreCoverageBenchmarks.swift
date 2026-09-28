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
