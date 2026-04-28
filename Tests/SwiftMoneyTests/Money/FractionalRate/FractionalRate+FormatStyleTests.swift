import Foundation
import Testing
import SwiftMoney

@Suite("FractionalRate - FormatStyle")
struct FractionalRateFormatStyleTests {

    // MARK: - Fraction formatting

    @Test("Formats 3/4 as fraction")
    func formatThreeQuarters() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate.formatted(.fraction) == "3/4")
    }

    @Test("Formats -1/10 as fraction")
    func formatNegativeRate() throws {
        let rate = try #require(FractionalRate(numerator: -1, denominator: 10))
        #expect(rate.formatted(.fraction) == "-1/10")
    }

    @Test("Formats 0/1 as fraction")
    func formatZero() throws {
        let rate = try #require(FractionalRate(numerator: 0, denominator: 1))
        #expect(rate.formatted(.fraction) == "0/1")
    }

    @Test("Formats 1/1 as fraction")
    func formatUnit() throws {
        let rate = try #require(FractionalRate(numerator: 1, denominator: 1))
        #expect(rate.formatted(.fraction) == "1/1")
    }

    @Test("GCD-reduced: 2/4 formats as 1/2")
    func formatGCDReduced() throws {
        let rate = try #require(FractionalRate(numerator: 2, denominator: 4))
        #expect(rate.formatted(.fraction) == "1/2")
    }

    @Test("Formats 11/100 as fraction")
    func formatElevenHundredths() throws {
        let rate = try #require(FractionalRate(numerator: 11, denominator: 100))
        #expect(rate.formatted(.fraction) == "11/100")
    }

    @Test("Default formatted() uses fraction mode")
    func formattedDefaultIsFraction() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate.formatted() == "3/4")
    }

    @Test("FormatStyle() default mode is fraction")
    func defaultModeIsFraction() throws {
        let style = FractionalRate.FormatStyle()
        let rate = try #require(FractionalRate(numerator: 7, denominator: 8))
        #expect(style.format(rate) == "7/8")
    }

    // MARK: - Decimal formatting

    private let enUS = Locale(identifier: "en_US")
    private let deDE = Locale(identifier: "de_DE")

    @Test("Formats 1/2 as decimal")
    func formatHalfAsDecimal() throws {
        let rate = try #require(FractionalRate(numerator: 1, denominator: 2))
        #expect(rate.formatted(.decimal.locale(enUS)) == "0.5")
    }

    @Test("Formats 3/4 as decimal")
    func formatThreeQuartersDecimal() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate.formatted(.decimal.locale(enUS)) == "0.75")
    }

    @Test("Formats 1/1 as decimal")
    func formatUnitDecimal() throws {
        let rate = try #require(FractionalRate(numerator: 1, denominator: 1))
        #expect(rate.formatted(.decimal.locale(enUS)) == "1")
    }

    @Test("Formats 0/1 as decimal")
    func formatZeroDecimal() throws {
        let rate = try #require(FractionalRate(numerator: 0, denominator: 1))
        #expect(rate.formatted(.decimal.locale(enUS)) == "0")
    }

    @Test("Formats negative rate as decimal")
    func formatNegativeDecimal() throws {
        let rate = try #require(FractionalRate(numerator: -1, denominator: 4))
        #expect(rate.formatted(.decimal.locale(enUS)) == "-0.25")
    }

    @Test("Formats 11/100 as decimal")
    func formatElevenHundredthsDecimal() throws {
        let rate = try #require(FractionalRate(numerator: 11, denominator: 100))
        #expect(rate.formatted(.decimal.locale(enUS)) == "0.11")
    }

    @Test("Decimal mode respects locale (de_DE uses comma)")
    func decimalLocaleDE() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate.formatted(.decimal.locale(deDE)) == "0,75")
    }

    @Test("Decimal mode with integer rate")
    func decimalIntegerRate() throws {
        let rate = try #require(FractionalRate(numerator: 5, denominator: 1))
        #expect(rate.formatted(.decimal.locale(enUS)) == "5")
    }

    // MARK: - Percentage formatting

    @Test("Formats 3/4 as percentage")
    func formatThreeQuartersPercentage() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate.formatted(.percentage.locale(enUS)) == "75%")
    }

    @Test("Formats 1/100 as percentage")
    func formatOnePercent() throws {
        let rate = try #require(FractionalRate(numerator: 1, denominator: 100))
        #expect(rate.formatted(.percentage.locale(enUS)) == "1%")
    }

    @Test("Formats 1/2 as percentage")
    func formatHalfPercentage() throws {
        let rate = try #require(FractionalRate(numerator: 1, denominator: 2))
        #expect(rate.formatted(.percentage.locale(enUS)) == "50%")
    }

    @Test("Formats 0/1 as percentage")
    func formatZeroPercentage() throws {
        let rate = try #require(FractionalRate(numerator: 0, denominator: 1))
        #expect(rate.formatted(.percentage.locale(enUS)) == "0%")
    }

    @Test("Formats negative rate as percentage")
    func formatNegativePercentage() throws {
        let rate = try #require(FractionalRate(numerator: -1, denominator: 4))
        #expect(rate.formatted(.percentage.locale(enUS)) == "-25%")
    }

    @Test("Formats 1/1 as percentage")
    func formatUnitPercentage() throws {
        let rate = try #require(FractionalRate(numerator: 1, denominator: 1))
        #expect(rate.formatted(.percentage.locale(enUS)) == "100%")
    }

    @Test("Percentage mode respects locale (de_DE)")
    func percentageLocaleDE() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate.formatted(.percentage.locale(deDE)) == "75\u{00A0}%")
    }

    // MARK: - Static factories without locale

    @Test(".decimal static var uses autoupdatingCurrent locale")
    func decimalStaticVar() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        let result = rate.formatted(.decimal)
        #expect(!result.isEmpty)
    }

    @Test(".percentage static var uses autoupdatingCurrent locale")
    func percentageStaticVar() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        let result = rate.formatted(.percentage)
        #expect(!result.isEmpty)
    }

    // MARK: - Copy-on-modify modifiers

    @Test("mode(_:) modifier switches output representation")
    func modeModifier() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        let style = FractionalRate.FormatStyle(.fraction, locale: enUS).mode(.decimal)
        #expect(style.format(rate) == "0.75")
    }

    @Test("locale(_:) modifier changes locale")
    func localeModifier() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        let style = FractionalRate.FormatStyle(.decimal).locale(deDE)
        #expect(style.format(rate) == "0,75")
    }
}
