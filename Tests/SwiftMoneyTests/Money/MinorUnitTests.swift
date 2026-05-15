import Foundation
import Testing
import SwiftMoney

@Suite("MinorUnit")
struct MinorUnitTests {

    // MARK: - Failable Initialisation

    @Test("init exactly accepts zero")
    func exactlyAcceptsZero() throws {
        let mu = try #require(MinorUnit(exactly: Int64(0)))
        #expect(Int64(mu) == 0)
    }

    @Test("init exactly accepts positive values")
    func exactlyAcceptsPositive() throws {
        let mu = try #require(MinorUnit(exactly: Int64(150)))
        #expect(Int64(mu) == 150)
    }

    @Test("init exactly accepts negative values")
    func exactlyAcceptsNegative() throws {
        let mu = try #require(MinorUnit(exactly: Int64(-150)))
        #expect(Int64(mu) == -150)
    }

    @Test("init exactly accepts Int64.max")
    func exactlyAcceptsInt64Max() throws {
        let mu = try #require(MinorUnit(exactly: Int64.max))
        #expect(Int64(mu) == .max)
    }

    @Test("init exactly accepts Int64.min + 1")
    func exactlyAcceptsInt64MinPlusOne() throws {
        let mu = try #require(MinorUnit(exactly: Int64.min + 1))
        #expect(Int64(mu) == .min + 1)
    }

    @Test("init exactly rejects Int64.min")
    func exactlyRejectsInt64Min() {
        #expect(MinorUnit(exactly: Int64.min) == nil)
    }

    @Test("init exactly accepts Int that fits in Int64")
    func exactlyAcceptsInt() throws {
        let mu = try #require(MinorUnit(exactly: 42 as Int))
        #expect(Int64(mu) == 42)
    }

    @Test("init exactly rejects UInt64 that overflows Int64")
    func exactlyRejectsOverflowingUInt64() {
        #expect(MinorUnit(exactly: UInt64.max) == nil)
    }

    @Test("init exactly accepts Int128 that fits")
    func exactlyAcceptsInt128() throws {
        let mu = try #require(MinorUnit(exactly: Int128(1000)))
        #expect(Int64(mu) == 1000)
    }

    @Test("init exactly rejects Int128 that overflows Int64")
    func exactlyRejectsOverflowingInt128() {
        #expect(MinorUnit(exactly: Int128.max) == nil)
    }

    // MARK: - Int64 Conversion

    @Test("Int64 init produces the stored value")
    func int64ConversionProducesStoredValue() {
        let mu: MinorUnit = 42
        #expect(Int64(mu) == 42)
    }

    @Test("Int64 round-trips through MinorUnit")
    func int64RoundTrips() throws {
        let original: Int64 = -9_223_372_036_854_775_807
        let mu = try #require(MinorUnit(exactly: original))
        #expect(Int64(mu) == original)
    }

    // MARK: - ExpressibleByIntegerLiteral

    @Test("Integer literal produces correct value")
    func integerLiteral() {
        let mu: MinorUnit = 100
        #expect(Int64(mu) == 100)
    }

    @Test("Negative integer literal produces correct value")
    func negativeIntegerLiteral() {
        let mu: MinorUnit = -50
        #expect(Int64(mu) == -50)
    }

    // MARK: - Equatable

    @Test("Equal values compare as equal")
    func equalValuesAreEqual() {
        let a: MinorUnit = 100
        let b: MinorUnit = 100
        #expect(a == b)
    }

    @Test("Different values compare as not equal")
    func differentValuesNotEqual() {
        let a: MinorUnit = 100
        let b: MinorUnit = 200
        #expect(a != b)
    }

    // MARK: - Comparable

    @Test("Smaller value is less than larger value")
    func lessThan() {
        let negOne: MinorUnit = -1
        let zero: MinorUnit = 0
        let one: MinorUnit = 1
        #expect(negOne < zero)
        #expect(zero < one)
    }

    @Test("Values sort correctly")
    func sorting() {
        let values: [MinorUnit] = [3, -1, 0, 2]
        let sorted = values.sorted()
        let expected: [MinorUnit] = [-1, 0, 2, 3]
        #expect(sorted == expected)
    }

    // MARK: - Hashable

    @Test("Equal values produce the same hash")
    func equalValuesSameHash() {
        let a: MinorUnit = 100
        let b: MinorUnit = 100
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used as a Set element")
    func usableInSet() {
        let set: Set<MinorUnit> = [1, 2, 2, 3]
        #expect(set.count == 3)
    }

    @Test("Can be used as a Dictionary key")
    func usableAsDictionaryKey() {
        var dict: [MinorUnit: String] = [:]
        dict[100] = "one pound"
        #expect(dict[100] == "one pound")
    }

    // MARK: - CustomStringConvertible

    @Test("description equals the Int64 string representation")
    func descriptionIsInt64String() {
        let hundred: MinorUnit = 100
        let negFifty: MinorUnit = -50
        let zero: MinorUnit = 0
        #expect(hundred.description == "100")
        #expect(negFifty.description == "-50")
        #expect(zero.description == "0")
    }

    // MARK: - Codable

    @Test("Encodes to a JSON integer")
    func encodesToJsonInteger() throws {
        let mu: MinorUnit = 150
        let data = try JSONEncoder().encode(mu)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json == "150")
    }

    @Test("Decodes from a JSON integer")
    func decodesFromJsonInteger() throws {
        let json = "150"
        let data = try #require(json.data(using: .utf8))
        let mu = try JSONDecoder().decode(MinorUnit.self, from: data)
        let expected: MinorUnit = 150
        #expect(mu == expected)
    }

    @Test("Round-trips through JSON")
    func roundTrips() throws {
        let original: MinorUnit = -9_223_372_036_854_775_807
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MinorUnit.self, from: data)
        #expect(decoded == original)
    }

    @Test("Decoding Int64.min throws DecodingError")
    func decodingInt64MinThrows() throws {
        let json = "-9223372036854775808"
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MinorUnit.self, from: data)
        }
    }

    // MARK: - Static Properties

    @Test("zero is 0")
    func zeroIsZero() {
        #expect(Int64(MinorUnit.zero) == 0)
    }

    @Test("max is Int64.max")
    func maxIsInt64Max() {
        #expect(Int64(MinorUnit.max) == .max)
    }

    @Test("min is Int64.min + 1")
    func minIsInt64MinPlusOne() {
        #expect(Int64(MinorUnit.min) == .min + 1)
    }
}
