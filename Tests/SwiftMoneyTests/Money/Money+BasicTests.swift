import Testing
import SwiftMoney

@Suite("Basic Properties")
struct BasicTests {

    @Test("Currency is correct")
    func currency() {
        let currency = Money<TST>(minorUnits: 0).currency
        let isEqual = currency == TST.self
        #expect(isEqual)
    }

    @Test("NaN")
    func nan() {
        let nan = Money<TST>.nan
        #expect(nan.isNaN)
        #expect(nan.minorUnits == Int64.min)
        #expect(nan != .zero)
    }

    @Test("intValue is correct")
    func intValue() {
        let hundredMinorUnits = Money<TST>(minorUnits: 100)
        #expect(hundredMinorUnits.minorUnits == 100)

        let noMinorUnits = Money<TST_0>(minorUnits: 100)
        #expect(noMinorUnits.minorUnits == 100)
    }

    @Test("isFinite returns true for non-NaN, false for NaN")
    func isFinite() {
        #expect(Money<TST>.zero.isFinite)
        #expect(Money<TST>(minorUnits: 42).isFinite)
        #expect(Money<TST>(minorUnits: -1).isFinite)
        #expect(Money<TST>.max.isFinite)
        #expect(Money<TST>.min.isFinite)
        #expect(!Money<TST>.nan.isFinite)
    }

    @Test("Special values")
    func specialValues() {
        #expect(Money<TST>.max.minorUnits == Int64.max)
        #expect(Money<TST>.min.minorUnits == Int64.min + 1)
        #expect(Money<TST>.leastNonzeroMagnitude.minorUnits == 1)
        #expect(Money<TST>.greatestFiniteMagnitude.minorUnits == Int64.max)
        #expect(Money<TST>.leastFiniteMagnitude == .min)
    }

    @Test("sign returns .plus for positive/zero/NaN, .minus for negative")
    func sign() {
        #expect(Money<TST>(minorUnits: 42).sign == .plus)
        #expect(Money<TST>.zero.sign == .plus)
        #expect(Money<TST>(minorUnits: -42).sign == .minus)
        #expect(Money<TST>.min.sign == .minus)
        #expect(Money<TST>.nan.sign == .plus)
    }
}
