import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Proves the CLDR-generated locale data, composed into a MoneyFormat and rendered by the Core engine,
// matches ICU — with no ICU at render time. Drives both sides from the same locale, currency, and
// presentation. Any mismatch is either a generator bug or CLDR-48-vs-platform-ICU drift, and is worth
// surfacing rather than hiding.
@Suite("SwiftMoneyLocalization ICU parity")
struct MoneyLocalizationTests {

    static func currency(_ iso: String) -> Currency {
        guard let code = CurrencyCode(string: iso), let currency = Currency(iso: code) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return currency
    }

    // (localeID as Foundation and CLDR see it, currencies to exercise there).
    static let matrix: [(locale: String, currencies: [String])] = [
        ("en_US", ["USD", "EUR", "GBP"]),
        ("en_GB", ["GBP", "USD", "EUR"]),
        ("de_DE", ["EUR", "USD", "GBP"]),
        ("fr_FR", ["EUR", "USD"]),
        ("ja_JP", ["JPY", "USD"]),
    ]

    static let presentations: [(mine: CurrencyPresentation, icu: Decimal.FormatStyle.Currency.Configuration.Presentation)] = [
        (.standard, .standard),
        (.isoCode, .isoCode),
        (.narrow, .narrow),
    ]

    static let amounts: [Int64] = [0, 1_00, 12_34_56, -12_34_56, 1_234_567_89]

    static func icu(_ minorUnits: Int64, _ iso: String, _ localeID: String, _ presentation: Decimal.FormatStyle.Currency.Configuration.Presentation, places: Int) -> String {
        var style = Decimal.FormatStyle.Currency(code: iso, locale: Locale(identifier: localeID))
            .precision(.fractionLength(places))
        if presentation != .standard {
            style = style.presentation(presentation)
        }
        let divisor = Decimal(sign: .plus, exponent: places, significand: 1)
        return style.format(Decimal(minorUnits) / divisor)
    }

    @Test("Generated locale data renders to match ICU", arguments: matrix)
    func matchesICU(_ row: (locale: String, currencies: [String])) throws {
        for iso in row.currencies {
            let currency = Self.currency(iso)
            let places = currency.unitScale.decimalPlaces

            for presentation in Self.presentations {
                let format = try #require(
                    MoneyLocalization.moneyFormat(for: currency, locale: LocaleIdentifier(row.locale), presentation: presentation.mine),
                    "\(row.locale) should be a covered locale"
                )

                for amount in Self.amounts {
                    let engine = format.format(Money(minorUnits: amount, currency: currency))

                    // Known CLDR-48-vs-platform drift: CLDR 48 gives the ja JPY symbol as the fullwidth
                    // ￥ (U+FFE5); the ICU bundled with the OS still uses the halfwidth ¥ (U+00A5). CLDR
                    // is our source of truth, so we assert our value rather than ICU's for this one cell.
                    if row.locale == "ja_JP", iso == "JPY", presentation.mine == .standard {
                        #expect(engine.contains("\u{FFE5}"))
                        continue
                    }

                    let icu = Self.icu(amount, iso, row.locale, presentation.icu, places: places)
                    #expect(engine == icu, "\(row.locale)/\(iso)/\(presentation.mine) \(amount): '\(engine)' vs ICU '\(icu)'")
                }
            }
        }
    }

    @Test("An uncovered locale returns nil, and a region falls back to its language")
    func coverage() {
        #expect(MoneyLocalization.moneyFormat(for: Self.currency("GBP"), locale: "zz-ZZ") == nil)
        // de_DE is not a table key; it must fall back to "de".
        #expect(MoneyLocalization.moneyFormat(for: Self.currency("EUR"), locale: "de_DE") != nil)
    }
}
