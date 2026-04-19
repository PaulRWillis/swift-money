import Testing
import SwiftMoney

@Suite("Basic Initialization and Properties")
struct BasicTests {

    @Test("Zero initialization")
    func zeroInit() {
        let zero = Money<TST>()
        #expect(zero.minorUnits == 0)
        #expect(zero == .zero)
        #expect(!zero.isNaN)
        #expect(zero == .zero)
    }

    @Test("Minor units initialization")
    func minorUnitsInit() {
        let value = Money<TST>(minorUnits: 123_456_789_00)
        #expect(value.minorUnits == 123_456_789_00)
    }

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

        let noMinorUnits = Money<NO_MINOR_UNITS>(minorUnits: 100)
        #expect(noMinorUnits.minorUnits == 100)
    }
}
