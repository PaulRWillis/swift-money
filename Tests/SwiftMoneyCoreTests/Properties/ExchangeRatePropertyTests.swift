import SwiftMoneyCore
import Testing

// A conversion to exercise: an amount, a mid rate (EUR→GBP), a second leg (GBP→USD) to cross with, a
// margin, and an ordered pair of amounts for the monotonicity check. The rates are stored rather than the
// `ExchangeRate` values, which are built in the tests: a positive rate always yields one, so `#require`
// unwraps it there without a fallback.
private struct ConvertCase: Sendable {
    let amount: EUR
    let rate: Rate
    let onwardRate: Rate
    let marginBasisPoints: Int
    let smaller: EUR
    let larger: EUR
}

// Amounts run from £1.00 up to a million minor units. The floor keeps a settled conversion positive:
// even at the smallest rate (0.1) less the largest margin (just under 0.5), 100 × 0.1 × 0.5 = 5 minor
// units, so rounding never reaches zero.
private let conversionAmountFloor: Int64 = 100
private let conversionAmountBound: Int64 = 1_000_000

// Rates in [0.1, 10]: a significand of 1_000…100_000 over 10_000. A crossed pair reaches 100, so the
// largest product 10⁶ × 100 = 10⁸ minor units stays far inside range.
private let exchangeSignificandRange: ClosedRange<Int64> = 1_000 ... 100_000
private let exchangeDenominator: Int64 = 10_000

// Margins from zero up to just under one half (4_999 basis points is 0.4999), the range `Margin` accepts.
private let maxMarginBasisPoints: Int64 = 4_999

private let roundingRules: [RoundingRule] = [
    .toNearestOrAwayFromZero,
    .toNearestOrEven,
    .up,
    .down,
    .towardZero,
    .awayFromZero,
]

private func euros(in range: ClosedRange<Int64>) -> Gen<EUR> {
    Gen<Int64>.int(in: range).map { EUR(minorUnits: $0) }
}

private func exchangeRateGen() -> Gen<Rate> {
    Gen<Rate>.rate(significandIn: exchangeSignificandRange, denominators: [exchangeDenominator])
}

private let convertCases: [ConvertCase] = samples(
    zip(
        zip3(
            euros(in: conversionAmountFloor ... conversionAmountBound),
            exchangeRateGen(),
            exchangeRateGen()
        ),
        zip3(
            Gen<Int64>.int(in: 0 ... maxMarginBasisPoints).map { Int($0) },
            euros(in: conversionAmountFloor ... conversionAmountBound),
            euros(in: conversionAmountFloor ... conversionAmountBound)
        )
    ).map { rates, rest in
        let (first, second) = rest.1 <= rest.2 ? (rest.1, rest.2) : (rest.2, rest.1)
        return ConvertCase(
            amount: rates.0,
            rate: rates.1,
            onwardRate: rates.2,
            marginBasisPoints: rest.0,
            smaller: first,
            larger: second
        )
    },
    seed: PropertySeed.exchangeRate,
    edges: [
        ConvertCase(
            amount: EUR(minorUnits: conversionAmountFloor),
            rate: "0.1",
            onwardRate: "0.1",
            marginBasisPoints: 0,
            smaller: EUR(minorUnits: conversionAmountFloor),
            larger: EUR(minorUnits: conversionAmountBound)
        ),
        ConvertCase(
            amount: EUR(minorUnits: conversionAmountBound),
            rate: "10",
            onwardRate: "10",
            marginBasisPoints: Int(maxMarginBasisPoints),
            smaller: EUR(minorUnits: conversionAmountFloor),
            larger: EUR(minorUnits: conversionAmountFloor)
        ),
    ]
)

@Suite("Exchange-rate properties")
struct ExchangeRatePropertyTests {

    @Test("A positive amount converts to a positive amount", arguments: convertCases)
    private func conversionIsPositive(_ convert: ConvertCase) throws {
        let rate = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(convert.rate))

        for rule in roundingRules {
            #expect(convert.amount.converted(using: rate).rounded(rule) > .zero)
        }
    }

    @Test("A crossed rate keeps a positive amount positive", arguments: convertCases)
    private func crossedConversionIsPositive(_ convert: ConvertCase) throws {
        let eurGbp = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(convert.rate))
        let gbpUsd = try #require(ExchangeRate<Currencies.GBP, Currencies.USD>(convert.onwardRate))
        let eurUsd = eurGbp.crossed(with: gbpUsd)

        for rule in roundingRules {
            #expect(convert.amount.converted(using: eurUsd).rounded(rule) > .zero)
        }
    }

    @Test("Applying a margin never exceeds the mid rate and stays positive", arguments: convertCases)
    private func marginStaysBelowMidAndPositive(_ convert: ConvertCase) throws {
        let rate = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(convert.rate))
        let margin = try #require(Margin(.basisPoints(convert.marginBasisPoints)))

        for rule in roundingRules {
            let mid = convert.amount.converted(using: rate).rounded(rule)
            let customer = convert.amount.converted(using: rate.applyingMargin(margin)).rounded(rule)

            #expect(customer <= mid)
            #expect(customer > .zero)
        }
    }

    @Test("Converting is monotonic in the amount", arguments: convertCases)
    private func conversionIsMonotonic(_ convert: ConvertCase) throws {
        let rate = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(convert.rate))

        for rule in roundingRules {
            let lower = convert.smaller.converted(using: rate).rounded(rule)
            let upper = convert.larger.converted(using: rate).rounded(rule)

            #expect(lower <= upper)
        }
    }
}
