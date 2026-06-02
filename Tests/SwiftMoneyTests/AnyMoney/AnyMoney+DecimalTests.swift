import Foundation
import Testing
import SwiftMoney

@Suite("AnyMoney – Decimal Conversion")
struct AnyMoney_DecimalTests {

    // MARK: - Decimal init from AnyMoney

    @Test("Decimal init returns correct value for a ratio-100 currency")
    func decimalInitRatio100() throws {
        let any = Money<TST_100>(minorUnits: 150).erased
        let expected = try #require(Decimal(string: "1.50"))
        #expect(Decimal(any) == expected)
    }

    @Test("Decimal init returns correct value for a ratio-1 currency")
    func decimalInitRatio1() {
        let any = Money<TST_1>(minorUnits: 500).erased
        #expect(Decimal(any) == Decimal(500))
    }

    @Test("Decimal init returns correct value for zero")
    func decimalInitZero() {
        let any = Money<TST_100>.zero.erased
        #expect(Decimal(any) == Decimal(0))
    }

    @Test("Decimal init returns correct value for a negative value")
    func decimalInitNegative() throws {
        let any = Money<TST_100>(minorUnits: -275).erased
        let expected = try #require(Decimal(string: "-2.75"))
        #expect(Decimal(any) == expected)
    }

    @Test("Decimal(anyMoney) matches Decimal(money) for ratio-100 currency")
    func decimalInitMatchesTyped100() {
        let money = Money<TST_100>(minorUnits: 9999)
        #expect(Decimal(money.erased) == Decimal(money))
    }

    @Test("Decimal(anyMoney) matches Decimal(money) for ratio-1 currency")
    func decimalInitMatchesTyped1() {
        let money = Money<TST_1>(minorUnits: 9999)
        #expect(Decimal(money.erased) == Decimal(money))
    }
}
