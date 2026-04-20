import SwiftMoney
import Testing

@Suite("Type Conversions")
struct ConversionTests {

    // MARK: - Int Conversions

    @Test("Int value round trips")
    func intValue() {
        let int = Int(12399)
        let value = Money<TST>(minorUnits: int)
        #expect(Int(value) == 12399)
    }

    @Test("Int min traps as NaN")
    func intMinIsNaN() async {
        let intMin = Int64.min
        let value = Money<TST>(minorUnits: intMin)
        async #expect(processExitsWith: .failure) { _ = Int(value) }
    }

    @Test("Int min + 1 round trips")
    func intMinPlusOne() {
        let intNearMin = Int.min + 1
        let value = Money<TST>(minorUnits: intNearMin)
        #expect(Int(value) == intNearMin)
    }

    @Test("Int max round trips")
    func intMax() {
        let intMax = Int.max
        let value = Money<TST>(minorUnits: intMax)
        #expect(Int(value) == intMax)
    }

    @Test("Exact money init success on Int")
    func exactInitForInt() {
        let int = Int(12399)
        let value = Money<TST>(minorUnits: int)
        #expect(Int(exactly: value) == 12399)
    }

    @Test("Exact money init traps as NaN on Int.min")
    func exactInitForIntMin() {
        let intMin = Int.min
        let value = Money<TST>(minorUnits: intMin)
        #expect(Int(exactly: value) == nil)
    }

    @Test("Exact money init success on Int.min + 1")
    func exactInitForIntMinPlusOne() {
        let intNearMin = Int.min + 1
        let value = Money<TST>(minorUnits: intNearMin)
        #expect(Int(exactly: value) == intNearMin)
    }

    @Test("Exact money init success on Int.max")
    func exactInitForIntMax() {
        let intMax = Int.max
        let value = Money<TST>(minorUnits: intMax)
        #expect(Int(value) == intMax)
    }
}
