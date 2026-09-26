import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

@Suite("Money Format Style Modifier Tests")
struct MoneyFormatStyleModifierTests {
    private typealias CHF = MoneyOf<Currencies.CHF>
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

    @Test("Grouping can be turned off")
    func grouping() {
        let amount = GBP(minorUnits: 1_234_56)

        #expect(Self.sterling.format(amount) == "£1,234.56")
        #expect(Self.sterling.grouping(.never).format(amount) == "£1234.56")
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

    @Test("Precision is the opt-in to rounding what is shown")
    func precision() {
        let amount = GBP(minorUnits: 4_99)

        #expect(Self.sterling.format(amount) == "£4.99")
        #expect(Self.sterling.precision(.fractionLength(0)).format(amount) == "£5")
#if canImport(Darwin)
        // Significant digits is not engine-expressible, so this falls back to Foundation, whose ICU
        // output differs and races under parallel tests on swift-corelibs-foundation.
        #expect(Self.sterling.precision(.significantDigits(2)).format(amount) == "£5.0")
#endif
    }

    @Test("A rounding rule decides which way the shown digits go")
    func roundingRule() {
        let style = Self.sterling.precision(.fractionLength(0))

        #expect(style.format(GBP(minorUnits: 4_99)) == "£5")
        #expect(style.rounded(rule: .down).format(GBP(minorUnits: 4_99)) == "£4")
        #expect(style.rounded(rule: .up).format(GBP(minorUnits: 4_01)) == "£5")
    }

    @Test("A tie in the shown digits goes to the even digit unless the caller says otherwise")
    func roundingRuleDefaultsToHalfEven() {
        // Half a pound, which is the tie at this precision and the one amount that tells the two
        // nearest rules apart. The style hands ICU no rule of its own until the caller sets one,
        // so this pins what ICU's own default is: half to even, showing 4.50 as 4 and 5.50 as 6.
        let style = Self.sterling.precision(.fractionLength(0))

        #expect(style.format(GBP(minorUnits: 4_50)) == "£4")
        #expect(style.format(GBP(minorUnits: 5_50)) == "£6")
        #expect(style.rounded(rule: .toNearestOrAwayFromZero).format(GBP(minorUnits: 4_50)) == "£5")
    }

    @Test("A rounding increment counts the currency's smallest units")
    func roundingIncrement() {
        let style = CHF.FormatStyle().locale(Self.britishEnglish)
        let amount = CHF(minorUnits: 4_98)

        #expect(style.format(amount) == "CHF\u{00A0}4.98")
#if canImport(Darwin)
        // A rounding increment is not engine-expressible, so this falls back to Foundation, whose ICU
        // output differs and races under parallel tests on swift-corelibs-foundation.
        #expect(style.rounded(increment: 5).format(amount) == "CHF\u{00A0}5.00")
#endif
    }

    @Test("Our engine keeps the currency symbol where Foundation drops it")
    func groupingOffBesideASecondOptionKeepsTheSymbol() {
        // Foundation's currency style drops the symbol when grouping is turned off beside a sign,
        // separator or rounding rule — the worst thing a money formatter can quietly do. For a covered
        // locale the non-ICU engine renders it correctly instead. The defect remains in
        // `Decimal.FormatStyle.Currency` itself, recorded below. Verified on Swift 6.3.2.
        let sut = Self.sterling.grouping(.never).sign(strategy: .always())

        #expect(sut.format(GBP(minorUnits: 1_234_56)) == "+£1234.56")

#if canImport(Darwin)
        // The recorded Foundation defect: only Apple's Foundation drops the symbol here. On
        // swift-corelibs-foundation it does not, and its ICU races under parallel tests.
        let foundationStyle = Decimal.FormatStyle.Currency(code: "GBP", locale: Self.britishEnglish)
            .grouping(.never)
            .sign(strategy: .always())

        withKnownIssue("Foundation's own currency style still drops the symbol") {
            let value = try #require(Decimal(string: "1234.56"))

            #expect(foundationStyle.format(value) == "+£1234.56")
        }
#endif
    }

    @Test("A recognised fraction length renders through the engine, keeping the symbol Foundation drops")
    func fixedPrecisionRendersThroughTheEngine() {
        // The grouping-off-beside-a-sign defect again: with the currency symbol kept, the render came
        // from the engine, not the fallback. A fixed fraction length is engine-expressible, so it does.
        let sut = Self.sterling.grouping(.never).sign(strategy: .always()).precision(.fractionLength(2))

        #expect(sut.format(GBP(minorUnits: 1_234_56)) == "+£1234.56")
    }

    @Test("The highest engine-expressible fraction length pads with zeros instead of overflowing")
    func highestFractionLengthPadsWithoutOverflowing() {
        // 19 is the widest fraction length `fractionLength(of:)` still routes to the engine; it used to
        // overflow the engine's internal arithmetic for any amount.
        let sut = Self.sterling.precision(.fractionLength(19))

        #expect(sut.format(GBP(minorUnits: 4_99)) == "£4.9900000000000000000")
    }

#if canImport(Darwin)
    // The whole test asserts Foundation's fallback output (the dropped symbol), which only Apple's
    // Foundation produces; swift-corelibs-foundation differs and races under parallel tests.
    @Test("An unrecognised precision falls back to Foundation")
    func significantDigitsFallsBack() {
        // Significant digits is not engine-expressible, so the style hands the render to Foundation,
        // which under this option combination drops the symbol. The dropped symbol is the tell that it
        // fell back, in contrast to the fixed-length case above.
        let sut = Self.sterling.grouping(.never).sign(strategy: .always()).precision(.significantDigits(2))

        #expect(sut.format(GBP(minorUnits: 1_234_56)) == "1234.56")
    }
#endif

    @Test("A full name at an explicit precision follows the plural of the digits shown")
    func fullNamePrecisionUsesShownDigitsForPlural() {
        // One pound shown at no decimals is "1", which is singular; at the natural two decimals it is
        // "1.00", which is plural ("pounds"). The name has to follow the digits actually shown, which
        // the engine reads from the scale rather than the fixed length, so a full name at an explicit
        // precision renders through ICU.
        let style = Self.sterling.presentation(.fullName)

        #expect(style.format(GBP(minorUnits: 1_00)) == "1.00 British pounds")
#if canImport(Darwin)
        // A full name at an explicit precision renders through ICU, whose output differs and races
        // under parallel tests on swift-corelibs-foundation.
        #expect(style.precision(.fractionLength(0)).format(GBP(minorUnits: 1_00)) == "1 British pound")
#endif
    }

    @Test("Each modifier keeps every option set before it")
    func modifiersKeepEarlierOptions() {
        let sut = Self.sterling
            .presentation(.isoCode)
            .sign(strategy: .always())
            .rounded(rule: .down)
            .precision(.fractionLength(0))

        #expect(sut.format(GBP(minorUnits: 4_99)) == "+GBP\u{00A0}4")
    }
}
