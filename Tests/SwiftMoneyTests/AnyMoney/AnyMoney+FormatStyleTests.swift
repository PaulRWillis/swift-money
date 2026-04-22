#warning("Support testing on Linux where Foundation is not always consistent or available?")
import Foundation
import Testing
import SwiftMoney

@Suite("AnyMoney – Formatting")
struct AnyMoney_FormatStyleTests {

    // MARK: - formatted()

    @Test("formatted() produces a non-empty string")
    func formattedNonEmpty() {
        let any = Money<GBP>(minorUnits: 100).erased
        #expect(!any.formatted().isEmpty)
    }

    @Test("formatted() matches Money<GBP> output for GBP")
    func formattedMatchesTypedGBP() {
        let money = Money<GBP>(minorUnits: 100)
        #expect(money.erased.formatted() == money.formatted())
    }

    @Test("formatted() matches Money<EUR> output for EUR")
    func formattedMatchesTypedEUR() {
        let money = Money<EUR>(minorUnits: 100)
        #expect(money.erased.formatted() == money.formatted())
    }

    @Test("formatted() matches Money<JPY> output for JPY (ratio-1 currency)")
    func formattedMatchesTypedJPY() {
        let money = Money<JPY>(minorUnits: 500)
        #expect(money.erased.formatted() == money.formatted())
    }

    #warning("Might need to set locale for tests for reproducibility")
    @Test(
        "formatted() produces correct currency symbol",
        arguments: zip(
            [
                Money<GBP>(minorUnits: 100).erased,
                Money<EUR>(minorUnits: 100).erased,
                Money<JPY>(minorUnits: 100).erased,
            ],
            ["£1.00", "€1.00", "JP¥100"]
        )
    )
    func formattedCurrencySymbol(any: AnyMoney, expected: String) {
        #expect(any.formatted() == expected)
    }

    // MARK: - CustomStringConvertible

    @Test("description equals formatted()")
    func descriptionEqualsFormatted() {
        let any = Money<GBP>(minorUnits: 500).erased
        #expect(any.description == any.formatted())
    }

    @Test("description matches typed Money description for GBP")
    func descriptionMatchesTypedGBP() {
        let money = Money<GBP>(minorUnits: 500)
        #expect(money.erased.description == money.description)
    }

    @Test("description matches typed Money description for JPY")
    func descriptionMatchesTypedJPY() {
        let money = Money<JPY>(minorUnits: 500)
        #expect(money.erased.description == money.description)
    }
}
