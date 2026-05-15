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

    @Test("intValue is correct")
    func intValue() {
        let hundredMinorUnits = Money<TST_100>(minorUnits: 100)
        #expect(hundredMinorUnits.minorUnits == 100)

        let oneMinorUnit = Money<TST_1>(minorUnits: 100)
        #expect(oneMinorUnit.minorUnits == 100)
    }

    @Test("Special values")
    func specialValues() {
        #expect(Money<TST_100>.max.minorUnits == Int64.max)
        #expect(Money<TST_100>.min.minorUnits == Int64.min)
        #expect(Money<TST_100>.leastNonzeroMagnitude.minorUnits == 1)
        #expect(Money<TST_100>.greatestFiniteMagnitude.minorUnits == Int64.max)
    }

    @Test("sign returns .plus for positive/zero, .minus for negative")
    func sign() {
        #expect(Money<TST_100>(minorUnits: 42).sign == .plus)
        #expect(Money<TST_100>.zero.sign == .plus)
        #expect(Money<TST_100>(minorUnits: -42).sign == .minus)
        #expect(Money<TST_100>.min.sign == .minus)
    }
}
