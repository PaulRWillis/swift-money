import Foundation
import Testing
import SwiftMoney

@Suite("DistributionParts")
struct DistributionPartsTests {

    // MARK: - Initialisation

    @Test("init accepts 1")
    func initAcceptsOne() {
        let parts = DistributionParts(1)
        #expect(parts.intValue == 1)
    }

    @Test("init accepts 3")
    func initAcceptsThree() {
        let parts = DistributionParts(3)
        #expect(parts.intValue == 3)
    }

    @Test("init accepts 100")
    func initAcceptsOneHundred() {
        let parts = DistributionParts(100)
        #expect(parts.intValue == 100)
    }

    @Test("init accepts Int.max")
    func initAcceptsIntMax() {
        let parts = DistributionParts(.max)
        #expect(parts.intValue == .max)
    }

    @Test("init traps on 0")
    func initZeroTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = DistributionParts(0)
        }
    }

    @Test("init traps on -1")
    func initNegativeOneTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = DistributionParts(-1)
        }
    }

    @Test("init traps on Int.min")
    func initIntMinTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = DistributionParts(.min)
        }
    }

    // MARK: - ExpressibleByIntegerLiteral

    @Test("Integer literal produces correct value")
    func integerLiteral() {
        let parts: DistributionParts = 3
        #expect(parts.intValue == 3)
    }

    // MARK: - Int conversion

    @Test("Int init from DistributionParts produces correct value")
    func intInitFromParts() {
        let parts = DistributionParts(3)
        #expect(Int(parts) == 3)
    }

    @Test("Int(parts) equals parts.intValue")
    func intInitEqualsIntValue() {
        let parts = DistributionParts(10)
        #expect(Int(parts) == parts.intValue)
    }

    // MARK: - Equatable

    @Test("Equal parts compare as equal")
    func equalPartsAreEqual() {
        let a = DistributionParts(3)
        let b = DistributionParts(3)
        #expect(a == b)
    }

    @Test("Different parts compare as not equal")
    func differentPartsNotEqual() {
        #expect(DistributionParts(3) != DistributionParts(5))
    }

    @Test("Parts equal integer-literal form")
    func partsEqualLiteral() {
        let parts = DistributionParts(3)
        let literal: DistributionParts = 3
        #expect(parts == literal)
    }

    // MARK: - Hashable

    @Test("Equal parts produce the same hash")
    func equalPartsSameHash() {
        let a = DistributionParts(3)
        let b = DistributionParts(3)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("DistributionParts can be used as a Set element")
    func usableInSet() {
        let set: Set<DistributionParts> = [1, 3, 3, 10]
        #expect(set.count == 3)
    }

    @Test("DistributionParts can be used as a Dictionary key")
    func usableAsDictionaryKey() {
        var dict: [DistributionParts: String] = [:]
        dict[DistributionParts(3)] = "three"
        #expect(dict[3] == "three")
    }

    // MARK: - Comparable

    @Test("Smaller parts compare as less than larger parts")
    func compareOrdering() {
        #expect(DistributionParts(1) < DistributionParts(3))
        #expect(DistributionParts(3) > DistributionParts(1))
        #expect(!(DistributionParts(3) < DistributionParts(3)))
    }

    @Test("Parts can be sorted")
    func sortableArray() {
        let parts: [DistributionParts] = [10, 1, 5, 3]
        let sorted = parts.sorted()
        #expect(sorted.map(\.intValue) == [1, 3, 5, 10])
    }

    // MARK: - CustomStringConvertible

    @Test("description returns the integer string representation",
          arguments: [
              (1,   "1"),
              (3,   "3"),
              (100, "100"),
          ])
    func description(value: Int, expected: String) {
        #expect(DistributionParts(value).description == expected)
    }

    // MARK: - Codable

    @Test("Encodes to a JSON integer")
    func encodesToJsonInteger() throws {
        let parts = DistributionParts(3)
        let data = try JSONEncoder().encode(parts)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json == "3")
    }

    @Test("Decodes from a JSON integer")
    func decodesFromJsonInteger() throws {
        let json = "3"
        let data = try #require(json.data(using: .utf8))
        let parts = try JSONDecoder().decode(DistributionParts.self, from: data)
        #expect(parts == DistributionParts(3))
    }

    @Test("Round-trips through JSON")
    func roundTrips() throws {
        let original = DistributionParts(100)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DistributionParts.self, from: data)
        #expect(decoded == original)
    }

    @Test("Decoding 0 throws DecodingError")
    func decodingZeroThrows() throws {
        let json = "0"
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(DistributionParts.self, from: data)
        }
    }

    @Test("Decoding a negative value throws DecodingError")
    func decodingNegativeThrows() throws {
        let json = "-1"
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(DistributionParts.self, from: data)
        }
    }
}
