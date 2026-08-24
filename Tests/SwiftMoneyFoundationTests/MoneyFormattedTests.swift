import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Formatted Tests")
struct MoneyFormattedTests {
    private static let britishEnglish = Locale(identifier: "en_GB")

    @Test("An amount with no style named renders through the default style")
    func rendersThroughTheDefaultStyle() throws {
        let amount = GBP(minorUnits: 4_99)

        // Read from Foundation directly, so this says what the default is rather than only that
        // two paths agree: the user's locale, and every digit sterling divides into.
        let expected = Decimal.FormatStyle.Currency(code: "GBP", locale: .autoupdatingCurrent)
            .precision(.fractionLength(2))
            .format(try #require(Decimal(string: "4.99")))

        #expect(amount.formatted() == expected)
        #expect(amount.formatted() == GBP.FormatStyle().format(amount))
    }

    @Test("A runtime amount with no style named renders through the default style too")
    func rendersARuntimeAmountThroughTheDefaultStyle() throws {
        let amount = Money(minorUnits: 1_234, currency: .bhd)

        let expected = Decimal.FormatStyle.Currency(code: "BHD", locale: .autoupdatingCurrent)
            .precision(.fractionLength(3))
            .format(try #require(Decimal(string: "1.234")))

        #expect(amount.formatted() == expected)
    }

    @Test("The dot syntax names the same style, with no currency code to disagree with")
    func rendersThroughTheDotSyntax() {
        let amount = GBP(minorUnits: 4_99)

        #expect(amount.formatted(.currency(locale: Self.britishEnglish)) == "£4.99")
        #expect(
            Money(minorUnits: 4_99, currency: .gbp)
                .formatted(.currency(locale: Self.britishEnglish)) == "£4.99"
        )
    }
}
