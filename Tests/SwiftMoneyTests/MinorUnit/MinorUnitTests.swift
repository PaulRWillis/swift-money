import Foundation
import Testing
@testable import SwiftMoney

private typealias Storage = Int

#warning("Remove this entire test suite. Tests should have no knowledge of `MinorUnit` internal type")
@Suite("MinorUnit")
struct MinorUnitTests {

    // MARK: - Failable Initialisation

    // Assertions use Int64(_:) — not == literal — to avoid false positives.
    // Literal coercion would call init(exactly:) on both sides of ==, so a
    // bug that always stores zero would produce MinorUnit(0) == MinorUnit(0).

    @Test("init exactly accepts zero")
    func exactlyAcceptsZero() throws {
        let minorUnit = try #require(MinorUnit(exactly: 0))
        #expect(Int64(minorUnit) == 0)
    }

    @Test("init exactly accepts positive values")
    func exactlyAcceptsPositive() throws {
        let minorUnit = try #require(MinorUnit(exactly: 150))
        #expect(Int64(minorUnit) == 150)
    }

    @Test("init exactly accepts negative values")
    func exactlyAcceptsNegative() throws {
        let minorUnit = try #require(MinorUnit(exactly: -150))
        #expect(Int64(minorUnit) == -150)
    }

    @Test("init exactly accepts Storage.max")
    func exactlyAcceptsStorageMax() throws {
        let minorUnit = try #require(MinorUnit(exactly: Storage.max))
        #expect(Int64(minorUnit) == Storage.max)
    }

    @Test("init exactly accepts Storage.min")
    func exactlyAcceptsStorageMin() throws {
        let minorUnit = try #require(MinorUnit(exactly: Storage.min))
        #expect(Int64(minorUnit) == Storage.min)
    }

    @Test("init exactly accepts Int that fits in Storage")
    func exactlyAcceptsInt() throws {
        let minorUnit = try #require(MinorUnit(exactly: 42 as Int))
        #expect(Int64(minorUnit) == 42)
    }

    @Test("init exactly rejects UInt64 that overflows Storage")
    func exactlyRejectsOverflowingUInt64() {
        #expect(MinorUnit(exactly: UInt64.max) == nil)
    }

    @Test("init exactly accepts Int128 that fits")
    func exactlyAcceptsInt128() throws {
        let minorUnit = try #require(MinorUnit(exactly: Int128(1000)))
        #expect(Int64(minorUnit) == 1000)
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

    // Assertions use Int64(_:) for the same false-positive reason as init tests.

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

    // MARK: - Static Properties

    // Boundary values (.min, .max) use Int64(_:) for the same false-positive
    // reason as init tests. .zero uses == literal since zero is unambiguous.

    @Test("zero is 0")
    func zeroIsZero() {
        #expect(MinorUnit.zero == 0)
    }

    @Test("min is Storage.min")
    func minIsStorageMin() {
        #expect(Int64(MinorUnit.min) == Storage.min)
    }

    @Test("max is Storage.max")
    func maxIsStorageMax() {
        #expect(Int64(MinorUnit.max) == Storage.max)
    }

    // MARK: - Equatable

    @Test("equal values are equal")
    func equalValuesAreEqual() throws {
        let a = try #require(MinorUnit(exactly: 100))
        let b = try #require(MinorUnit(exactly: 100))
        #expect(a == b)
    }

    @Test("different values are not equal")
    func differentValuesAreNotEqual() throws {
        let a = try #require(MinorUnit(exactly: 100))
        let b = try #require(MinorUnit(exactly: 200))
        #expect(a != b)
    }

    // MARK: - Comparable

    @Test("smaller value is less than larger value")
    func smallerIsLessThanLarger() {
        let a: MinorUnit = 100
        let b: MinorUnit = 200
        #expect(a < b)
    }

    @Test("larger value is not less than smaller value")
    func largerIsNotLessThanSmaller() {
        let a: MinorUnit = 200
        let b: MinorUnit = 100
        #expect(!(a < b))
    }

    @Test("equal values are not less than each other")
    func equalValuesAreNotLessThan() {
        let a: MinorUnit = 100
        let b: MinorUnit = 100
        #expect(!(a < b))
    }

    // MARK: - Hashable

    @Test("equal values produce the same hash")
    func equalValuesProduceSameHash() throws {
        let a = try #require(MinorUnit(exactly: 42))
        let b = try #require(MinorUnit(exactly: 42))
        #expect(a.hashValue == b.hashValue)
    }

    @Test("can be used as a Set element")
    func canBeUsedAsSetElement() {
        let set: Set<MinorUnit> = [1, 2, 3, 1]
        #expect(set.count == 3)
    }

    // MARK: - CustomStringConvertible

    @Test("description is the numeric value")
    func descriptionIsNumericValue() {
        let minorUnit: MinorUnit = 150
        #expect(minorUnit.description == "150")
    }

    @Test("description of negative value includes minus sign")
    func descriptionOfNegativeValue() {
        let minorUnit: MinorUnit = -42
        #expect(minorUnit.description == "-42")
    }

    // MARK: - CustomDebugStringConvertible

    @Test("debugDescription includes type name")
    func debugDescriptionIncludesTypeName() {
        let minorUnit: MinorUnit = 150
        #expect(minorUnit.debugDescription == "MinorUnit(150)")
    }

    @Test("debugDescription of negative value")
    func debugDescriptionOfNegativeValue() {
        let minorUnit: MinorUnit = -42
        #expect(minorUnit.debugDescription == "MinorUnit(-42)")
    }

    // MARK: - Codable

    @Test("round-trips through JSON")
    func codableRoundTrip() throws {
        let original: MinorUnit = 150
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MinorUnit.self, from: data)
        #expect(decoded == original)
    }

