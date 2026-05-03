import Testing
import SwiftMoney

#if canImport(Foundation)
import Foundation

@Suite("UnitRate - FormatStyle")
struct UnitRateFormatStyleTests {

    private let enGB = Locale(identifier: "en_GB")
    private let enUS = Locale(identifier: "en_US")
    private let deDE = Locale(identifier: "de_DE")
    private let frFR = Locale(identifier: "fr_FR")

    // MARK: - Currency formatting (String units)

    @Test("GBP small rate")
    func gbpSmallRate() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let result = unitRate.formatted(.init(locale: enGB))
        #expect(result == "£0.000023/kWh")
    }

    @Test("USD large rate")
    func usdLargeRate() throws {
        let rate = try #require(Rate(numerator: 14500, denominator: 200))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        let result = unitRate.formatted(.init(locale: enUS))
        #expect(result == "$72.50/barrel")
    }

    @Test("JPY (no decimal places)")
    func jpyNoDecimals() throws {
        let rate = try #require(Rate(numerator: 150, denominator: 1))
        let unitRate = UnitRate<JPY, String>(rate, per: "litre")
        let result = unitRate.formatted(.init(locale: Locale(identifier: "ja_JP")))
        #expect(result == "¥150/litre")
    }

    @Test("negative rate")
    func negativeRate() throws {
        let rate = try #require(Rate(numerator: -5, denominator: 100))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let result = unitRate.formatted(.init(locale: enGB))
        #expect(result == "-£0.05/kWh")
    }

    @Test("zero rate")
    func zeroRate() throws {
        let unitRate = UnitRate<GBP, String>(.zero, per: "kWh")
        let result = unitRate.formatted(.init(locale: enGB))
        #expect(result == "£0.00/kWh")
    }

    @Test("German locale")
    func germanLocale() throws {
        let rate = try #require(Rate(numerator: 14500, denominator: 200))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        let result = unitRate.formatted(.init(locale: deDE))
        #expect(result.contains("72,50"))
        #expect(result.hasSuffix("/barrel"))
    }

    @Test("whole pounds denominator 1")
    func wholePounds() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<GBP, String>(rate, per: "hr")
        let result = unitRate.formatted(.init(locale: enGB))
        #expect(result == "£5.00/hr")
    }

    @Test("multi-word unit")
    func multiWordUnit() throws {
        let rate = try #require(Rate(numerator: 50, denominator: 1))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel of oil")
        let result = unitRate.formatted(.init(locale: enUS))
        #expect(result == "$50.00/barrel of oil")
    }

    // MARK: - Modifiers

    @Test("locale modifier changes currency formatting")
    func localeModifier() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 2))
        let unitRate = UnitRate<GBP, String>(rate, per: "hr")
        let style = UnitRate<GBP, String>.FormatStyle(locale: enGB)
        let result = unitRate.formatted(style)
        #expect(result == "£0.50/hr")
    }

    @Test("locale modifier via chaining")
    func localeModifierChain() throws {
        let rate = try #require(Rate(numerator: 14500, denominator: 200))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        let style = UnitRate<USD, String>.FormatStyle().locale(deDE)
        let result = unitRate.formatted(style)
        #expect(result.contains("72,50"))
    }

    #if canImport(Darwin)
    @Test("unitWidth modifier via chaining")
    func unitWidthModifierChain() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let style = UnitRate<GBP, UnitEnergy>.FormatStyle().locale(enGB).unitWidth(.wide)
        let result = unitRate.formatted(style)
        #expect(result.contains("kilowatt"))
    }
    #endif

    // MARK: - formatted() convenience

    @Test("formatted() uses default style with autoupdatingCurrent locale")
    func formattedDefault() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<GBP, String>(rate, per: "hr")
        let result = unitRate.formatted()
        // Currency symbol should be present regardless of locale
        #expect(result.hasSuffix("/hr"))
    }

    // MARK: - Edge cases

    @Test("empty string unit")
    func emptyUnit() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<GBP, String>(rate, per: "")
        let result = unitRate.formatted(.init(locale: enGB))
        #expect(result == "£1.00/")
    }

    @Test("unit containing separator character")
    func unitContainingSeparator() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<GBP, String>(rate, per: "kg/m³")
        let result = unitRate.formatted(.init(locale: enGB))
        #expect(result == "£1.00/kg/m³")
    }

    @Test("very small rate shows sufficient decimals")
    func verySmallRate() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 10_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let result = unitRate.formatted(.init(locale: enGB))
        #expect(result == "£0.0000001/kWh")
    }
}

