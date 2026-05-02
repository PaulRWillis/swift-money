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

    // MARK: - .rate mode

    @Test("rate mode: positive rate with string unit")
    func rateModePositive() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.formatted(.rate) == "23/1000000/kWh")
    }

    @Test("rate mode: GCD-reduced rate shows reduced form")
    func rateModeGCDReduced() throws {
        let rate = try #require(Rate(numerator: 14500, denominator: 200))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        #expect(unitRate.formatted(.rate) == "145/2/barrel")
    }

    @Test("rate mode: negative rate")
    func rateModeNegative() throws {
        let rate = try #require(Rate(numerator: -5, denominator: 100))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.formatted(.rate) == "-1/20/kWh")
    }

    @Test("rate mode: zero rate")
    func rateModeZero() throws {
        let unitRate = UnitRate<GBP, String>(.zero, per: "kWh")
        #expect(unitRate.formatted(.rate) == "0/1/kWh")
    }

    @Test("rate mode: custom separator")
    func rateModeCustomSeparator() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.formatted(.rate.separator(" / ")) == "23/1000000 / kWh")
    }

    @Test("rate mode: multi-word unit")
    func rateModeMultiWord() throws {
        let rate = try #require(Rate(numerator: 50, denominator: 1))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel of oil")
        #expect(unitRate.formatted(.rate) == "50/1/barrel of oil")
    }

    // MARK: - .number mode

    @Test("number mode: small rate en_US")
    func numberModeSmall() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let result = unitRate.formatted(.number.locale(enUS))
        #expect(result == "0.000023/kWh")
    }

    @Test("number mode: German locale uses comma")
    func numberModeGerman() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let result = unitRate.formatted(.number.locale(deDE))
        #expect(result == "0,000023/kWh")
    }

    @Test("number mode: integer rate (denominator 1)")
    func numberModeInteger() throws {
        let rate = try #require(Rate(numerator: 72, denominator: 1))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        let result = unitRate.formatted(.number.locale(enUS))
        #expect(result == "72/barrel")
    }

    @Test("number mode: negative rate")
    func numberModeNegative() throws {
        let rate = try #require(Rate(numerator: -5, denominator: 100))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let result = unitRate.formatted(.number.locale(enUS))
        #expect(result == "-0.05/kWh")
    }

    @Test("number mode: zero rate")
    func numberModeZero() throws {
        let unitRate = UnitRate<GBP, String>(.zero, per: "kWh")
        let result = unitRate.formatted(.number.locale(enUS))
        #expect(result == "0/kWh")
    }

    @Test("number mode: large rate")
    func numberModeLarge() throws {
        let rate = try #require(Rate(numerator: 14500, denominator: 200))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        let result = unitRate.formatted(.number.locale(enUS))
        #expect(result == "72.5/barrel")
    }

    @Test("number mode: custom separator")
    func numberModeCustomSeparator() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let result = unitRate.formatted(.number.locale(enUS).separator(" per "))
        #expect(result == "0.000023 per kWh")
    }

    // MARK: - .price mode

    @Test("price mode: GBP small rate")
    func priceModeGBP() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let result = unitRate.formatted(.price.locale(enGB))
        #expect(result == "£0.000023/kWh")
    }

    @Test("price mode: USD large rate")
    func priceModeUSD() throws {
        let rate = try #require(Rate(numerator: 14500, denominator: 200))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        let result = unitRate.formatted(.price.locale(enUS))
        #expect(result == "$72.50/barrel")
    }

    @Test("price mode: JPY (no decimal places)")
    func priceModeJPY() throws {
        let rate = try #require(Rate(numerator: 150, denominator: 1))
        let unitRate = UnitRate<JPY, String>(rate, per: "litre")
        let result = unitRate.formatted(.price.locale(Locale(identifier: "ja_JP")))
        #expect(result == "¥150/litre")
    }

    @Test("price mode: negative rate")
    func priceModeNegative() throws {
        let rate = try #require(Rate(numerator: -5, denominator: 100))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let result = unitRate.formatted(.price.locale(enGB))
        #expect(result == "-£0.05/kWh")
    }

    @Test("price mode: zero rate")
    func priceModeZero() throws {
        let unitRate = UnitRate<GBP, String>(.zero, per: "kWh")
        let result = unitRate.formatted(.price.locale(enGB))
        #expect(result == "£0.00/kWh")
    }

    @Test("price mode: German locale")
    func priceModeGerman() throws {
        let rate = try #require(Rate(numerator: 14500, denominator: 200))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        let result = unitRate.formatted(.price.locale(deDE))
        #expect(result.contains("72,50"))
        #expect(result.hasSuffix("/barrel"))
    }

    @Test("price mode: custom separator")
    func priceModeCustomSeparator() throws {
        let rate = try #require(Rate(numerator: 14500, denominator: 200))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        let result = unitRate.formatted(.price.locale(enUS).separator(" per "))
        #expect(result == "$72.50 per barrel")
    }

    // MARK: - Modifiers

    @Test("locale modifier changes decimal formatting")
    func localeModifier() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 2))
        let unitRate = UnitRate<GBP, String>(rate, per: "hr")
        let en = unitRate.formatted(.number.locale(enUS))
        let de = unitRate.formatted(.number.locale(deDE))
        #expect(en == "0.5/hr")
        #expect(de == "0,5/hr")
    }

    @Test("separator modifier changes the delimiter")
    func separatorModifier() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<GBP, String>(rate, per: "hr")
        #expect(unitRate.formatted(.rate.separator(" per ")) == "1/1 per hr")
    }

    // MARK: - Static factories

    @Test("static .rate factory produces rate mode")
    func staticRate() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 2))
        let unitRate = UnitRate<GBP, String>(rate, per: "hr")
        let fromFactory = unitRate.formatted(.rate)
        let fromInit = unitRate.formatted(UnitRate<GBP, String>.FormatStyle(.rate))
        #expect(fromFactory == fromInit)
    }

    @Test("static .number factory produces number mode")
    func staticNumber() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 2))
        let unitRate = UnitRate<GBP, String>(rate, per: "hr")
        let fromFactory = unitRate.formatted(.number.locale(enUS))
        let fromInit = unitRate.formatted(UnitRate<GBP, String>.FormatStyle(.number, locale: enUS))
        #expect(fromFactory == fromInit)
    }

    @Test("static .price factory produces price mode")
    func staticPrice() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 2))
        let unitRate = UnitRate<GBP, String>(rate, per: "hr")
        let fromFactory = unitRate.formatted(.price.locale(enGB))
        let fromInit = unitRate.formatted(UnitRate<GBP, String>.FormatStyle(.price, locale: enGB))
        #expect(fromFactory == fromInit)
    }

    // MARK: - formatted() convenience

    @Test("formatted() uses default .rate style")
    func formattedDefault() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.formatted() == unitRate.formatted(.rate))
    }

    // MARK: - Edge cases

    @Test("empty string unit")
    func emptyUnit() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<GBP, String>(rate, per: "")
        #expect(unitRate.formatted(.rate) == "1/1/")
    }

    @Test("unit containing separator character")
    func unitContainingSeparator() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<GBP, String>(rate, per: "kg/m³")
        #expect(unitRate.formatted(.rate) == "1/1/kg/m³")
    }

    @Test("denominator 1 rate in price mode")
    func priceModeWholePounds() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<GBP, String>(rate, per: "hr")
        let result = unitRate.formatted(.price.locale(enGB))
        #expect(result == "£5.00/hr")
    }
}

