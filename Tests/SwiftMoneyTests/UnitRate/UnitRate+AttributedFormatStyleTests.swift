import Testing
import SwiftMoney

#if canImport(Foundation)
import Foundation

@Suite("UnitRate - AttributedFormatStyle")
struct UnitRateAttributedFormatStyleTests {

    private let enGB = Locale(identifier: "en_GB")
    private let enUS = Locale(identifier: "en_US")
    private let deDE = Locale(identifier: "de_DE")

    // MARK: - String unit attributed output

    @Test("attributed: produces .value and .unit runs")
    func attributedProducesRuns() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let style = UnitRate<GBP, String>.FormatStyle(locale: enGB)
        let attributed = unitRate.formatted(style.attributed)

        let runs = Array(attributed.runs[\.unitRateComponent])
        #expect(runs.count == 2)
        #expect(runs[0].0 == .value)
        #expect(runs[1].0 == .unit)

        #expect(String(attributed[runs[0].1].characters) == "£0.000023")
        #expect(String(attributed[runs[1].1].characters) == "/kWh")
    }

    @Test("attributed: unit run includes separator for string units")
    func attributedSeparatorIncludedInUnit() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<USD, String>(rate, per: "gallon")
        let style = UnitRate<USD, String>.FormatStyle(locale: enUS)
        let attributed = unitRate.formatted(style.attributed)

        let runs = Array(attributed.runs[\.unitRateComponent])
        let unitText = String(attributed[runs[1].1].characters)
        #expect(unitText.hasPrefix("/"))
        #expect(unitText == "/gallon")
    }

    @Test("attributed: full text matches plain formatted output")
    func attributedMatchesPlain() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let style = UnitRate<GBP, String>.FormatStyle(locale: enGB)

        let plain = unitRate.formatted(style)
        let attributed = unitRate.formatted(style.attributed)
        #expect(String(attributed.characters) == plain)
    }

    // MARK: - Dimension unit attributed output

    @Test("attributed Dimension: produces .value and .unit runs")
    func dimensionAttributedRuns() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let style = UnitRate<GBP, UnitEnergy>.FormatStyle(locale: enGB)
        let attributed = unitRate.formatted(style.attributed)

        let runs = Array(attributed.runs[\.unitRateComponent])
        #expect(runs.count == 2)
        #expect(runs[0].0 == .value)
        #expect(runs[1].0 == .unit)
    }

    @Test("attributed Dimension: unit run includes Foundation spacing")
    func dimensionAttributedSpacing() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<GBP, UnitLength>(rate, per: .kilometers)
        let style = UnitRate<GBP, UnitLength>.FormatStyle(locale: enGB)
        let attributed = unitRate.formatted(style.attributed)

        let runs = Array(attributed.runs[\.unitRateComponent])
        let unitText = String(attributed[runs[1].1].characters)
        // Foundation provides a space before the abbreviated unit
        #expect(unitText.hasPrefix(" "))
    }

    @Test("attributed Dimension: full text matches plain formatted output")
    func dimensionAttributedMatchesPlain() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let style = UnitRate<GBP, UnitEnergy>.FormatStyle(locale: enGB)

        let plain = unitRate.formatted(style)
        let attributed = unitRate.formatted(style.attributed)
        #expect(String(attributed.characters) == plain)
    }

    @Test("attributed Dimension: wide unit width shows full unit name")
    func dimensionAttributedWideWidth() throws {
        let rate = try #require(Rate(numerator: 3, denominator: 1))
        let unitRate = UnitRate<USD, UnitMass>(rate, per: .kilograms)
        let style = UnitRate<USD, UnitMass>.FormatStyle(locale: enUS, unitWidth: .wide)
        let attributed = unitRate.formatted(style.attributed)

        let runs = Array(attributed.runs[\.unitRateComponent])
        let unitText = String(attributed[runs[1].1].characters)
        #expect(unitText.contains("kilogram"))
    }

    @Test("attributed Dimension: German locale localises unit name")
    func dimensionAttributedGermanLocale() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, UnitEnergy>(rate, per: .kilowattHours)
        let style = UnitRate<GBP, UnitEnergy>.FormatStyle(locale: deDE, unitWidth: .wide)
        let attributed = unitRate.formatted(style.attributed)

        let runs = Array(attributed.runs[\.unitRateComponent])
        let unitText = String(attributed[runs[1].1].characters)
        #expect(unitText.contains("Kilowattstunde"))
    }

    @Test("attributed: all characters are covered by exactly one component")
    func attributedFullCoverage() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        let style = UnitRate<USD, String>.FormatStyle(locale: enUS)
        let attributed = unitRate.formatted(style.attributed)

        let fullText = String(attributed.characters)
        var covered = ""
        for run in attributed.runs {
            let component = run[UnitRateFormatAttribute.self]
            #expect(component != nil)
            covered += String(attributed[run.range].characters)
        }
        #expect(covered == fullText)
    }

    @Test("attributed Dimension: all characters are covered by exactly one component")
    func dimensionAttributedFullCoverage() throws {
        let rate = try #require(Rate(numerator: 3, denominator: 1))
        let unitRate = UnitRate<USD, UnitMass>(rate, per: .kilograms)
        let style = UnitRate<USD, UnitMass>.FormatStyle(locale: enUS)
        let attributed = unitRate.formatted(style.attributed)

        let fullText = String(attributed.characters)
        var covered = ""
        for run in attributed.runs {
            let component = run[UnitRateFormatAttribute.self]
            #expect(component != nil)
            covered += String(attributed[run.range].characters)
        }
        #expect(covered == fullText)
    }

    // MARK: - Attribute scope

    @Test("runs accessible via unitRateComponent key path")
    func attributeScopeKeyPath() throws {
        let rate = try #require(Rate(numerator: 5, denominator: 1))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        let style = UnitRate<USD, String>.FormatStyle(locale: enUS)
        let attributed = unitRate.formatted(style.attributed)

        // Access via key path (exercises AttributeDynamicLookup subscript)
        let runs = Array(attributed.runs[\.unitRateComponent])
        #expect(runs.count == 2)
    }
}

#endif
