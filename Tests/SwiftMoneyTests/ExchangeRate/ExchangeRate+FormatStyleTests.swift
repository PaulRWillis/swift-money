import Foundation
import Testing
import SwiftMoney

// MARK: - Rate mode

@Suite("ExchangeRate.FormatStyle – rate mode")
struct ExchangeRateFormatStyleRateTests {

    private let enUS = Locale(identifier: "en_US")
    private let deDE = Locale(identifier: "de_DE")

    // MARK: - Same minimalQuantisation (100:100)

    @Test("1.25 rate between same-minQ currencies")
    func sameMinQ_1_25() throws {
        let decimal = try #require(Decimal(string: "1.25"))
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: decimal))
        #expect(rate.formatted(.rate.locale(enUS)) == "1.25")
    }

    @Test("Identity rate 1:1")
    func sameMinQ_identity() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(from: 1, to: 1))
        #expect(rate.formatted(.rate.locale(enUS)) == "1")
    }

    @Test("Large rate between same-minQ currencies")
    func sameMinQ_large() throws {
        let decimal = try #require(Decimal(string: "1234.56"))
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: decimal))
        #expect(rate.formatted(.rate.locale(enUS)) == "1,234.56")
    }

    // MARK: - Different minimalQuantisation (100:1)

    @Test("215.16 rate from minQ 100 to minQ 1")
    func differentMinQ_100_to_1() throws {
        let decimal = try #require(Decimal(string: "215.16"))
        let rate = try #require(ExchangeRate<TST_100, TST_1>(majorUnitRate: decimal))
        #expect(rate.formatted(.rate.locale(enUS)) == "215.16")
    }

    @Test("0.004659 rate from minQ 1 to minQ 100")
    func differentMinQ_1_to_100() throws {
        let decimal = try #require(Decimal(string: "0.004659"))
        let rate = try #require(ExchangeRate<TST_1, TST_100>(majorUnitRate: decimal))
        #expect(rate.formatted(.rate.locale(enUS)) == "0.004659")
    }

    // MARK: - High-precision currency (100_000_000)

    @Test("Rate involving bitcoin-like currency")
    func highPrecision() throws {
        let decimal = try #require(Decimal(string: "0.000015"))
        let rate = try #require(ExchangeRate<TST_100, TST_100_000_000>(majorUnitRate: decimal))
        #expect(rate.formatted(.rate.locale(enUS)) == "0.000015")
    }

    // MARK: - Locale formatting

    @Test("German locale uses comma as decimal separator")
    func germanLocale() throws {
        let decimal = try #require(Decimal(string: "1.25"))
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: decimal))
        #expect(rate.formatted(.rate.locale(deDE)) == "1,25")
    }

    @Test("German locale groups thousands with period")
    func germanLocaleGrouping() throws {
        let decimal = try #require(Decimal(string: "1234.56"))
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: decimal))
        #expect(rate.formatted(.rate.locale(deDE)) == "1.234,56")
    }

    // MARK: - Coverage: static factories and conveniences

    @Test(".rate static var uses autoupdatingCurrent locale")
    func rateStaticVar() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(from: 4, to: 5))
        let result = rate.formatted(.rate)
        #expect(!result.isEmpty)
    }

    @Test("formatted() no-arg convenience uses default .rate style")
    func formattedNoArg() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(from: 4, to: 5))
        let result = rate.formatted()
        #expect(!result.isEmpty)
    }
}

// MARK: - Fraction mode

@Suite("ExchangeRate.FormatStyle – fraction mode")
struct ExchangeRateFormatStyleFractionTests {

    // MARK: - Same minimalQuantisation (100:100)

    @Test("Identity rate 1:1 as fraction")
    func sameMinQ_identity() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(from: 1, to: 1))
        #expect(rate.formatted(.fraction) == "1/1")
    }

    @Test("1.25 rate as fraction → 5/4")
    func sameMinQ_1_25() throws {
        let decimal = try #require(Decimal(string: "1.25"))
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: decimal))
        #expect(rate.formatted(.fraction) == "5/4")
    }

    @Test("0.5 rate as fraction → 1/2")
    func sameMinQ_half() throws {
        let decimal = try #require(Decimal(string: "0.5"))
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: decimal))
        #expect(rate.formatted(.fraction) == "1/2")
    }

    @Test("GCD reduction: 150/100 minor units → major 3/2")
    func sameMinQ_gcdReduction() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(from: 100, to: 150))
        #expect(rate.formatted(.fraction) == "3/2")
    }

    // MARK: - Different minimalQuantisation (100:1)

    @Test("215.16 rate from minQ 100 to minQ 1 as fraction")
    func differentMinQ_100_to_1() throws {
        let decimal = try #require(Decimal(string: "215.16"))
        let rate = try #require(ExchangeRate<TST_100, TST_1>(majorUnitRate: decimal))
        #expect(rate.formatted(.fraction) == "5379/25")
    }

    // MARK: - Different minimalQuantisation (1:100)

    @Test("Small rate from minQ 1 to minQ 100 as fraction")
    func differentMinQ_1_to_100() throws {
        let decimal = try #require(Decimal(string: "0.5"))
        let rate = try #require(ExchangeRate<TST_1, TST_100>(majorUnitRate: decimal))
        #expect(rate.formatted(.fraction) == "1/2")
    }

    // MARK: - High-precision currency (100:100_000_000)

    @Test("Rate involving bitcoin-like currency as fraction")
    func highPrecision() throws {
        let decimal = try #require(Decimal(string: "0.000015"))
        let rate = try #require(ExchangeRate<TST_100, TST_100_000_000>(majorUnitRate: decimal))
        #expect(rate.formatted(.fraction) == "3/200000")
    }

    // MARK: - Integer rate

    @Test("Integer rate 2:1 as fraction")
    func integerRate() throws {
        let decimal = try #require(Decimal(string: "2"))
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: decimal))
        #expect(rate.formatted(.fraction) == "2/1")
    }
}

