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

#endif
