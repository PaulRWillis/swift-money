import Testing
@testable import SwiftMoney

@Suite("Basic Initialization and Properties")
struct BasicTests {

    @Test("Zero initialization")
    func zeroInit() {
        let zero = Money<TST>()
        #expect(zero._minorUnits == 0)
        #expect(zero == .zero)
        #expect(zero == .zero)
    }

    @Test("Minor units initialization")
    func minorUnitsInit() {
        let value = Money<TST>(minorUnits: 123_456_789_00)
        #expect(value._minorUnits == 123_456_789_00)
    }

    @Test("Currency is correct")
    func currency() {
        let currency = Money<TST>(minorUnits: 0).currency
        let isEqual = currency == TST.self
        #expect(isEqual)
    }
}
