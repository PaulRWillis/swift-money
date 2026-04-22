import Foundation
import SwiftMoney
import Testing

@Suite("Money - ParseStrategy")
struct Money_ParseStrategyTests {

    private let enGB = Locale(identifier: "en_GB")
    private let enUS = Locale(identifier: "en_US")

    // MARK: - API surface

    @Test("FormatStyle.parseStrategy returns a ParseStrategy")
    func parseStrategyProperty() {
        let style = Money<GBP>.FormatStyle(locale: enGB)
        let strategy = style.parseStrategy
        // Sanity: strategy is the ParseStrategy type (confirmed by parse call below)
        #expect(type(of: strategy) == Money<GBP>.ParseStrategy.self)
    }

    @Test("Money<C>.init(_:format:) parses correctly")
    func convenienceInit() throws {
        let style = Money<GBP>.FormatStyle(locale: enGB)
        let money = try Money<GBP>("£12.34", format: style)
        #expect(money.minorUnits == 1234)
    }

    // MARK: - Round-trip: GBP (minQ = 100)

    @Test("GBP round-trip: positive amount")
    func gbpRoundTripPositive() throws {
        let original = Money<GBP>(minorUnits: 12_345)           // £123.45
        let style    = Money<GBP>.FormatStyle(locale: enGB)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    @Test("GBP round-trip: negative amount")
    func gbpRoundTripNegative() throws {
        let original = Money<GBP>(minorUnits: -9_876)           // -£98.76
        let style    = Money<GBP>.FormatStyle(locale: enGB)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    @Test("GBP round-trip: zero")
    func gbpRoundTripZero() throws {
        let original = Money<GBP>.zero
        let style    = Money<GBP>.FormatStyle(locale: enGB)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    @Test("GBP round-trip: single minor unit (£0.01)")
    func gbpRoundTripOneMinorUnit() throws {
        let original = Money<GBP>(minorUnits: 1)
        let style    = Money<GBP>.FormatStyle(locale: enGB)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    // MARK: - Round-trip: JPY (minQ = 1)

    @Test("JPY round-trip: positive amount")
    func jpyRoundTripPositive() throws {
        let original = Money<JPY>(minorUnits: 12_345)
        let style    = Money<JPY>.FormatStyle(locale: enGB)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    @Test("JPY round-trip: negative amount")
    func jpyRoundTripNegative() throws {
        let original = Money<JPY>(minorUnits: -9_999)
        let style    = Money<JPY>.FormatStyle(locale: enGB)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    // MARK: - Round-trip: KWD (minQ = 1000)

    @Test("KWD round-trip: positive amount (3-decimal currency)")
    func kwdRoundTripPositive() throws {
        let original = Money<TestKWD>(minorUnits: 1_234_567)    // KWD 1,234.567
        let style    = Money<TestKWD>.FormatStyle(locale: enGB)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    @Test("KWD round-trip: single minor unit (KWD 0.001)")
    func kwdRoundTripOneMinorUnit() throws {
        let original = Money<TestKWD>(minorUnits: 1)
        let style    = Money<TestKWD>.FormatStyle(locale: enGB)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    // MARK: - Round-trip: modifiers

    @Test("Round-trip with .presentation(.isoCode)")
    func roundTripISOCode() throws {
        let original = Money<USD>(minorUnits: 4_200)
        let style    = Money<USD>.FormatStyle(locale: enUS).presentation(.isoCode)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    @Test("Round-trip with .presentation(.fullName)")
    func roundTripFullName() throws {
        let original = Money<USD>(minorUnits: 4_200)
        let style    = Money<USD>.FormatStyle(locale: enUS).presentation(.fullName)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    @Test("Round-trip with .sign(strategy: .always())")
    func roundTripSignAlways() throws {
        let original = Money<GBP>(minorUnits: 5_000)
        let style    = Money<GBP>.FormatStyle(locale: enGB).sign(strategy: .always())
        let string   = style.format(original)                   // "+£50.00"
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    @Test("Round-trip with .sign(strategy: .accounting) on negative value")
    func roundTripSignAccounting() throws {
        let original = Money<GBP>(minorUnits: -5_000)
        let style    = Money<GBP>.FormatStyle(locale: enGB).sign(strategy: .accounting)
        let string   = style.format(original)                   // "(£50.00)"
        let parsed   = try style.parseStrategy.parse(string)
        #expect(parsed == original)
    }

    // MARK: - Round-trip across locales

    @Test(
        "GBP format→parse round-trips correctly across locales",
        arguments: localizationTestLocales
    )
    func gbpRoundTripAcrossLocales(locale: Locale) throws {
        let original = Money<GBP>(minorUnits: 12_345)
        let style    = Money<GBP>.FormatStyle(locale: locale)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(
            parsed == original,
            "Locale \(locale.identifier): '\(string)' did not round-trip (got \(parsed.minorUnits), want \(original.minorUnits))"
        )
    }

    @Test(
        "JPY format→parse round-trips correctly across locales",
        arguments: localizationTestLocales
    )
    func jpyRoundTripAcrossLocales(locale: Locale) throws {
        let original = Money<JPY>(minorUnits: 12_345)
        let style    = Money<JPY>.FormatStyle(locale: locale)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(
            parsed == original,
            "Locale \(locale.identifier): '\(string)' did not round-trip (got \(parsed.minorUnits), want \(original.minorUnits))"
        )
    }

    @Test(
        "KWD format→parse round-trips correctly across locales (3-decimal currency)",
        arguments: localizationTestLocales
    )
    func kwdRoundTripAcrossLocales(locale: Locale) throws {
        let original = Money<TestKWD>(minorUnits: 1_234_567)
        let style    = Money<TestKWD>.FormatStyle(locale: locale)
        let string   = style.format(original)
        let parsed   = try style.parseStrategy.parse(string)
        #expect(
            parsed == original,
            "Locale \(locale.identifier): '\(string)' did not round-trip (got \(parsed.minorUnits), want \(original.minorUnits))"
        )
    }

    // MARK: - Failure cases

    @Test("parse throws on a non-currency string")
    func parseThrowsOnGarbage() {
        let style = Money<GBP>.FormatStyle(locale: enGB)
        #expect(throws: (any Error).self) {
            try style.parseStrategy.parse("not a number")
        }
    }

    @Test("parse throws on an empty string")
    func parseThrowsOnEmpty() {
        let style = Money<GBP>.FormatStyle(locale: enGB)
        #expect(throws: (any Error).self) {
            try style.parseStrategy.parse("")
        }
    }

    // MARK: - ParseStrategy is Codable, Hashable, Equatable

    @Test("ParseStrategy is Equatable — same format style produces equal strategies")
    func parseStrategyEquality() {
        let styleA = Money<GBP>.FormatStyle(locale: enGB)
        let styleB = Money<GBP>.FormatStyle(locale: enGB)
        #expect(styleA.parseStrategy == styleB.parseStrategy)
    }

    @Test("ParseStrategy is Equatable — different locales produce different strategies")
    func parseStrategyInequality() {
        let strategyGB = Money<GBP>.FormatStyle(locale: enGB).parseStrategy
        let strategyUS = Money<GBP>.FormatStyle(locale: enUS).parseStrategy
        #expect(strategyGB != strategyUS)
    }

    @Test("ParseStrategy is Hashable — equal strategies have equal hashes")
    func parseStrategyHashable() {
        let styleA = Money<GBP>.FormatStyle(locale: enGB)
        let styleB = Money<GBP>.FormatStyle(locale: enGB)
        #expect(styleA.parseStrategy.hashValue == styleB.parseStrategy.hashValue)
    }

    @Test("ParseStrategy is Codable — encodes and decodes to the same strategy")
    func parseStrategyCodable() throws {
        let strategy = Money<GBP>.FormatStyle(locale: enGB).parseStrategy
        let data     = try JSONEncoder().encode(strategy)
        let decoded  = try JSONDecoder().decode(Money<GBP>.ParseStrategy.self, from: data)
        #expect(strategy == decoded)
    }
}
