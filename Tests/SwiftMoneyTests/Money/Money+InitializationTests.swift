import Testing
import SwiftMoney

@Suite("Initialization")
struct InitializationTests {

    @Test("Zero initialization")
    func zeroInit() {
        let zero = Money<TST_100>()
        #expect(zero.minorUnits == 0)
        #expect(zero == .zero)
        #expect(!zero.isNaN)
        #expect(zero == .zero)
    }

    // MARK: - Int init

    @Test("Int minor units initialization")
    func intInit() {
        let value = Money<TST_100>(minorUnits: Int(123_456_789_00))
        #expect(value.minorUnits == 123_456_789_00)
    }

    @Test("Int negative minor units initialization")
    func negativeIntInit() {
        let value = Money<TST_100>(minorUnits: Int(-123_456_789_00))
        #expect(value.minorUnits == -123_456_789_00)
    }

    @Test("Init success for Int.max")
    func intMaxInit() {
        let intMax = Money<TST_100>(minorUnits: Int.max)
        #expect(intMax.minorUnits == Int.max)
    }

    @Test("Init sucesss for Int.min")
    func intMinInit() {
        let intMin = Money<TST_100>(minorUnits: Int.min)
        #expect(intMin.minorUnits == Int.min)
    }

    // MARK: - Int64 init

    @Test("Init success for Int64")
    func int64Init() {
        let value = Money<TST_100>(minorUnits: Int64(123_456_789_00))
        #expect(value.minorUnits == 123_456_789_00)
    }

    @Test("Init success for negative Int64")
    func negativeInt64Init() {
        let value = Money<TST_100>(minorUnits: Int64(-123_456_789_00))
        #expect(value.minorUnits == -123_456_789_00)
    }

    @Test("Init success for Int64.max")
    func int64MaxInit() {
        let int64Max = Money<TST_100>(minorUnits: Int64.max)
        #expect(int64Max.minorUnits == Int64.max)
    }

    @Test("Init sucesss for Int64.min")
    func int64MinInit() {
        let int64Min = Money<TST_100>(minorUnits: Int64.min)
        #expect(int64Min.minorUnits == Int64.min)
    }

    // MARK: - Exact integer init for Int128

    @available(macOS 15.0, *)
    @Test("Exact integer init oveflow for Int128.max")
    func exactIntegerInitOverflowForInt128Max() {
        let int128Max = Money<TST_100>(exactly: Int128.max)
        #expect(int128Max == nil)
    }

    @available(macOS 15.0, *)
    @Test("Exact integer init oveflow for Int128.min")
    func exactIntegerInitOverflowForInt128Min() {
        let int128Min = Money<TST_100>(exactly: Int128.min)
        #expect(int128Min == nil)
    }

    // MARK: - Exact integer init for Int64

    @Test("Exact integer init success for Int64")
    func exactIntegerInitForInt64() {
        let int64 = Money<TST_100>(exactly: Int64(42))
        #expect(int64 != nil)
        #expect(int64?.minorUnits == 42)
    }

    @Test("Exact integer init success for Int64.max")
    func exactIntegerInitForInt64Max() {
        let int64Max = Money<TST_100>(exactly: Int64.max)
        #expect(int64Max != nil)
        #expect(int64Max?.minorUnits == Int64.max)
    }

    @Test("Exact integer init success for Int64.min")
    func exactIntegerInitForInt64Min() {
        let int64Min = Money<TST_100>(exactly: Int64.min)
        #expect(int64Min != nil)
        #expect(int64Min?.minorUnits == Int64.min)
    }

    // MARK: - Exact integer init for Int32

    @Test("Exact integer init success for Int32.max")
    func exactIntegerInitForInt32Max() {
        let int32Max = Money<TST_100>(exactly: Int32.max)
        #expect(int32Max != nil)
        #expect(int32Max?.minorUnits == Int64(Int32.max))
    }

    @Test("Exact integer init success for Int32.min")
    func exactIntegerInitForInt32Min() {
        let Int32Min = Money<TST_100>(exactly: Int32.min)
        #expect(Int32Min != nil)
        #expect(Int32Min?.minorUnits == Int64(Int32.min))
    }

    // MARK: - Exact integer init for Int16

    @Test("Exact integer init success for Int16.max")
    func exactIntegerInitForInt16Max() {
        let int16Max = Money<TST_100>(exactly: Int16.max)
        #expect(int16Max != nil)
        #expect(int16Max?.minorUnits == Int64(Int16.max))
    }

    @Test("Exact integer init success for Int16.min")
    func exactIntegerInitForInt16Min() {
        let Int16Min = Money<TST_100>(exactly: Int16.min)
        #expect(Int16Min != nil)
        #expect(Int16Min?.minorUnits == Int64(Int16.min))
    }

    // MARK: - Exact integer init for Int8

    @Test("Exact integer init success for Int8.max")
    func exactIntegerInitForInt8Max() {
        let int8Max = Money<TST_100>(exactly: Int8.max)
        #expect(int8Max != nil)
        #expect(int8Max?.minorUnits == Int64(Int8.max))
    }

    @Test("Exact integer init success for Int8.min")
    func exactIntegerInitForInt8Min() {
        let Int8Min = Money<TST_100>(exactly: Int8.min)
        #expect(Int8Min != nil)
        #expect(Int8Min?.minorUnits == Int64(Int8.min))
    }

    // MARK: - Exact integer init for UInt

    @Test("Init success for UInt")
    func uintInit() throws {
        let value = try #require(Money<TST_100>(exactly: UInt(123_456_789)))
        #expect(value.minorUnits == 123_456_789)
    }

    @Test("Init overflow for UInt.max")
    func uintMaxInit() {
        let uintMax = Money<TST_100>(exactly: UInt.max)
        #expect(uintMax == nil)
    }

    @Test("Init success for UInt.min")
    func uintMinInit() throws {
        let uintMin = try #require(Money<TST_100>(exactly: UInt.min))
        #expect(uintMin.minorUnits == Int64(UInt.min))
    }
}
