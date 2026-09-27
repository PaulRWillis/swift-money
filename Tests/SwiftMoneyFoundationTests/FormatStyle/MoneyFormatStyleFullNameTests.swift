import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import SwiftMoneyLocalization
import Testing

// A full name is the one presentation whose text depends on the amount, so these drive it across the
// locales the CLDR data covers and check every case against ICU. Where the two agree, the engine is
// picking the same plural form ICU does.
@Suite("Money Format Style Full Name Tests")
struct MoneyFormatStyleFullNameTests {

    static func currency(_ iso: String) -> Currency {
        guard let code = CurrencyCode(string: iso), let currency = Currency(iso: code) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return currency
    }

    static func icu(_ minorUnits: Int64, _ currency: Currency, _ localeID: String) -> String {
        let places = currency.unitScale.decimalPlaces
        let divisor = Decimal(sign: .plus, exponent: places, significand: 1)

        return Decimal.FormatStyle.Currency(code: String(currency.code), locale: Locale(identifier: localeID))
            .presentation(.fullName)
            .precision(.fractionLength(places))
            .format(Decimal(minorUnits) / divisor)
    }

    static let amounts: [Int64] = [0, 1, 2, 1_00, 2_00, 12_34_56, -12_34_56, 1_000_000_00]

    static let cases: [(locale: String, currencies: [String])] = [
        ("en_US", ["USD", "GBP", "CLP", "JPY"]),
        ("en_GB", ["GBP", "EUR", "CLP"]),
        ("de_DE", ["EUR", "USD"]),
        ("fr_FR", ["EUR", "USD"]),
        ("ja_JP", ["JPY", "USD"]),
    ]

    @Test("A currency's full name matches ICU for every covered locale", arguments: cases)
    func fullNamesMatchICU(_ row: (locale: String, currencies: [String])) throws {
        for iso in row.currencies {
            let currency = Self.currency(iso)
            let style = Money.FormatStyle().locale(Locale(identifier: row.locale)).presentation(.fullName)

            // The engine has to be the one answering, or this would compare ICU with itself.
            #expect(
                MoneyLocalization.fullNameMoneyFormat(
                    for: currency, minorUnits: 1, locale: LocaleIdentifier(row.locale)
                ) != nil,
                "\(row.locale) should name \(iso) without ICU"
            )

            for amount in Self.amounts {
                let ours = style.format(Money(minorUnits: amount, currency: currency))

                #expect(ours == Self.icu(amount, currency, row.locale), "\(row.locale)/\(iso) \(amount)")
            }
        }
    }

    // The two sides of the finding this phase is built on, in one test.
    @Test("One unit is singular only where the currency shows no fraction digits")
    func singularNeedsNoFractionDigits() {
        let style = Money.FormatStyle().locale(Locale(identifier: "en_US")).presentation(.fullName)

        #expect(style.format(Money(minorUnits: 1, currency: Self.currency("CLP"))) == "1 Chilean peso")
        #expect(style.format(Money(minorUnits: 1_00, currency: .gbp)) == "1.00 British pounds")
    }
}
