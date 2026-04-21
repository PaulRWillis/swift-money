import SwiftMoney
import Testing

@Suite("Integer Type Conversions")
struct IntegerTests {

    // MARK: - Int Conversions

    @Test("Int value round trips")
    func intValue() {
        let int = Int(12399)
        let value = Money<TST_100>(minorUnits: int)
        #expect(Int(value) == 12399)
    }

    @Test("Int traps on NaN")
    func intTrapsOnNaN() async {
        await #expect(processExitsWith: .failure) { _ = Int(Money<TST_100>.nan) }
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

    @Test("Exact money init traps on NaN")
    func exactInitTrapsForIntNaN() {
        let value = Money<TST_100>.nan
        #expect(Int(exactly: value) == nil)
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

    // MARK: - Int64 Conversions

    @Test("Int64 value round trips")
    func int64Value() throws {
        let int64 = Int64(12399)
        let value = try #require(Money<TST_100>(exactly: int64))
        #expect(Int64(value) == 12399)
    }

    @Test("Int64 traps on NaN")
    func int64TrapsOnNaN() async {
        await #expect(processExitsWith: .failure) { _ = Int64(Money<TST_100>.nan) }
    }

    @Test("Int64 min + 1 round trips")
    func int64MinPlusOne() {
        let int64NearMin = Int64.min + 1
        let value = Money<TST_100>(minorUnits: int64NearMin)
        #expect(Int64(value) == int64NearMin)
    }

    @Test("Int64 max round trips")
    func int64Max() {
        let int64Max = Int64.max
        let value = Money<TST_100>(minorUnits: int64Max)
        #expect(Int64(value) == int64Max)
    }

    // MARK: - Exact Int64 Conversions

    @Test("Exact money init success on Int64")
    func exactInitForInt64() {
        let int64 = Int64(12399)
        let value = Money<TST_100>(minorUnits: int64)
        #expect(Int64(exactly: value) == 12399)
    }

    @Test("Exact money init traps on Int64 NaN")
    func exactInitForInt64NaN() {
        let value = Money<TST_100>.nan
        #expect(Int64(exactly: value) == nil)
    }

    @Test("Exact money init success on Int64.min + 1")
    func exactInitForInt64MinPlusOne() {
        let int64NearMin = Int64.min + 1
        let value = Money<TST_100>(minorUnits: int64NearMin)
        #expect(Int64(exactly: value) == int64NearMin)
    }

    @Test("Exact money init success on Int64.max")
    func exactInitForInt64Max() {
        let int64Max = Int64.max
        let value = Money<TST_100>(minorUnits: int64Max)
        #expect(Int64(value) == int64Max)
    }
    
    // MARK: - Int32 Conversions

    @Test("Int32 value round trips")
    func int32Value() throws {
        let int32 = Int32(12399)
        let value = try #require(Money<TST_100>(exactly: int32))
        #expect(Int32(value) == 12399)
    }

    @Test("Int32 traps on NaN")
    func int32TrapsOnNaN() async {
        await #expect(processExitsWith: .failure) { _ = Int32(Money<TST_100>.nan) }
    }

    @Test("Int32 min round trips")
    func int32Min() async throws {
        let int32Min = Int32.min
        let value = try #require(Money<TST_100>(exactly: int32Min))
        #expect(Int32(value) == int32Min)
    }

    @Test("Int32 max round trips")
    func int32Max() throws {
        let int32Max = Int32.max
        let value = try #require(Money<TST_100>(exactly: int32Max))
        #expect(Int32(value) == int32Max)
    }

    @Test("Int32 nil on underflow")
    func int32Underflow() async {
        await #expect(processExitsWith: .failure) {
            let int32Underflow = Int64(Int32.min) - 1
            let value = Money<TST_100>(minorUnits: int32Underflow)
            _ = Int32(value)
        }
    }

    @Test("Int32 nil on overflow")
    func int32Overflow() async {
        await #expect(processExitsWith: .failure) {
            let int32Overflow = Int64(Int32.max) + 1
            let value = Money<TST_100>(minorUnits: int32Overflow)
            _ = Int32(value)
        }
    }

    // MARK: - Exact Int32 Conversions

    @Test("Exact money init success on Int32")
    func exactInitForInt32() throws {
        let int32 = Int32(12399)
        let value = try #require(Money<TST_100>(exactly: int32))
        #expect(Int32(exactly: value) == 12399)
    }

    @Test("Exact money init is nil on Int32 NaN")
    func exactInitForInt32NaN() {
        let value = Money<TST_100>.nan
        #expect(Int32(exactly: value) == nil)
    }