// MARK: - Pair mode

@Suite("ExchangeRate.FormatStyle – pair mode")
struct ExchangeRateFormatStylePairTests {

    private let enGB = Locale(identifier: "en_GB")
    private let deDE = Locale(identifier: "de_DE")

    // MARK: - Default separator (equals)

    @Test("GBP→USD 1.25 as pair with en_GB locale")
    func gbpToUsd() throws {
        let decimal = try #require(Decimal(string: "1.25"))
        let rate = try #require(ExchangeRate<GBP, USD>(majorUnitRate: decimal))
        #expect(rate.formatted(.pair.locale(enGB)) == "£1.00 = US$1.25")
    }

    @Test("GBP→JPY 215 as pair with en_GB locale")
    func gbpToJpy() throws {
        let decimal = try #require(Decimal(string: "215"))
        let rate = try #require(ExchangeRate<GBP, JPY>(majorUnitRate: decimal))
        #expect(rate.formatted(.pair.locale(enGB)) == "£1.00 = JP¥215")
    }

    @Test("Identity GBP→GBP as pair")
    func identity() throws {
        let rate = try #require(ExchangeRate<GBP, GBP>(from: 1, to: 1))
        #expect(rate.formatted(.pair.locale(enGB)) == "£1.00 = £1.00")
    }

    @Test("EUR→GBP 0.85 as pair with en_GB locale")
    func eurToGbp() throws {
        let decimal = try #require(Decimal(string: "0.85"))
        let rate = try #require(ExchangeRate<EUR, GBP>(majorUnitRate: decimal))
        #expect(rate.formatted(.pair.locale(enGB)) == "€1.00 = £0.85")
    }

    // MARK: - Custom separators

    @Test("Colon separator: GBP→USD")
    func colonSeparator() throws {
        let decimal = try #require(Decimal(string: "1.25"))
        let rate = try #require(ExchangeRate<GBP, USD>(majorUnitRate: decimal))
        #expect(rate.formatted(.pair(separator: .colon).locale(enGB)) == "£1.00 : US$1.25")
    }

    @Test("Custom separator: GBP→USD with arrow")
    func customSeparator() throws {
        let decimal = try #require(Decimal(string: "1.25"))
        let rate = try #require(ExchangeRate<GBP, USD>(majorUnitRate: decimal))
        let style = ExchangeRate<GBP, USD>.FormatStyle(.pair(separator: .custom(" → "))).locale(enGB)
        #expect(rate.formatted(style) == "£1.00 → US$1.25")
    }

    // MARK: - Locale

    @Test("German locale formats both sides with German conventions")
    func germanLocale() throws {
        let decimal = try #require(Decimal(string: "1.25"))
        let rate = try #require(ExchangeRate<GBP, USD>(majorUnitRate: decimal))
        let result = rate.formatted(.pair.locale(deDE))
        #expect(result == "1,00\u{00A0}£ = 1,25\u{00A0}$")
    }

    // MARK: - Coverage: static factories

    @Test(".pair static var uses default equals separator")
    func pairStaticVar() throws {
        let decimal = try #require(Decimal(string: "1.25"))
        let rate = try #require(ExchangeRate<GBP, USD>(majorUnitRate: decimal))
        let result = rate.formatted(.pair.locale(enGB))
        #expect(result.contains(" = "))
    }

    @Test(".pair(separator:) static factory")
    func pairSeparatorFactory() throws {
        let decimal = try #require(Decimal(string: "1.25"))
        let rate = try #require(ExchangeRate<GBP, USD>(majorUnitRate: decimal))
        let result = rate.formatted(.pair(separator: .colon).locale(enGB))
        #expect(result.contains(" : "))
    }
}
