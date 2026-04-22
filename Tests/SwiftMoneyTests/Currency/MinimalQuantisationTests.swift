import Testing
import SwiftMoney

@Suite("MinimalQuantisation")
struct MinimalQuantisationTests {

    // MARK: - Initialisation

    @Test("init accepts 1 (no minor units, e.g. JPY)")
    func initAcceptsOne() {
        let q = MinimalQuantisation(1)
        #expect(q.int64Value == 1)
    }

    @Test("init accepts 100 (e.g. GBP, USD, EUR)")
    func initAcceptsOneHundred() {
        let q = MinimalQuantisation(100)
        #expect(q.int64Value == 100)
    }

    @Test("init accepts 100_000_000 (e.g. BTC satoshis)")
    func initAcceptsBitcoinSatoshis() {
        let q = MinimalQuantisation(100_000_000)
        #expect(q.int64Value == 100_000_000)
    }

    @Test("init accepts Int64.max")
    func initAcceptsInt64Max() {
        let q = MinimalQuantisation(.max)
        #expect(q.int64Value == .max)
    }

    @Test("init traps on 0")
    func initZeroTraps() {
        #expect(processExitsWith: .failure) {
            _ = MinimalQuantisation(0)
        }
    }

    @Test("init traps on negative values")
    func initNegativeTraps() {
        #expect(processExitsWith: .failure) {
            _ = MinimalQuantisation(-1)
        }
    }

    @Test("init traps on Int64.min")
    func initMinTraps() {
        #expect(processExitsWith: .failure) {
            _ = MinimalQuantisation(.min)
        }
    }

    // MARK: - ExpressibleByIntegerLiteral

    @Test("Integer literal produces correct value")
    func integerLiteral() {
        let q: MinimalQuantisation = 100
        #expect(q.int64Value == 100)
    }

    // MARK: - Int64 conversion

    @Test("Int64 init from MinimalQuantisation produces correct value")
    func int64InitFromQuantisation() {
        let q = MinimalQuantisation(100)
        #expect(Int64(q) == 100)
    }

    @Test("Int64(q) equals q.int64Value")
    func int64InitEqualsInt64Value() {
        let q = MinimalQuantisation(1_000)
        #expect(Int64(q) == q.int64Value)
    }

    // MARK: - Equatable

    @Test("Equal quantisations compare as equal")
    func equalQuantisationsAreEqual() {
        let a = MinimalQuantisation(100)
        let b = MinimalQuantisation(100)
        #expect(a == b)
    }

    @Test("Different quantisations compare as not equal")
    func differentQuantisationsNotEqual() {
        #expect(MinimalQuantisation(100) != MinimalQuantisation(1))
    }

    @Test("Quantisation equals integer-literal form")
    func quantisationEqualsLiteral() {
        let q = MinimalQuantisation(100)
        let literal: MinimalQuantisation = 100
        #expect(q == literal)
    }

    // MARK: - Hashable

    @Test("Equal quantisations produce the same hash")
    func equalQuantisationsSameHash() {
        let a = MinimalQuantisation(100)
        let b = MinimalQuantisation(100)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("MinimalQuantisation can be used as a Set element")
    func usableInSet() {
        let set: Set<MinimalQuantisation> = [1, 100, 100, 100_000_000]
        #expect(set.count == 3)
    }

    @Test("MinimalQuantisation can be used as a Dictionary key")
    func usableAsDictionaryKey() {
        var dict: [MinimalQuantisation: String] = [:]
        dict[MinimalQuantisation(100)] = "cents"
        #expect(dict[100] == "cents")
    }

    // MARK: - CustomStringConvertible

    @Test("description equals the Int64 string representation")
    func descriptionIsInt64String() {
        #expect(MinimalQuantisation(100).description == "100")
        #expect(MinimalQuantisation(1).description == "1")
        #expect(MinimalQuantisation(100_000_000).description == "100000000")
    }

    // MARK: - Codable

    @Test("Encodes to a JSON integer")
    func encodesToJsonInteger() throws {
        let q = MinimalQuantisation(100)
        let data = try JSONEncoder().encode(q)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json == "100")
    }

    @Test("Decodes from a JSON integer")
    func decodesFromJsonInteger() throws {
        let json = "100"
        let data = try #require(json.data(using: .utf8))
        let q = try JSONDecoder().decode(MinimalQuantisation.self, from: data)
        #expect(q == MinimalQuantisation(100))
    }

    @Test("Round-trips through JSON")
    func roundTrips() throws {
        let original = MinimalQuantisation(100_000_000)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MinimalQuantisation.self, from: data)
        #expect(decoded == original)
    }

    @Test("Decoding 0 throws DecodingError")
    func decodingZeroThrows() throws {
        let json = "0"
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MinimalQuantisation.self, from: data)
        }
    }

    @Test("Decoding a negative value throws DecodingError")
    func decodingNegativeThrows() throws {
        let json = "-1"
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MinimalQuantisation.self, from: data)
        }
    }
}