    @Test("encodes as a bare integer")
    func encodesAsBareInteger() throws {
        let minorUnit: MinorUnit = 42
        let data = try JSONEncoder().encode(minorUnit)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json == "42")
    }

    // MARK: - Addition

    @Test("adding two positive values")
    func addPositiveValues() {
        let result: MinorUnit = 100 + 50
        #expect(result == 150)
    }

    @Test("adding positive and negative values")
    func addPositiveAndNegative() {
        let result: MinorUnit = 100 + (-30)
        #expect(result == 70)
    }

    @Test("adding zero is identity")
    func addZeroIsIdentity() {
        let result: MinorUnit = 42 + .zero
        #expect(result == 42)
    }

    @Test("adding to produce .max")
    func addToMax() throws {
        let a = try #require(MinorUnit(exactly: Storage.max - 1))
        let result = a + 1
        #expect(result == .max)
    }

    @Test("adding to produce .min")
    func addToMin() throws {
        let a = try #require(MinorUnit(exactly: Storage.min + 1))
        let result = a + (-1)
        #expect(result == .min)
    }

    @Test("adding past .max traps")
    func addPastMaxTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = MinorUnit.max + 1
        }
    }

    @Test("adding to produce Storage.min traps")
    func addToStorageMinTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = MinorUnit.min + (-1)
        }
    }

    // MARK: - Subtraction

    @Test("subtracting two values")
    func subtractValues() {
        let result: MinorUnit = 100 - 30
        #expect(result == 70)
    }

    @Test("subtracting to produce negative result")
    func subtractToNegative() {
        let result: MinorUnit = 30 - 100
        #expect(result == -70)
    }

    @Test("subtracting zero is identity")
    func subtractZeroIsIdentity() {
        let result: MinorUnit = 42 - .zero
        #expect(result == 42)
    }

    @Test("subtracting to produce .min")
    func subtractToMin() throws {
        let a = try #require(MinorUnit(exactly: Storage.min + 1))
        let result = a - 1
        #expect(result == .min)
    }

    @Test("subtracting to produce .max")
    func subtractToMax() throws {
        let a = try #require(MinorUnit(exactly: Storage.max - 1))
        let b: MinorUnit = -1
        let result = a - b
        #expect(result == .max)
    }

    @Test("subtracting past .min traps")
    func subtractPastMinTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = MinorUnit.min - 1
        }
    }

    // MARK: - AdditiveArithmetic

    @Test("conforms to AdditiveArithmetic")
    func conformsToAdditiveArithmetic() {
        func addGeneric<T: AdditiveArithmetic>(_ a: T, _ b: T) -> T { a + b }
        let result = addGeneric(MinorUnit(integerLiteral: 3), MinorUnit(integerLiteral: 4))
        #expect(result == 7)
    }

    // MARK: - Scalar Multiplication

    @Test("MinorUnit times Int64")
    func minorUnitTimesInt64() {
        let result: MinorUnit = 5 * Int(3)
        #expect(result == 15)
    }

    @Test("Int64 times MinorUnit")
    func int64TimesMinorUnit() {
        let minorUnit: MinorUnit = 5
        let result = Int(3) * minorUnit
        #expect(result == 15)
    }

    @Test("multiplying by zero produces zero")
    func multiplyByZero() {
        let result: MinorUnit = 42 * Int(0)
        #expect(result == .zero)
    }

    @Test("multiplying by negative scalar")
    func multiplyByNegativeScalar() {
        let result: MinorUnit = 10 * Int(-3)
        #expect(result == -30)
    }

    @Test("multiplying to produce .max")
    func multiplyToMax() {
        let result: MinorUnit = 1 * Storage.max
        #expect(result == .max)
    }

    @Test("multiplying past .max traps")
    func multiplyPastMaxTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = MinorUnit.max * Int(2)
        }
    }

    // MARK: - Negation

    @Test("negating a positive value")
    func negatePositive() {
        let result = -(MinorUnit(integerLiteral: 42))
        #expect(result == -42)
    }

    @Test("negating a negative value")
    func negateNegative() {
        let result = -(MinorUnit(integerLiteral: -42))
        #expect(result == 42)
    }

    @Test("negating zero is zero")
    func negateZero() {
        let result = -(MinorUnit.zero)
        #expect(result == .zero)
    }

    @Test("negating .min traps with overflow error")
    func negateMinProducesMax() async {
        await #expect(processExitsWith: .failure) {
            guard let pos = MinorUnit(exactly: Storage.min ) else { return }
            _ = -pos
        }
    }

    @Test("negating .max succeeds")
    func negateMaxProducesMin() async {
        await #expect(processExitsWith: .success) {
            _ = -(MinorUnit.max)
        }
    }

    @Test("negate() mutates in place")
    func negateMutatesInPlace() {
        var minorUnit: MinorUnit = 100
        minorUnit.negate()
        #expect(minorUnit == -100)
    }
}
