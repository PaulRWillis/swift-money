import Testing
import SwiftMoney

@Suite("Money - Basic Properties")
struct Money_BasicTests {

    @Test("Currency is correct")
    func currency() {
        let currency = Money<TST_100>(minorUnits: 0).currency
        let isEqual = currency == TST_100.self
        #expect(isEqual)
    }

    @Test("NaN")
    func nan() {
        let nan = Money<TST_100>.nan
        #expect(nan.isNaN)
        #expect(nan.minorUnits == Int64.min)
        #expect(nan != .zero)
    }

    @Test("intValue is correct")
    func intValue() {
        let hundredMinorUnits = Money<TST_100>(minorUnits: 100)
        #expect(hundredMinorUnits.minorUnits == 100)

        let noMinorUnits = Money<TST_0>(minorUnits: 100)
        #expect(noMinorUnits.minorUnits == 100)
    }

    @Test("isFinite returns true for non-NaN, false for NaN")
    func isFinite() {
        #expect(Money<TST_100>.zero.isFinite)
        #expect(Money<TST_100>(minorUnits: 42).isFinite)
        #expect(Money<TST_100>(minorUnits: -1).isFinite)
        #expect(Money<TST_100>.max.isFinite)
        #expect(Money<TST_100>.min.isFinite)
        #expect(!Money<TST_100>.nan.isFinite)
    }

    @Test("Special values")
    func specialValues() {
        #expect(Money<TST_100>.max.minorUnits == Int64.max)
        #expect(Money<TST_100>.min.minorUnits == Int64.min + 1)
        #expect(Money<TST_100>.leastNonzeroMagnitude.minorUnits == 1)
        #expect(Money<TST_100>.greatestFiniteMagnitude.minorUnits == Int64.max)
        #expect(Money<TST_100>.leastFiniteMagnitude == .min)
    }

    @Test("sign returns .plus for positive/zero/NaN, .minus for negative")
    func sign() {
        #expect(Money<TST_100>(minorUnits: 42).sign == .plus)
        #expect(Money<TST_100>.zero.sign == .plus)
        #expect(Money<TST_100>(minorUnits: -42).sign == .minus)
        #expect(Money<TST_100>.min.sign == .minus)
        #expect(Money<TST_100>.nan.sign == .plus)
    }
}
