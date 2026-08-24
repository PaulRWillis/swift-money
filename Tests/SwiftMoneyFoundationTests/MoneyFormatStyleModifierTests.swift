import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Format Style Modifier Tests")
struct MoneyFormatStyleModifierTests {
    private typealias MGA = MoneyOf<Currencies.MGA>

    private static let britishEnglish = Locale(identifier: "en_GB")
    private static let germanGerman = Locale(identifier: "de_DE")

    private static var sterling: GBP.FormatStyle {
        GBP.FormatStyle().locale(britishEnglish)
    }

    @Test("The locale decides the symbol's place and the separators")
    func locale() {
        let amount = GBP(minorUnits: 1_234_56)

        #expect(Self.sterling.format(amount) == "£1,234.56")
        #expect(GBP.FormatStyle().locale(Self.germanGerman).format(amount) == "1.234,56\u{00A0}£")
    }

    @Test("A plus sign can be asked for on an amount that would not carry one")
    func sign() {
        let amount = GBP(minorUnits: 4_99)

        #expect(Self.sterling.format(amount) == "£4.99")
        #expect(Self.sterling.sign(strategy: .always()).format(amount) == "+£4.99")
        #expect(Self.sterling.sign(strategy: .never).format(GBP(minorUnits: -4_99)) == "£4.99")
    }

    @Test("A decimal separator can be asked for where no digits follow it")
    func decimalSeparator() {
        // Yen, which have no subunit, so the default style writes no separator at all.
        let amount = JPY(minorUnits: 499)
        let style = JPY.FormatStyle().locale(Self.britishEnglish)

        #expect(style.format(amount) == "JP¥499")
        #expect(style.decimalSeparator(strategy: .always).format(amount) == "JP¥499.")
    }

    @Test("The currency's own scale sets the digits, not ICU's idea of the currency")
    func precisionComesFromTheScale() {
        // The ariary, where the two disagree: ICU shows no decimals, and the repo's MGA divides
        // into 100. Without the pin the style would drop 0.40 from what it shows. Every other
        // currency the suite formats has ICU agreeing with its scale, so this is the one case
        // that can catch the pin being removed.
        let style = MGA.FormatStyle().locale(Self.britishEnglish)

        #expect(style.format(MGA(minorUnits: 1_40)) == "MGA\u{00A0}1.40")
        #expect(style.format(MGA(minorUnits: 1_234_56)) == "MGA\u{00A0}1,234.56")
    }
}
