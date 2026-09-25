import SwiftMoneyCore
import Testing

// Format-then-parse does no arithmetic — only `description` and the parser run — so the whole Int64 range
// is safe, and the edge corpus deliberately includes Int64.min and .max, the values a scaled decimal
// form is most likely to mishandle.
private let fullRange = Int64.min ... Int64.max

private let typedAmounts: [GBP] = samples(
    .typedMoney(minorUnitsIn: fullRange),
    seed: PropertySeed.roundTrip,
    edges: [.min, .max, .zero, GBP(minorUnits: 1), GBP(minorUnits: -1)]
)

private let isoAmounts: [Money] = samples(
    .runtimeMoney(minorUnitsIn: fullRange, currency: .isoCurrency),
    seed: PropertySeed.roundTrip,
    edges: [
        Money(minorUnits: Int64.min, currency: .gbp),
        Money(minorUnits: Int64.max, currency: .gbp),
        Money(minorUnits: Int64.min, currency: .jpy),
        Money(minorUnits: Int64.max, currency: .jpy),
        Money(minorUnits: 0, currency: .usd),
        Money(minorUnits: 1, currency: .eur),
        Money(minorUnits: -1, currency: .eur),
    ]
)

private let customAmounts: [Money] = samples(
    .runtimeMoney(minorUnitsIn: fullRange, currency: .customScaleCurrency),
    seed: PropertySeed.roundTrip,
    edges: [
        Money(minorUnits: Int64.min, currency: customCurrency(code: "GEM", unitScale: 100_000_000)),
        Money(minorUnits: Int64.max, currency: customCurrency(code: "GEM", unitScale: 100_000_000)),
        Money(minorUnits: Int64.min, currency: customCurrency(code: "PTS", unitScale: 1_000)),
        Money(minorUnits: Int64.max, currency: customCurrency(code: "KHO", unitScale: 100)),
        Money(minorUnits: 0, currency: customCurrency(code: "KHO", unitScale: 1)),
    ]
)

@Suite("Format round-trip properties")
struct RoundTripPropertyTests {

    @Test("A typed amount round-trips through its description", arguments: typedAmounts)
    private func typedRoundTrip(_ money: GBP) throws {
        #expect(try #require(GBP(string: money.description)) == money)
    }

    @Test("An ISO runtime amount round-trips through its description", arguments: isoAmounts)
    private func isoRoundTrip(_ money: Money) throws {
        #expect(try #require(Money(string: money.description)) == money)
    }

    @Test("A custom-currency amount round-trips through its description", arguments: customAmounts)
    private func customRoundTrip(_ money: Money) throws {
        #expect(try #require(Money(string: money.description, currency: money.currency)) == money)
    }
}
