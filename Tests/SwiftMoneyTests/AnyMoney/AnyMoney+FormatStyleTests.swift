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

// MARK: - Static factory shorthand

@Suite("AnyMoney – FormatStyle – Static Factories")
struct AnyMoney_FormatStyle_StaticFactoryTests {

    private let enGB = Locale(identifier: "en_GB")
    private let fr   = Locale(identifier: "fr")

    private var gbp150: AnyMoney { Money<GBP>(minorUnits: 150).erased }
    private var eur105: AnyMoney { Money<EUR>(minorUnits: 105).erased }
    private var jpy100: AnyMoney { Money<JPY>(minorUnits: 100).erased }

    // MARK: .locale

    @Test(".locale(_:) produces the same result as the designated initialiser")
    func localeDotSyntax() {
        let dotSyntax = gbp150.formatted(.locale(enGB))
        let explicit  = gbp150.formatted(AnyMoney.FormatStyle(locale: enGB))
        #expect(dotSyntax == explicit)
    }

    @Test(".locale(_:) respects the given locale")
    func localeDotSyntaxFr() {
        #expect(eur105.formatted(.locale(fr)) == "1,05\u{00A0}€")
    }

    // MARK: .grouping

    @Test(".grouping(_:) equals FormatStyle().grouping(_:) on the same value")
    func groupingDotSyntax() {
        let large = Money<GBP>(minorUnits: 1_234_567).erased
        let dotSyntax = large.formatted(.grouping(.never).locale(enGB))
        let explicit  = large.formatted(AnyMoney.FormatStyle(locale: enGB).grouping(.never))
        #expect(dotSyntax == explicit)
    }

    @Test(".grouping(.never) removes thousands separator")
    func groupingNeverRemovesSeparator() {
        let large = Money<GBP>(minorUnits: 1_234_567).erased
        #expect(!large.formatted(.grouping(.never).locale(enGB)).contains(","))
    }

    // MARK: .precision

    @Test(".precision(.fractionLength(0)) drops pence")
    func precisionFractionLength0() {
        #expect(gbp150.formatted(.precision(.fractionLength(0)).locale(enGB)) == "£2")
    }

    @Test(".precision(_:) equals FormatStyle().precision(_:) on the same value")
    func precisionDotSyntax() {
        let dotSyntax = gbp150.formatted(.precision(.fractionLength(0)).locale(enGB))
        let explicit  = gbp150.formatted(AnyMoney.FormatStyle(locale: enGB).precision(.fractionLength(0)))
        #expect(dotSyntax == explicit)
    }

    // MARK: .sign

    @Test(".sign(strategy: .always()) prefixes positive values")
    func signAlways() {
        #expect(gbp150.formatted(.sign(strategy: .always()).locale(enGB)) == "+£1.50")
    }

    // MARK: .presentation

    @Test(".presentation(.isoCode) uses the ISO code")
    func presentationIsoCode() {
        #expect(gbp150.formatted(.presentation(.isoCode).locale(enGB)).contains("GBP"))
    }

    // MARK: .decimalSeparator

    @Test(".decimalSeparator(strategy: .always) always shows separator")
    func decimalSeparatorAlways() {
        let output = jpy100.formatted(.decimalSeparator(strategy: .always).locale(enGB))
        #expect(output.contains("."))
    }

    // MARK: .rounded

    @Test(".rounded() equals FormatStyle().rounded() on the same value")
    func roundedDotSyntax() {
        let dotSyntax = gbp150.formatted(.rounded().locale(enGB))
        let explicit  = gbp150.formatted(AnyMoney.FormatStyle(locale: enGB).rounded())
        #expect(dotSyntax == explicit)
    }

    // MARK: Chaining from static factory

    @Test("static factory result is chainable with further modifiers")
    func chainingFromStaticFactory() {
        let large = Money<GBP>(minorUnits: 1_234_567).erased
        let chained  = large.formatted(.grouping(.never).locale(enGB))
        let baseline = large.formatted(AnyMoney.FormatStyle(locale: enGB).grouping(.never))
        #expect(chained == baseline)
    }
}
