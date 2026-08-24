import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Format Style Tests")
struct MoneyFormatStyleTests {
    private static let britishEnglish = Locale(identifier: "en_GB")

    @Test("A typed amount renders localized, in an explicit locale")
    func rendersTypedAmountLocalized() {
        let style = GBP.FormatStyle().locale(Self.britishEnglish)

        #expect(style.format(GBP(minorUnits: 4_99)) == "£4.99")
        #expect(GBP(minorUnits: 1_234_56).formatted(style) == "£1,234.56")
        #expect(style.format(GBP(minorUnits: -4_99)) == "-£4.99")
    }

    @Test("A runtime amount renders the same as its typed twin")
    func rendersRuntimeAmountLocalized() {
        let style = Money.FormatStyle().locale(Self.britishEnglish)

        #expect(style.format(Money(minorUnits: 4_99, currency: .gbp)) == "£4.99")
        #expect(style.format(Money(minorUnits: 1_234_56, currency: .gbp)) == "£1,234.56")
        #expect(style.format(Money(minorUnits: -4_99, currency: .gbp)) == "-£4.99")
    }

    @Test("A localized string parses back to the amount it came from")
    func parsesLocalizedTextBack() throws {
        let style = GBP.FormatStyle().locale(Self.britishEnglish)
        let amount = GBP(minorUnits: 12_34)

        #expect(try style.parseStrategy.parse(style.format(amount)) == amount)
        #expect(try style.parseStrategy.parse("£1,234.56") == GBP(minorUnits: 1_234_56))
    }
}
