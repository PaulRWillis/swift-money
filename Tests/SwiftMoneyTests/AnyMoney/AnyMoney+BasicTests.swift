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

    @Test("minorUnitRatio is preserved for ratio-100 currency")
    func minorUnitRatioRatio100() {
        let any = Money<TST_100>(minorUnits: 500).erased
        #expect(any.minorUnitRatio == 100)
    }

    @Test("minorUnitRatio is preserved for ratio-1 currency")
    func minorUnitRatioRatio1() {
        let any = Money<TST_1>(minorUnits: 500).erased
        #expect(any.minorUnitRatio == 1)
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

    // MARK: - isNaN / isFinite

    @Test("isNaN is false for a normal value")
    func isNaNFalseForNormal() {
        let any = Money<TST_100>(minorUnits: 100).erased
        #expect(!any.isNaN)
    }

    @Test("isFinite is true for a normal value")
    func isFiniteTrueForNormal() {
        let any = Money<TST_100>(minorUnits: 100).erased
        #expect(any.isFinite)
    }

    @Test("isNaN is true for an erased NaN")
    func isNaNTrueForErasedNaN() {
        let any = Money<TST_100>.nan.erased
        #expect(any.isNaN)
    }

    @Test("isFinite is false for an erased NaN")
    func isFiniteFalseForErasedNaN() {
        let any = Money<TST_100>.nan.erased
        #expect(!any.isFinite)
    }

    @Test("NaN minorUnits equals Int64.min (sentinel)")
    func nanMinorUnitsSentinel() {
        let any = Money<TST_100>.nan.erased
        #expect(any.minorUnits == Int64.min)
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

    // MARK: - asMoney round-trip

    @Test("asMoney returns typed value for matching currency")
    func asMoneyMatchingCurrency() throws {
        let money = Money<TST_100>(minorUnits: 500)
        let roundTripped = try #require(money.erased.asMoney(TST_100.self))
        #expect(roundTripped == money)
    }

    @Test("asMoney returns nil for mismatched currency")
    func asMoneyMismatchedCurrency() {
        let any = Money<TST_100>(minorUnits: 500).erased
        #expect(any.asMoney(TST_1.self) == nil)
    }

    @Test("asMoney preserves NaN through round-trip")
    func asMoneyPreservesNaN() throws {
        let original = Money<TST_100>.nan
        let roundTripped = try #require(original.erased.asMoney(TST_100.self))
        #expect(roundTripped.isNaN)
    }
}
