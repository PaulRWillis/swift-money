import Testing
@testable import SwiftMoney

@Suite("Basic Initialization and Properties")
struct BasicTests {

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
