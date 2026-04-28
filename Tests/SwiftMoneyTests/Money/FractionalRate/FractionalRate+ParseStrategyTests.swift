import Foundation
import Testing
import SwiftMoney

@Suite("FractionalRate - ParseStrategy")
struct FractionalRateParseStrategyTests {

    // MARK: - Fraction parse round-trips

    @Test("Round-trip: format as fraction then parse back")
    func fractionRoundTrip() throws {
        let original = try #require(FractionalRate(numerator: 3, denominator: 4))
        let formatted = original.formatted(.fraction)
        let parsed = try FractionalRate(formatted, format: .fraction)
        #expect(parsed == original)
    }

    @Test("Round-trip: negative fraction")
    func negativeFractionRoundTrip() throws {
        let original = try #require(FractionalRate(numerator: -7, denominator: 16))
        let formatted = original.formatted(.fraction)
        let parsed = try FractionalRate(formatted, format: .fraction)
        #expect(parsed == original)
    }

    @Test("Round-trip: zero fraction")
    func zeroFractionRoundTrip() throws {
        let original = try #require(FractionalRate(numerator: 0, denominator: 1))
        let formatted = original.formatted(.fraction)
        let parsed = try FractionalRate(formatted, format: .fraction)
        #expect(parsed == original)
    }

    @Test("Round-trip: unit fraction")
    func unitFractionRoundTrip() throws {
        let original = try #require(FractionalRate(numerator: 1, denominator: 1))
        let formatted = original.formatted(.fraction)
        let parsed = try FractionalRate(formatted, format: .fraction)
        #expect(parsed == original)
    }

    @Test("Round-trip: GCD-reduced input parses to reduced form")
    func gcdReducedRoundTrip() throws {
        let parsed = try FractionalRate("6/8", format: .fraction)
        let expected = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(parsed == expected)
    }

    // MARK: - Parse success cases