// MARK: - Dimension-specific formatting

#if canImport(Darwin)
@Suite("UnitRate - FormatStyle (Dimension)")
struct UnitRateFormatStyleDimensionTests {

    private let enUS = Locale(identifier: "en_US")
    private let deDE = Locale(identifier: "de_DE")
    private let frFR = Locale(identifier: "fr_FR")
    private let enGB = Locale(identifier: "en_GB")

    // MARK: - Basic Dimension formatting

    @Test("UnitEnergy abbreviated (en_GB)")
    func energyAbbreviated() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.init(locale: enGB))
        #expect(result == "£0.000023 kWh")
    }

    @Test("UnitEnergy wide (en_US)")
    func energyWide() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.init(locale: enUS, unitWidth: .wide))
        #expect(result.contains("kilowatt"))
        #expect(result.contains("£"))
    }

    @Test("USD with UnitMass abbreviated (en_US)")
    func massAbbreviatedUSD() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<USD, UnitMass>(rate, per: .kilograms)
        let result = unitRate.formatted(.init(locale: enUS))
        #expect(result == "$5.00 kg")
    }

    @Test("UnitMass wide (en_US)")
    func massWide() throws {
        let rate = try #require(Rate(numerator: 3, denominator: 1))
        let unitRate = UnitRate<USD, UnitMass>(rate, per: .kilograms)
        let result = unitRate.formatted(.init(locale: enUS, unitWidth: .wide))
        #expect(result.contains("kilogram"))
        #expect(result.contains("$"))
    }

    // MARK: - Localisation

    @Test("Dimension unit localised to German (abbreviated)")
    func dimensionGermanAbbreviated() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<EUR, UnitLength>(rate, per: .kilometers)
        let result = unitRate.formatted(.init(locale: deDE))
        #expect(result.contains("km"))
        #expect(result.contains("€"))
    }

    @Test("Dimension unit localised to German (wide)")
    func dimensionGermanWide() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<EUR, UnitLength>(rate, per: .kilometers)
        let result = unitRate.formatted(.init(locale: deDE, unitWidth: .wide))
        #expect(result.contains("Kilometer"))
    }

    @Test("Dimension unit localised to French (wide)")
    func dimensionFrenchWide() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<EUR, UnitLength>(rate, per: .kilometers)
        let result = unitRate.formatted(.init(locale: frFR, unitWidth: .wide))
        #expect(result.contains("kilomètre"))
    }

    // MARK: - formatted() default

    @Test("Dimension formatted() uses abbreviated by default")
    func dimensionFormattedDefault() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted()
        #expect(result.contains("kWh"))
    }

    // MARK: - Narrow unit width

    @Test("Dimension unit with narrow width")
    func dimensionNarrowWidth() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<EUR, UnitLength>(rate, per: .kilometers)
        let result = unitRate.formatted(.init(locale: enUS, unitWidth: .narrow))
        #expect(result.contains("km"))
    }

    // MARK: - Very small rates

    @Test("very small rate shows sufficient decimals")
    func verySmallRate() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 10_000_000))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.init(locale: enGB))
        #expect(result == "£0.0000001 kWh")
    }

    // MARK: - Unit width modifier

    @Test("unitWidth modifier changes label form")
    func unitWidthModifier() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let abbreviated = unitRate.formatted(.init(locale: enGB, unitWidth: .abbreviated))
        let wide = unitRate.formatted(.init(locale: enGB, unitWidth: .wide))
        #expect(abbreviated.contains("kWh"))
        #expect(wide.contains("kilowatt"))
        #expect(abbreviated != wide)
    }
}
#endif

#endif
