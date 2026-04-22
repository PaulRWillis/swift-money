import Foundation
import Testing
import SwiftMoney

@Suite("AnyMoney – Formatting")
struct AnyMoney_FormatStyleTests {

    private let enUS = Locale(identifier: "en_US")
    private let enGB = Locale(identifier: "en_GB")

    // MARK: - formatted()

    @Test("formatted() produces a non-empty string")
    func formattedNonEmpty() {
        let any = Money<GBP>(minorUnits: 100).erased
        #expect(!any.formatted().isEmpty)
    }

    @Test("formatted() matches Money<GBP> output for GBP")
    func formattedMatchesTypedGBP() {
        let money = Money<GBP>(minorUnits: 100)
        let style = Money<GBP>.FormatStyle(locale: enGB)
        #expect(money.erased.formatted(AnyMoney.FormatStyle(locale: enGB)) == money.formatted(style))
    }

    @Test("formatted() matches Money<EUR> output for EUR")
    func formattedMatchesTypedEUR() {
        let money = Money<EUR>(minorUnits: 100)
        let style = Money<EUR>.FormatStyle(locale: enGB)
        #expect(money.erased.formatted(AnyMoney.FormatStyle(locale: enGB)) == money.formatted(style))
    }

    @Test("formatted() matches Money<JPY> output for JPY (ratio-1 currency)")
    func formattedMatchesTypedJPY() {
        let money = Money<JPY>(minorUnits: 500)
        let style = Money<JPY>.FormatStyle(locale: enUS)
        #expect(money.erased.formatted(AnyMoney.FormatStyle(locale: enUS)) == money.formatted(style))
    }

    @Test(
        "formatted(_:) produces correct currency symbol",
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
        // en_GB: GBP→£, EUR→€, JPY→JP¥ (foreign-currency disambiguation symbols)
        #expect(any.formatted(AnyMoney.FormatStyle(locale: Locale(identifier: "en_GB"))) == expected)
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
