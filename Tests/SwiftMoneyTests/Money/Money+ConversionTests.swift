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

    // MARK: - Exact Int conversions

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

    // MARK: - Int64 Conversions

    @Test("Int64 value round trips")
    func int64Value() throws {
        let int64 = Int64(12399)
        let value = try #require(Money<TST>(exactly: int64))
        #expect(Int64(value) == 12399)
    }

    @Test("Int64 min traps as NaN")
    func int64MinIsNaN() async {
        let int64Min = Int64.min
        let value = Money<TST>(minorUnits: int64Min)
        async #expect(processExitsWith: .failure) { _ = Int64(value) }
    }

    @Test("Int64 min + 1 round trips")
    func int64MinPlusOne() {
        let int64NearMin = Int64.min + 1
        let value = Money<TST>(minorUnits: int64NearMin)
        #expect(Int64(value) == int64NearMin)
    }

    @Test("Int64 max round trips")
    func int64Max() {
        let int64Max = Int64.max
        let value = Money<TST>(minorUnits: int64Max)
        #expect(Int64(value) == int64Max)
    }

    // MARK: - Exact Int64 Conversions

    @Test("Exact money init success on Int64")
    func exactInitForInt64() {
        let int64 = Int64(12399)
        let value = Money<TST>(minorUnits: int64)
        #expect(Int64(exactly: value) == 12399)
    }

    @Test("Exact money init traps as NaN on Int64.min")
    func exactInitForInt64Min() {
        let int64Min = Int64.min
        let value = Money<TST>(minorUnits: int64Min)
        #expect(Int64(exactly: value) == nil)
    }

    @Test("Exact money init success on Int64.min + 1")
    func exactInitForInt64MinPlusOne() {
        let int64NearMin = Int64.min + 1
        let value = Money<TST>(minorUnits: int64NearMin)
        #expect(Int64(exactly: value) == int64NearMin)
    }

    @Test("Exact money init success on Int64.max")
    func exactInitForInt64Max() {
        let int64Max = Int64.max
        let value = Money<TST>(minorUnits: int64Max)
        #expect(Int64(value) == int64Max)
    }
}