    @Test("Parses '3/4'")
    func parseThreeQuarters() throws {
        let rate = try FractionalRate.ParseStrategy().parse("3/4")
        let expected = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate == expected)
    }

    @Test("Parses '-1/10'")
    func parseNegative() throws {
        let rate = try FractionalRate.ParseStrategy().parse("-1/10")
        let expected = try #require(FractionalRate(numerator: -1, denominator: 10))
        #expect(rate == expected)
    }

    @Test("Parses with whitespace around components")
    func parseWithWhitespace() throws {
        let rate = try FractionalRate.ParseStrategy().parse(" 3 / 4 ")
        let expected = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate == expected)
    }

    // MARK: - Parse failure cases

    @Test("Parse '1/0' throws invalidFraction")
    func parseDivisionByZero() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidFraction) {
            try FractionalRate.ParseStrategy().parse("1/0")
        }
    }

    @Test("Parse '' throws invalidInput")
    func parseEmptyString() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("")
        }
    }

    @Test("Parse 'abc' throws invalidInput")
    func parseGarbage() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("abc")
        }
    }

    @Test("Parse '/5' throws invalidInput")
    func parseMissingNumerator() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("/5")
        }
    }

    @Test("Parse '5/' throws invalidInput")
    func parseMissingDenominator() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("5/")
        }
    }

    @Test("Parse '/' throws invalidInput")
    func parseSlashOnly() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("/")
        }
    }

    @Test("Parse '1/-5' throws invalidFraction (negative denominator)")
    func parseNegativeDenominator() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidFraction) {
            try FractionalRate.ParseStrategy().parse("1/-5")
        }
    }

    @Test("Parse with Int64.min numerator throws invalidFraction")
    func parseInt64MinNumerator() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidFraction) {
            try FractionalRate.ParseStrategy().parse("\(Int64.min)/1")
        }
    }

    // MARK: - Decimal parse round-trips

    @Test("Round-trip: format as decimal then parse back (0.75)")
    func decimalRoundTripThreeQuarters() throws {
        let original = try #require(FractionalRate(numerator: 3, denominator: 4))
        let formatted = original.formatted(.decimal.locale(Locale(identifier: "en_US")))
        let parsed = try FractionalRate.ParseStrategy().parse(formatted)
        #expect(parsed == original)
    }

    @Test("Round-trip: format as decimal then parse back (0.5)")
    func decimalRoundTripHalf() throws {
        let original = try #require(FractionalRate(numerator: 1, denominator: 2))
        let formatted = original.formatted(.decimal.locale(Locale(identifier: "en_US")))
        let parsed = try FractionalRate.ParseStrategy().parse(formatted)
        #expect(parsed == original)
    }

    @Test("Round-trip: format as decimal then parse back (0.11)")
    func decimalRoundTripElevenHundredths() throws {
        let original = try #require(FractionalRate(numerator: 11, denominator: 100))
        let formatted = original.formatted(.decimal.locale(Locale(identifier: "en_US")))
        let parsed = try FractionalRate.ParseStrategy().parse(formatted)
        #expect(parsed == original)
    }

    // MARK: - Decimal parse success cases

    @Test("Parses '0.75' as decimal")
    func parseDecimalThreeQuarters() throws {
        let rate = try FractionalRate.ParseStrategy().parse("0.75")
        let expected = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate == expected)
    }

    @Test("Parses '0.5' as decimal")
    func parseDecimalHalf() throws {
        let rate = try FractionalRate.ParseStrategy().parse("0.5")
        let expected = try #require(FractionalRate(numerator: 1, denominator: 2))
        #expect(rate == expected)
    }

    @Test("Parses '1' as decimal (integer)")
    func parseDecimalInteger() throws {
        let rate = try FractionalRate.ParseStrategy().parse("1")
        let expected = try #require(FractionalRate(numerator: 1, denominator: 1))
        #expect(rate == expected)
    }

    @Test("Parses '-0.25' as negative decimal")
    func parseNegativeDecimal() throws {
        let rate = try FractionalRate.ParseStrategy().parse("-0.25")
        let expected = try #require(FractionalRate(numerator: -1, denominator: 4))
        #expect(rate == expected)
    }

    // MARK: - Percentage parse round-trips

    @Test("Round-trip: format as percentage then parse back (75%)")
    func percentageRoundTripThreeQuarters() throws {
        let original = try #require(FractionalRate(numerator: 3, denominator: 4))
        let formatted = original.formatted(.percentage.locale(Locale(identifier: "en_US")))
        let parsed = try FractionalRate.ParseStrategy().parse(formatted)
        #expect(parsed == original)
    }

    @Test("Round-trip: format as percentage then parse back (50%)")
    func percentageRoundTripHalf() throws {
        let original = try #require(FractionalRate(numerator: 1, denominator: 2))
        let formatted = original.formatted(.percentage.locale(Locale(identifier: "en_US")))
        let parsed = try FractionalRate.ParseStrategy().parse(formatted)
        #expect(parsed == original)
    }

    @Test("Round-trip: format as percentage then parse back (1%)")
    func percentageRoundTripOnePercent() throws {
        let original = try #require(FractionalRate(numerator: 1, denominator: 100))
        let formatted = original.formatted(.percentage.locale(Locale(identifier: "en_US")))
        let parsed = try FractionalRate.ParseStrategy().parse(formatted)
        #expect(parsed == original)
    }

    // MARK: - Percentage parse success cases

    @Test("Parses '75%' as percentage")
    func parsePercentageThreeQuarters() throws {
        let rate = try FractionalRate.ParseStrategy().parse("75%")
        let expected = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate == expected)
    }

    @Test("Parses '50%' as percentage")
    func parsePercentageHalf() throws {
        let rate = try FractionalRate.ParseStrategy().parse("50%")
        let expected = try #require(FractionalRate(numerator: 1, denominator: 2))
        #expect(rate == expected)
    }

    @Test("Parses '100%' as percentage")
    func parsePercentageFull() throws {
        let rate = try FractionalRate.ParseStrategy().parse("100%")
        let expected = try #require(FractionalRate(numerator: 1, denominator: 1))
        #expect(rate == expected)
    }

    @Test("Parses '0%' as percentage")
    func parsePercentageZero() throws {
        let rate = try FractionalRate.ParseStrategy().parse("0%")
        let expected = try #require(FractionalRate(numerator: 0, denominator: 1))
        #expect(rate == expected)
    }

    @Test("Parses '-25%' as negative percentage")
    func parseNegativePercentage() throws {
        let rate = try FractionalRate.ParseStrategy().parse("-25%")
        let expected = try #require(FractionalRate(numerator: -1, denominator: 4))
        #expect(rate == expected)
    }

    // MARK: - Percentage parse failure cases

    @Test("Parse '%' alone throws invalidInput")
    func parsePercentSignOnly() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("%")
        }
    }

    // MARK: - Decimal percentage parsing

    @Test("Parses '75.2%' as decimal percentage")
    func parseDecimalPercentage() throws {
        let rate = try FractionalRate.ParseStrategy().parse("75.2%")
        let expected = try #require(FractionalRate(numerator: 94, denominator: 125))
        #expect(rate == expected)
    }

    @Test("Parses '33.33%' as decimal percentage")
    func parseDecimalPercentageThirtyThree() throws {
        let rate = try FractionalRate.ParseStrategy().parse("33.33%")
        let expected = try #require(FractionalRate(numerator: 3333, denominator: 10000))
        #expect(rate == expected)
    }

    @Test("Parses '0.5%' as half-percent")
    func parseHalfPercent() throws {
        let rate = try FractionalRate.ParseStrategy().parse("0.5%")
        let expected = try #require(FractionalRate(numerator: 1, denominator: 200))
        #expect(rate == expected)
    }

    // MARK: - Locale-aware percentage parsing

    private let enUS = Locale(identifier: "en_US")
    private let deDE = Locale(identifier: "de_DE")
    private let frFR = Locale(identifier: "fr_FR")

    @Test("Round-trip: German locale percentage (75\u{00A0}%)")
    func germanPercentageRoundTrip() throws {
        let original = try #require(FractionalRate(numerator: 3, denominator: 4))
        let style = FractionalRate.FormatStyle(.percentage, locale: deDE)
        let formatted = style.format(original)
        let parsed = try style.parseStrategy.parse(formatted)
        #expect(parsed == original)
    }

    @Test("Round-trip: French locale percentage (75\u{00A0}%)")
    func frenchPercentageRoundTrip() throws {
        let original = try #require(FractionalRate(numerator: 3, denominator: 4))
        let style = FractionalRate.FormatStyle(.percentage, locale: frFR)
        let formatted = style.format(original)
        let parsed = try style.parseStrategy.parse(formatted)
        #expect(parsed == original)
    }

    @Test("Round-trip: German locale decimal percentage (75,2\u{00A0}%)")
    func germanDecimalPercentageRoundTrip() throws {
        let original = try #require(FractionalRate(numerator: 94, denominator: 125))
        let style = FractionalRate.FormatStyle(.percentage, locale: deDE)
        let formatted = style.format(original)
        let parsed = try style.parseStrategy.parse(formatted)
        #expect(parsed == original)
    }

    @Test("Parses German-formatted '75,2 %' with German locale")
    func parseGermanDecimalPercentage() throws {
        let rate = try FractionalRate.ParseStrategy(locale: deDE).parse("75,2\u{00A0}%")
        let expected = try #require(FractionalRate(numerator: 94, denominator: 125))
        #expect(rate == expected)
    }

    @Test("Round-trip: German locale decimal (0,75)")
    func germanDecimalRoundTrip() throws {
        let original = try #require(FractionalRate(numerator: 3, denominator: 4))
        let style = FractionalRate.FormatStyle(.decimal, locale: deDE)
        let formatted = style.format(original)
        let parsed = try style.parseStrategy.parse(formatted)
        #expect(parsed == original)
    }

    @Test("Parses German-formatted '0,75' with German locale")
    func parseGermanDecimal() throws {
        let rate = try FractionalRate.ParseStrategy(locale: deDE).parse("0,75")
        let expected = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate == expected)
    }

    // MARK: - Fraction: non-numeric components

    @Test("Parse 'abc/4' throws invalidInput (non-numeric numerator)")
    func parseNonNumericNumerator() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("abc/4")
        }
    }

    @Test("Parse '3/xyz' throws invalidInput (non-numeric denominator)")
    func parseNonNumericDenominator() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("3/xyz")
        }
    }

    // MARK: - Decimal: FractionalRate overflow

    @Test("Parse decimal with significand exceeding Int64 throws invalidInput")
    func parseDecimalOverflow() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("99999999999999999999")
        }
    }

    // MARK: - Percentage: non-numeric body

    @Test("Parse 'abc%' throws invalidInput (non-numeric percentage)")
    func parseNonNumericPercentage() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("abc%")
        }
    }

    // MARK: - Percentage: FractionalRate overflow

    @Test("Parse percentage with significand exceeding Int64 throws invalidInput")
    func parsePercentageOverflow() {
        #expect(throws: FractionalRate.ParseStrategy.ParseError.invalidInput) {
            try FractionalRate.ParseStrategy().parse("99999999999999999999%")
        }
    }
}
