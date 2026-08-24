import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Parse Strategy Tests")
struct MoneyParseStrategyTests {
    private static let britishEnglish = Locale(identifier: "en_GB")

    private static var sterling: GBP.FormatStyle {
        GBP.FormatStyle().locale(britishEnglish)
    }

    // MARK: - The three refusals

    @Test("Text that is not an amount is refused as unrecognized")
    func refusesTextThatIsNotAnAmount() {
        #expect(throws: MoneyParsingError.unrecognizedText("not an amount")) {
            try Self.sterling.parseStrategy.parse("not an amount")
        }

        #expect(throws: MoneyParsingError.unrecognizedText("")) {
            try Self.sterling.parseStrategy.parse("")
        }
    }

    @Test("An amount finer than the currency divides is refused rather than rounded")
    func refusesAnAmountFinerThanTheCurrencyDivides() {
        #expect(throws: MoneyParsingError.inexactAmount(.gbp)) {
            try Self.sterling.parseStrategy.parse("£4.999")
        }

        // Yen have no subunit at all, so any fraction of one is too fine.
        let yen = JPY.FormatStyle().locale(Self.britishEnglish)

        #expect(throws: MoneyParsingError.inexactAmount(.jpy)) {
            try yen.parseStrategy.parse("JP¥4.5")
        }
    }

    @Test("An amount too large to store is refused as unrepresentable")
    func refusesAnAmountTooLargeToStore() {
        #expect(throws: MoneyParsingError.unrepresentableAmount(.gbp)) {
            try Self.sterling.parseStrategy.parse("£99,999,999,999,999,999,999.99")
        }

        // One unit past the top of the range, which is the smallest refusal of this kind.
        #expect(throws: MoneyParsingError.unrepresentableAmount(.gbp)) {
            try Self.sterling.parseStrategy.parse("£92,233,720,368,547,758.08")
        }
    }

    @Test("A number too large for Decimal itself is refused as unrepresentable")
    func refusesANumberTooLargeForDecimal() {
        let vast = String(repeating: "9", count: 40)

        #expect(throws: MoneyParsingError.unrepresentableAmount(.gbp)) {
            try Self.sterling.parseStrategy.parse("£\(vast).99")
        }
    }
}