// MARK: - Dimension-specific formatting

@Suite("UnitRate - FormatStyle (Dimension)")
struct UnitRateFormatStyleDimensionTests {

    private let enUS = Locale(identifier: "en_US")
    private let deDE = Locale(identifier: "de_DE")
    private let frFR = Locale(identifier: "fr_FR")
    private let enGB = Locale(identifier: "en_GB")

    // MARK: - Basic Dimension formatting

    @Test("number mode with UnitEnergy abbreviated (en_US)")
    func numberModeEnergyAbbreviated() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.number.locale(enUS).unitWidth(.abbreviated))
        #expect(result == "0.000023/kWh")
    }

    @Test("number mode with UnitEnergy wide (en_US)")
    func numberModeEnergyWide() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.number.locale(enUS).unitWidth(.wide))
        #expect(result.contains("kilowatt"))
    }

    @Test("price mode with UnitEnergy (en_GB)")
    func priceModeEnergy() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.price.locale(enGB))
        #expect(result == "£0.000023/kWh")
    }

    @Test("rate mode with Dimension uses localised label")
    func rateModeEnergy() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<USD, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.rate.locale(enUS))
        #expect(result == "5/1/kWh")
    }

    // MARK: - Localisation

    @Test("Dimension unit localised to German (abbreviated)")
    func dimensionGermanAbbreviated() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<EUR, UnitLength>(rate, per: .kilometers)
        let result = unitRate.formatted(.number.locale(deDE).unitWidth(.abbreviated))
        #expect(result == "1/km")
    }

    @Test("Dimension unit localised to German (wide)")
    func dimensionGermanWide() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<EUR, UnitLength>(rate, per: .kilometers)
        let result = unitRate.formatted(.number.locale(deDE).unitWidth(.wide))
        #expect(result.contains("Kilometer"))
    }

    @Test("Dimension unit localised to French (wide)")
    func dimensionFrenchWide() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<EUR, UnitLength>(rate, per: .kilometers)
        let result = unitRate.formatted(.number.locale(frFR).unitWidth(.wide))
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

    // MARK: - Custom separator with Dimension

    @Test("custom separator with Dimension unit")
    func customSeparatorDimension() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.number.locale(enGB).separator(" per "))
        #expect(result == "5 per kWh")
    }

    // MARK: - Narrow unit width

    @Test("Dimension unit with narrow width")
    func dimensionNarrowWidth() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<EUR, UnitLength>(rate, per: .kilometers)
        let result = unitRate.formatted(.number.locale(enUS).unitWidth(.narrow))
        #expect(result.contains("km"))
    }

    // MARK: - Additional Dimension units

    @Test("UnitMass abbreviation (en_US)")
    func dimensionMassAbbreviated() throws {
        let rate = try #require(Rate(numerator: 3, denominator: 1))
        let unitRate = UnitRate<USD, UnitMass>(rate, per: .kilograms)
        let result = unitRate.formatted(.number.locale(enUS).unitWidth(.abbreviated))
        #expect(result == "3/kg")
    }

    @Test("UnitMass wide (en_US)")
    func dimensionMassWide() throws {
        let rate = try #require(Rate(numerator: 3, denominator: 1))
        let unitRate = UnitRate<USD, UnitMass>(rate, per: .kilograms)
        let result = unitRate.formatted(.number.locale(enUS).unitWidth(.wide))
        #expect(result.contains("kilogram"))
    }

    // MARK: - French locale

    @Test("number mode with French locale uses comma")
    func dimensionFrenchNumber() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 2))
        let unitRate = UnitRate<EUR, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.number.locale(frFR))
        #expect(result.contains("0,5"))
    }

    // MARK: - Chained modifiers

    @Test("chained modifiers: locale + separator + unitWidth")
    func chainedModifiers() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<EUR, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.number.locale(deDE).separator(" pro ").unitWidth(.abbreviated))
        #expect(result == "5 pro kWh")
    }

    // MARK: - Price mode with Dimension

    @Test("price mode with UnitMass (USD)")
    func priceModeMass() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<USD, UnitMass>(rate, per: .kilograms)
        let result = unitRate.formatted(.price.locale(enUS))
        #expect(result == "$5.00/kg")
    }

    // MARK: - formatted(_:) with explicit init

    @Test("formatted(_:) with explicit FormatStyle init for Dimension")
    func formattedExplicitInit() throws {
        let rate = try #require(Rate(numerator: 10, denominator: 1))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let style = UnitRate<GBP, UnitEnergy>.FormatStyle(.number, locale: enGB)
        let result = unitRate.formatted(style)
        #expect(result == "10/kWh")
    }

    // MARK: - Very small rates

    @Test("price mode very small rate shows sufficient decimals")
    func priceVerySmallRate() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 10_000_000))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let result = unitRate.formatted(.price.locale(enGB))
        #expect(result == "£0.0000001/kWh")
    }
}

#endif
