import Foundation
import Testing
import SwiftMoney

@Suite("AnyMoney – Decimal Conversion")
struct AnyMoney_DecimalTests {

    // MARK: - decimalValue

    @Test("decimalValue is correct for a ratio-100 currency")
    func decimalValueRatio100() {
        let any = Money<TST_100>(minorUnits: 150).erased
        #expect(any.decimalValue == Decimal(string: "1.50")!)
    }

    @Test("decimalValue is correct for a ratio-1 currency (no minor units)")
    func decimalValueRatio1() {
        let any = Money<TST_1>(minorUnits: 500).erased
        #expect(any.decimalValue == Decimal(500))
    }

    @Test("decimalValue is correct for zero")
    func decimalValueZero() {
        let any = Money<TST_100>.zero.erased
        #expect(any.decimalValue == Decimal(0))
    }

    @Test("decimalValue is correct for a negative value")
    func decimalValueNegative() {
        let any = Money<TST_100>(minorUnits: -275).erased
        #expect(any.decimalValue == Decimal(string: "-2.75")!)
    }

    @Test("decimalValue returns Decimal.nan for an erased NaN")
    func decimalValueNaN() {
        let any = Money<TST_100>.nan.erased
        #expect(any.decimalValue.isNaN)
    }

    @Test("decimalValue matches Money<C>.decimalValue for ratio-100 currency")
    func decimalValueMatchesTyped100() {
        let money = Money<TST_100>(minorUnits: 9999)
        #expect(money.erased.decimalValue == money.decimalValue)
    }

    @Test("decimalValue matches Money<C>.decimalValue for ratio-1 currency")
    func decimalValueMatchesTyped1() {
        let money = Money<TST_1>(minorUnits: 9999)
        #expect(money.erased.decimalValue == money.decimalValue)
    }
}
