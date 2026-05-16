import Foundation
import Testing
@testable import SwiftMoney

private typealias Storage = MinorUnit.Storage

@Suite("MinorUnit")
struct MinorUnitTests {

    // MARK: - Failable Initialisation

    @Test("init exactly accepts zero")
    func exactlyAcceptsZero() throws {
        let minorUnit = try #require(MinorUnit(exactly: 0))
        #expect(minorUnit._storage == 0)
    }

    @Test("init exactly accepts positive values")
    func exactlyAcceptsPositive() throws {
        let minorUnit = try #require(MinorUnit(exactly: 150))
        #expect(minorUnit._storage == 150)
    }

    @Test("init exactly accepts negative values")
    func exactlyAcceptsNegative() throws {
        let minorUnit = try #require(MinorUnit(exactly: -150))
        #expect(minorUnit._storage == -150)
    }

    @Test("init exactly accepts Storage.max")
    func exactlyAcceptsStorageMax() throws {
        let minorUnit = try #require(MinorUnit(exactly: Storage.max))
        #expect(minorUnit._storage == .max)
    }

    @Test("init exactly accepts Storage.min + 1")
    func exactlyAcceptsStorageMinPlusOne() throws {
        let minorUnit = try #require(MinorUnit(exactly: Storage.min + 1))
        #expect(minorUnit._storage == .min + 1)
    }

    @Test("init exactly rejects Storage.min")
    func exactlyRejectsStorageMin() {
        #expect(MinorUnit(exactly: Storage.min) == nil)
    }

    @Test("init exactly accepts Int that fits in Storage")
    func exactlyAcceptsInt() throws {
        let minorUnit = try #require(MinorUnit(exactly: 42 as Int))
        #expect(minorUnit._storage == 42)
    }

    @Test("init exactly rejects UInt64 that overflows Storage")
    func exactlyRejectsOverflowingUInt64() {
        #expect(MinorUnit(exactly: UInt64.max) == nil)
    }

    @Test("init exactly accepts Int128 that fits")
    func exactlyAcceptsInt128() throws {
        let minorUnit = try #require(MinorUnit(exactly: Int128(1000)))
        #expect(minorUnit._storage == 1000)
    }

    @Test("init exactly rejects Int128 that overflows Storage")
    func exactlyRejectsOverflowingInt128() {
        #expect(MinorUnit(exactly: Int128.max) == nil)
    }

    // MARK: - Int64 Conversion

    @Test("Int64 init produces the stored value")
    func int64ConversionProducesStoredValue() throws {
        let minorUnit = try #require(MinorUnit(exactly: 42))
        #expect(Int64(minorUnit) == 42)
    }

    @Test("Int64 round-trips through MinorUnit")
    func int64RoundTrips() throws {
        let original = Storage.min + 1
        let minorUnit = try #require(MinorUnit(exactly: original))
        #expect(Int64(minorUnit) == original)
    }

    // MARK: - ExpressibleByIntegerLiteral

    @Test("Integer literal produces correct value")
    func integerLiteral() {
        let minorUnit: MinorUnit = 100
        #expect(minorUnit._storage == 100)
    }

    @Test("Negative integer literal produces correct value")
    func negativeIntegerLiteral() {
        let minorUnit: MinorUnit = -50
        #expect(minorUnit._storage == -50)
    }

    @Test("Integer literal traps on Storage.min")
    func integerLiteralTrapsOnStorageMin() async {
        await #expect(processExitsWith: .failure) {
            _ = MinorUnit(integerLiteral: .min)
        }
    }

    // MARK: - Static Properties

    @Test("zero is 0")
    func zeroIsZero() {
        #expect(MinorUnit.zero._storage == 0)
    }

    @Test("min is Storage.min + 1")
    func minIsStorageMinPlusOne() {
        #expect(MinorUnit.min._storage == .min + 1)
    }
}
