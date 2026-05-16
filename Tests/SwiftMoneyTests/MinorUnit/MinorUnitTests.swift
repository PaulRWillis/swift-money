import Foundation
import Testing
@testable import SwiftMoney

@Suite("MinorUnit")
struct MinorUnitTests {

    // MARK: - Failable Initialisation

    @Test("init exactly accepts zero")
    func exactlyAcceptsZero() throws {
        let minorUnit = try #require(MinorUnit(exactly: Int64(0)))
        #expect(Int64(minorUnit) == 0)
    }

    @Test("init exactly accepts positive values")
    func exactlyAcceptsPositive() throws {
        let minorUnit = try #require(MinorUnit(exactly: Int64(150)))
        #expect(Int64(minorUnit) == 150)
    }

    @Test("init exactly accepts negative values")
    func exactlyAcceptsNegative() throws {
        let minorUnit = try #require(MinorUnit(exactly: Int64(-150)))
        #expect(Int64(minorUnit) == -150)
    }

    @Test("init exactly accepts Int64.max")
    func exactlyAcceptsInt64Max() throws {
        let minorUnit = try #require(MinorUnit(exactly: Int64.max))
        #expect(Int64(minorUnit) == .max)
    }

    @Test("init exactly accepts Int64.min + 1")
    func exactlyAcceptsInt64MinPlusOne() throws {
        let minorUnit = try #require(MinorUnit(exactly: Int64.min + 1))
        #expect(Int64(minorUnit) == .min + 1)
    }

    @Test("init exactly rejects Int64.min")
    func exactlyRejectsInt64Min() {
        #expect(MinorUnit(exactly: Int64.min) == nil)
    }

    @Test("init exactly accepts Int that fits in Int64")
    func exactlyAcceptsInt() throws {
        let minorUnit = try #require(MinorUnit(exactly: 42 as Int))
        #expect(Int64(minorUnit) == 42)
    }

    @Test("init exactly rejects UInt64 that overflows Int64")
    func exactlyRejectsOverflowingUInt64() {
        #expect(MinorUnit(exactly: UInt64.max) == nil)
    }

    @Test("init exactly accepts Int128 that fits")
    func exactlyAcceptsInt128() throws {
        let minorUnit = try #require(MinorUnit(exactly: Int128(1000)))
        #expect(Int64(minorUnit) == 1000)
    }

    @Test("init exactly rejects Int128 that overflows Int64")
    func exactlyRejectsOverflowingInt128() {
        #expect(MinorUnit(exactly: Int128.max) == nil)
    }

    // MARK: - Int64 Conversion

    @Test("Int64 init produces the stored value")
    func int64ConversionProducesStoredValue() throws {
        let minorUnit = try #require(MinorUnit(exactly: Int64(42)))
        #expect(Int64(minorUnit) == 42)
    }

    @Test("Int64 round-trips through MinorUnit")
    func int64RoundTrips() throws {
        let original: Int64 = -9_223_372_036_854_775_807
        let minorUnit = try #require(MinorUnit(exactly: original))
        #expect(Int64(minorUnit) == original)
    }

    // MARK: - ExpressibleByIntegerLiteral

    @Test("Integer literal produces correct value")
    func integerLiteral() {
        let minorUnit: MinorUnit = 100
        #expect(Int64(minorUnit) == 100)
    }

    @Test("Negative integer literal produces correct value")
    func negativeIntegerLiteral() {
        let minorUnit: MinorUnit = -50
        #expect(Int64(minorUnit) == -50)
    }

    @Test("Integer literal traps on Int64.min")
    func integerLiteralTrapsOnInt64Min() async {
        await #expect(processExitsWith: .failure) {
            _ = MinorUnit(integerLiteral: .min)
        }
    }
}
