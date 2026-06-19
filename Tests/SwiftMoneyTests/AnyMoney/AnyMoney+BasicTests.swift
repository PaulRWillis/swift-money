import Testing
import SwiftMoney

@Suite("AnyMoney – Basic Properties")
struct AnyMoney_BasicTests {

    // MARK: - Properties preserved on init

    @Test("minorUnits is preserved on init")
    func minorUnitsPreserved() {
        let any = Money<TST_100>(minorUnits: 500).erased
        #expect(any.minorUnits == 500)
    }

    @Test("currencyCode is preserved on init")
    func currencyCodePreserved() {
        let any = Money<TST_100>(minorUnits: 500).erased
        #expect(any.currencyCode == TST_100.code)
    }

    @Test("currency metatype is set on init from TST_100")
    func currencyMetatypeRatio100() {
        let any = Money<TST_100>(minorUnits: 1).erased
        #expect(any.currency == TST_100.self)
    }

    @Test("currency metatype is set on init from TST_1")
    func currencyMetatypeRatio1() {
        let any = Money<TST_1>(minorUnits: 1).erased
        #expect(any.currency == TST_1.self)
    }

    // MARK: - erased

    @Test("erased preserves minorUnits")
    func erasedPreservesMinorUnits() {
        let money = Money<TST_100>(minorUnits: 9876)
        #expect(money.erased.minorUnits == money.minorUnits)
    }

    @Test("erased preserves currencyCode")
    func erasedPreservesCurrencyCode() {
        let money = Money<TST_100>(minorUnits: 9876)
        #expect(money.erased.currencyCode == TST_100.code)
    }

    // MARK: - Money.init from AnyMoney round-trip

    @Test("Money.init returns typed value for matching currency")
    func moneyInitMatchingCurrency() throws {
        let money = Money<TST_100>(minorUnits: 500)
        let roundTripped = try #require(Money<TST_100>(money.erased))
        #expect(roundTripped == money)
    }

    @Test("Money.init returns nil for mismatched currency")
    func moneyInitMismatchedCurrency() {
        let any = Money<TST_100>(minorUnits: 500).erased
        #expect(Money<TST_1>(any) == nil)
    }

}
