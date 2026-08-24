import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Parse Strategy Tests")
struct MoneyParseStrategyTests {
    private typealias BHD = MoneyOf<Currencies.BHD>
    private typealias CHF = MoneyOf<Currencies.CHF>

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

    // MARK: - Round trips

    @Test("Every amount the style writes parses back to the amount it came from")
    func roundTripsWhatTheStyleWrites() throws {
        let amounts = [0, 1, -1, 4_99, -4_99, 1_234_56, -1_234_56, 99_99]

        for minorUnits in amounts {
            let sterling = GBP(minorUnits: minorUnits)
            let francs = CHF(minorUnits: minorUnits)
            let dinars = BHD(minorUnits: minorUnits)
            let yen = JPY(minorUnits: minorUnits)

            #expect(try Self.parsesBack(sterling, GBP.FormatStyle()))
            #expect(try Self.parsesBack(francs, CHF.FormatStyle()))
            #expect(try Self.parsesBack(dinars, BHD.FormatStyle()))
            #expect(try Self.parsesBack(yen, JPY.FormatStyle()))
        }
    }

    @Test("The ISO code and full name forms parse back too")
    func roundTripsTheOtherPresentations() throws {
        let amount = GBP(minorUnits: 1_234_56)

        for presentation in [CurrencyFormatStyleConfiguration.Presentation.isoCode, .fullName] {
            let style = Self.sterling.presentation(presentation)

            #expect(try style.parseStrategy.parse(style.format(amount)) == amount)
        }
    }

    @Test("A narrow symbol the locale cannot pin to one currency does not parse back")
    func refusesANarrowSymbolTheLocaleCannotPin() {
        // "$" in British English names no one currency, so ICU declines to read it as US
        // dollars. Recorded because it is the one form the style writes that it cannot read.
        let style = USD.FormatStyle().locale(Self.britishEnglish).presentation(.narrow)
        let written = style.format(USD(minorUnits: 4_99))

        #expect(written == "$4.99")
        #expect(throws: MoneyParsingError.unrecognizedText(written)) {
            try style.parseStrategy.parse(written)
        }
    }

    // MARK: - Rounding is a display choice, never a parsing one

    @Test("What a style with a coarser precision shows still parses exactly as shown")
    func parsesWhatADisplayRoundingStyleShows() throws {
        let style = Self.sterling.precision(.fractionLength(0))
        let written = style.format(GBP(minorUnits: 4_99))

        #expect(written == "£5")
        #expect(try style.parseStrategy.parse(written) == GBP(minorUnits: 5_00))
    }

    @Test("What a style with a rounding increment shows still parses exactly as shown")
    func parsesWhatAnIncrementRoundingStyleShows() throws {
        let style = CHF.FormatStyle().locale(Self.britishEnglish).rounded(increment: 5)
        let written = style.format(CHF(minorUnits: 4_98))

        #expect(written == "CHF\u{00A0}5.00")
        #expect(try style.parseStrategy.parse(written) == CHF(minorUnits: 5_00))
    }

    @Test("A style told to round its display still refuses text it cannot read exactly")
    func stillRefusesInexactTextUnderARoundingStyle() {
        let style = Self.sterling.precision(.fractionLength(0)).rounded(rule: .down, increment: 5)

        #expect(throws: MoneyParsingError.inexactAmount(.gbp)) {
            try style.parseStrategy.parse("£4.999")
        }
    }

    // MARK: - The ends of the range

    @Test("The largest and smallest amounts write and read back")
    func roundTripsTheEndsOfTheRange() throws {
        let style = Self.sterling

        #expect(style.format(GBP.max) == "£92,233,720,368,547,758.07")
        #expect(style.format(GBP.min) == "-£92,233,720,368,547,758.08")
        #expect(try style.parseStrategy.parse(style.format(GBP.max)) == GBP.max)
        #expect(try style.parseStrategy.parse(style.format(GBP.min)) == GBP.min)

        // Yen put every digit before the separator, which is the widest number ICU has to read.
        let yen = JPY.FormatStyle().locale(Self.britishEnglish)

        #expect(yen.format(JPY.max) == "JP¥9,223,372,036,854,775,807")
        #expect(yen.format(JPY.min) == "-JP¥9,223,372,036,854,775,808")
        #expect(try yen.parseStrategy.parse(yen.format(JPY.max)) == JPY.max)
        #expect(try yen.parseStrategy.parse(yen.format(JPY.min)) == JPY.min)
    }

    // MARK: - Helpers

    private static func parsesBack<C: CurrencyType>(
        _ amount: MoneyOf<C>,
        _ style: MoneyOf<C>.FormatStyle
    ) throws -> Bool {
        let localized = style.locale(britishEnglish)

        return try localized.parseStrategy.parse(localized.format(amount)) == amount
    }
}
