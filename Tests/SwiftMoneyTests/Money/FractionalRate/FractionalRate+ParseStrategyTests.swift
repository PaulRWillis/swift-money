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
        let formatted = original.formatted(.decimal(locale: Locale(identifier: "en_US")))
        let parsed = try FractionalRate.ParseStrategy().parse(formatted)
        #expect(parsed == original)
    }

    @Test("Round-trip: format as decimal then parse back (0.5)")
    func decimalRoundTripHalf() throws {
        let original = try #require(FractionalRate(numerator: 1, denominator: 2))
        let formatted = original.formatted(.decimal(locale: Locale(identifier: "en_US")))
        let parsed = try FractionalRate.ParseStrategy().parse(formatted)
        #expect(parsed == original)
    }

    @Test("Round-trip: format as decimal then parse back (0.11)")
    func decimalRoundTripElevenHundredths() throws {
        let original = try #require(FractionalRate(numerator: 11, denominator: 100))
        let formatted = original.formatted(.decimal(locale: Locale(identifier: "en_US")))
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
}
