import Foundation
import Testing
import SwiftMoney

@Suite("ExchangeRate.FormatStyle – rate mode")
struct ExchangeRateFormatStyleTests {

    private let enUS = Locale(identifier: "en_US")
    private let deDE = Locale(identifier: "de_DE")

    // MARK: - Same minimalQuantisation (100:100)

    @Test("1.25 rate between same-minQ currencies")
    func sameMinQ_1_25() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: Decimal(string: "1.25")!))
        #expect(rate.formatted(.rate(locale: enUS)) == "1.25")
    }

    @Test("Identity rate 1:1")
    func sameMinQ_identity() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(from: 1, to: 1))
        #expect(rate.formatted(.rate(locale: enUS)) == "1")
    }

    @Test("Large rate between same-minQ currencies")
    func sameMinQ_large() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: Decimal(string: "1234.56")!))
        #expect(rate.formatted(.rate(locale: enUS)) == "1,234.56")
    }

    // MARK: - Different minimalQuantisation (100:1)

    @Test("215.16 rate from minQ 100 to minQ 1")
    func differentMinQ_100_to_1() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_1>(majorUnitRate: Decimal(string: "215.16")!))
        #expect(rate.formatted(.rate(locale: enUS)) == "215.16")
    }

    @Test("0.004659 rate from minQ 1 to minQ 100")
    func differentMinQ_1_to_100() throws {
        let rate = try #require(ExchangeRate<TST_1, TST_100>(majorUnitRate: Decimal(string: "0.004659")!))
        #expect(rate.formatted(.rate(locale: enUS)) == "0.004659")
    }

    // MARK: - High-precision currency (100_000_000)

    @Test("Rate involving bitcoin-like currency")
    func highPrecision() throws {
        let rate = try #require(
            ExchangeRate<TST_100, TST_100_000_000>(majorUnitRate: Decimal(string: "0.000015")!)
        )
        #expect(rate.formatted(.rate(locale: enUS)) == "0.000015")
    }

    // MARK: - Locale formatting

    @Test("German locale uses comma as decimal separator")
    func germanLocale() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: Decimal(string: "1.25")!))
        #expect(rate.formatted(.rate(locale: deDE)) == "1,25")
    }

    @Test("German locale groups thousands with period")
    func germanLocaleGrouping() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(majorUnitRate: Decimal(string: "1234.56")!))
        #expect(rate.formatted(.rate(locale: deDE)) == "1.234,56")
    }

    // MARK: - formatted() convenience

    @Test("formatted() uses default .rate style")
    func formattedConvenience() throws {
        let rate = try #require(ExchangeRate<TST_100, TST_100>(from: 4, to: 5))
        // 5/4 = 1.25
        let result = rate.formatted(.rate(locale: enUS))
        #expect(result == "1.25")
    }
}