    @Test("Exact money init success on Int32.min")
    func exactInitForInt32Min() throws {
        let int32Min = Int32.min
        let value = try #require(Money<TST_100>(exactly: int32Min))
        #expect(Int32(exactly: value) == Int32.min)
    }

    @Test("Exact money init success on Int32.max")
    func exactInitForInt32Max() throws {
        let int32Max = Int32.max
        let value = try #require(Money<TST_100>(exactly: int32Max))
        #expect(Int32(value) == int32Max)
    }

    @Test("Exact money init is nil on Int32 underflow")
    func exactInitForInt32Underflow() throws {
        let int32Underflow = Int64(Int32.min) - 1
        let value = try #require(Money<TST_100>(exactly: int32Underflow))
        #expect(Int32(exactly: value) == nil)
    }

    @Test("Exact money init is nil on Int32 overflow")
    func exactInitForInt32Overflow() throws {
        let int32Overflow = Int64(Int32.max) + 1
        let value = try #require(Money<TST_100>(exactly: int32Overflow))
        #expect(Int32(exactly: value) == nil)
    }

    // MARK: - UInt Conversions

    @Test("UInt value round trips")
    func uintValue() throws {
        let uint = UInt(12399)
        let value = try #require(Money<TST_100>(exactly: uint))
        #expect(UInt(value) == 12399)
    }

    @Test("UInt value round trips up to Int64 upper bound")
    func uintValueUpToInt64UpperBound() throws {
        let uint = UInt(Int64.max)
        let value = try #require(Money<TST_100>(exactly: uint))
        #expect(UInt(value) == Int64.max)
    }

    @Test("UInt traps on NaN")
    func uintTrapsOnNaN() async {
        await #expect(processExitsWith: .failure) { _ = UInt(Money<TST_100>.nan) }
    }

    @Test("UInt min round trips")
    func uintMin() async {
        let uintMin = Int64(UInt.min)
        let value = Money<TST_100>(minorUnits: uintMin)
        #expect(UInt(value) == uintMin)
    }

    @Test("UInt max traps on overflow")
    func uintMax() {
        let uintMax = UInt.max
        let value = Money<TST_100>(exactly: uintMax)
        #expect(value == nil)
    }

