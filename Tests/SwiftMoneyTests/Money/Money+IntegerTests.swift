import SwiftMoney
import Testing

@Suite("Money - Integer Type Conversions")
struct Money_IntegerTests {

    // MARK: - Int Conversions

    @Test("Int value round trips")
    func intValue() {
        let int = Int(12399)
        let value = Money<TST_100>(minorUnits: int)
        #expect(Int(value) == 12399)
    }

    @Test("Int min + 1 round trips")
    func intMinPlusOne() {
        let intNearMin = Int.min + 1
        let value = Money<TST_100>(minorUnits: intNearMin)
        #expect(Int(value) == intNearMin)
    }

    @Test("Int max round trips")
    func intMax() {
        let intMax = Int.max
        let value = Money<TST_100>(minorUnits: intMax)
        #expect(Int(value) == intMax)
    }

    // MARK: - Exact Int conversions

    @Test("Exact money init success on Int")
    func exactInitForInt() {
        let int = Int(12399)
        let value = Money<TST_100>(minorUnits: int)
        #expect(Int(exactly: value) == 12399)
    }

    @Test("Exact money init success on Int.min + 1")
    func exactInitForIntMinPlusOne() {
        let intNearMin = Int.min + 1
        let value = Money<TST_100>(minorUnits: intNearMin)
        #expect(Int(exactly: value) == intNearMin)
    }

    @Test("Exact money init success on Int.max")
    func exactInitForIntMax() {
        let intMax = Int.max
        let value = Money<TST_100>(minorUnits: intMax)
        #expect(Int(value) == intMax)
    }
}