    @Test("UInt nil on underflow")
    func uintUnderflow() async {
        await #expect(processExitsWith: .failure) {
            let uintUnderflow = Int64(UInt.min) - 1
            let value = Money<TST_100>(minorUnits: uintUnderflow)
            _ = UInt(value)
        }
    }

    // MARK: - Exact UInt Conversions

    @Test("Exact money init success on UInt")
    func exactInitForUInt() throws {
        let uint = UInt(12399)
        let value = try #require(Money<TST_100>(exactly: uint))
        #expect(UInt(exactly: value) == 12399)
    }

    @Test("Exact money init is nil on UInt NaN")
    func exactInitForUIntNaN() {
        let value = Money<TST_100>.nan
        #expect(UInt(exactly: value) == nil)
    }

    @Test("Exact money init success on UInt.min")
    func exactInitForUIntMin() throws {
        let uintMin = UInt.min
        let value = try #require(Money<TST_100>(exactly: uintMin))
        #expect(UInt(exactly: value) == UInt.min)
    }

    @Test("Exact money init is nil on UInt underflow")
    func exactInitForUIntUnderflow() {
        let uintUnderflow = Int64(UInt.min) - 1
        let value = Money<TST_100>(minorUnits: uintUnderflow)
        #expect(UInt(exactly: value) == nil)
    }

    // MARK: - UInt64 Conversions

    @Test("UInt64 value round trips")
    func uint64Value() throws {
        let uint64 = UInt64(12399)
        let value = try #require(Money<TST_100>(exactly: uint64))
        #expect(UInt64(value) == 12399)
    }

    @Test("UInt64 value round trips up to Int64 upper bound")
    func uint64ValueUpToInt64UpperBound() throws {
        let uint64 = UInt64(Int64.max)
        let value = try #require(Money<TST_100>(exactly: uint64))
        #expect(UInt64(value) == Int64.max)
    }

    @Test("UInt64 traps on NaN")
    func uint64TrapsOnNaN() async {
        await #expect(processExitsWith: .failure) { _ = UInt64(Money<TST_100>.nan) }
    }

    @Test("UInt64 min round trips")
    func uint64Min() async {
        let uint64Min = Int64(UInt64.min)
        let value = Money<TST_100>(minorUnits: uint64Min)
        #expect(UInt64(value) == uint64Min)
    }

    @Test("UInt64 max traps on overflow")
    func uint64Max() {
        let uint64Max = UInt64.max
        let value = Money<TST_100>(exactly: uint64Max)
        #expect(value == nil)
    }

    @Test("UInt64 nil on underflow")
    func uint64Underflow() async {
        await #expect(processExitsWith: .failure) {
            let uint64Underflow = Int64(UInt64.min) - 1
            let value = Money<TST_100>(minorUnits: uint64Underflow)
            _ = UInt64(value)
        }
    }

    // MARK: - Exact UInt64 Conversions

    @Test("Exact money init success on UInt64")
    func exactInitForUInt64() throws {
        let uint64 = UInt64(12399)
        let value = try #require(Money<TST_100>(exactly: uint64))
        #expect(UInt64(exactly: value) == 12399)
    }

    @Test("Exact money init is nil on UInt64 NaN")
    func exactInitForUInt64NaN() {
        let value = Money<TST_100>.nan
        #expect(UInt64(exactly: value) == nil)
    }

    @Test("Exact money init success on UInt64.min")
    func exactInitForUInt64Min() throws {
        let uint64Min = UInt64.min
        let value = try #require(Money<TST_100>(exactly: uint64Min))
        #expect(UInt64(exactly: value) == UInt64.min)
    }

    @Test("Exact money init is nil on UInt64 underflow")
    func exactInitForUInt64Underflow() {
        let uint64Underflow = Int64(UInt64.min) - 1
        let value = Money<TST_100>(minorUnits: uint64Underflow)
        #expect(UInt64(exactly: value) == nil)
    }
    
    // MARK: - UInt32 Conversions

    @Test("UInt32 value round trips")
    func uint32Value() throws {
        let uint32 = UInt32(12399)
        let value = try #require(Money<TST_100>(exactly: uint32))
        #expect(UInt32(value) == 12399)
    }

    @Test("UInt32 traps on NaN")
    func uint32TrapsOnNaN() async {
        await #expect(processExitsWith: .failure) { _ = UInt32(Money<TST_100>.nan) }
    }

    @Test("UInt32 min round trips")
    func uint32Min() async throws {
        let uint32Min = UInt32.min
        let value = try #require(Money<TST_100>(exactly: uint32Min))
        #expect(UInt32(value) == uint32Min)
    }

    @Test("UInt32 max round trips")
    func uint32Max() throws {
        let uint32Max = UInt32.max
        let value = try #require(Money<TST_100>(exactly: uint32Max))
        #expect(UInt32(value) == uint32Max)
    }

    @Test("UInt32 nil on underflow")
    func uint32Underflow() async {
        await #expect(processExitsWith: .failure) {
            let uint32Underflow = Int64(UInt32.min) - 1
            let value = Money<TST_100>(minorUnits: uint32Underflow)
            _ = UInt32(value)
        }
    }

    // MARK: - Exact UInt32 Conversions

    @Test("Exact money init success on UInt32")
    func exactInitForUInt32() throws {
        let uint32 = UInt32(12399)
        let value = try #require(Money<TST_100>(exactly: uint32))
        #expect(UInt32(exactly: value) == 12399)
    }

    @Test("Exact money init is nil on UInt32 NaN")
    func exactInitForUInt32NaN() {
        let value = Money<TST_100>.nan
        #expect(UInt32(exactly: value) == nil)
    }

    @Test("Exact money init success on UInt32.min")
    func exactInitForUInt32Min() throws {
        let uint32Min = UInt32.min
        let value = try #require(Money<TST_100>(exactly: uint32Min))
        #expect(UInt32(exactly: value) == UInt32.min)
    }

    @Test("Exact money init success on UInt32.max")
    func exactInitForUInt32Max() throws {
        let uint32Max = UInt32.max
        let value = try #require(Money<TST_100>(exactly: uint32Max))
        #expect(UInt32(exactly: value) == uint32Max)
    }

    @Test("Exact money init is nil on UInt32 underflow")
    func exactInitForUInt32Underflow() {
        let uint32Underflow = Int64(UInt32.min) - 1
        let value = Money<TST_100>(minorUnits: uint32Underflow)
        #expect(UInt32(exactly: value) == nil)
    }

    @Test("Exact money init is nil on UInt32 overflow")
    func exactInitForUInt32Overflow() throws {
        let uint32Overflow = Int64(Int32.max) + 1
        let value = try #require(Money<TST_100>(exactly: uint32Overflow))
        #expect(Int32(exactly: value) == nil)
    }
}
