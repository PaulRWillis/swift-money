import Foundation
import SwiftMoney
import Testing

// MARK: - Initialisation

@Suite("CurrencyRegistry — Initialisation")
struct CurrencyRegistry_InitialisationTests {

    @Test("Empty registry has count 0")
    func emptyCount() {
        let registry = CurrencyRegistry()
        #expect(registry.count == 0)
    }

    @Test("Empty registry returns nil for any lookup")
    func emptyLookup() {
        let registry = CurrencyRegistry()
        #expect(registry.minimalQuantisation(for: "GBP") == nil)
    }

    @Test("isoStandard is non-empty")
    func isoStandardNonEmpty() {
        #expect(CurrencyRegistry.isoStandard.count > 150)
    }

    @Test("isoStandard spot-checks known currencies", arguments: [
        ("GBP", 100 as Int64),
        ("USD", 100),
        ("EUR", 100),
        ("CHF", 100),
        ("JPY", 1),
        ("KWD", 1000),
        ("BHD", 1000),
        ("OMR", 1000),
        ("TND", 1000),
        ("CLF", 10000),
        ("UYW", 10000),
        ("MGA", 100),
        ("MRU", 100),
        ("AUD", 100),
        ("CAD", 100),
        ("NZD", 100),
        ("SEK", 100),
        ("NOK", 100),
        ("DKK", 100),
        ("BIF", 1),
        ("KRW", 1),
        ("VND", 1),
        ("XAF", 1),
        ("XOF", 1),
        ("XPF", 1),
    ] as [(String, Int64)])
    func isoStandardSpotCheck(code: String, expectedQuantisation: Int64) {
        let result = CurrencyRegistry.isoStandard.minimalQuantisation(for: CurrencyCode(code))
        #expect(result == MinimalQuantisation(expectedQuantisation))
    }
}

// MARK: - Registration (Generic)

@Suite("CurrencyRegistry — Generic Registration")
struct CurrencyRegistry_GenericRegistrationTests {

    @Test("register adds currency type")
    func registerCurrencyType() {
        var registry = CurrencyRegistry()
        registry.register(TST_100.self)
        #expect(registry.minimalQuantisation(for: "TST_100") == 100)
    }

    @Test("registering same currency twice is idempotent")
    func registerIdempotent() {
        var registry = CurrencyRegistry()
        registry.register(TST_100.self)
        registry.register(TST_100.self)
        #expect(registry.count == 1)
        #expect(registry.minimalQuantisation(for: "TST_100") == 100)
    }

    @Test("register multiple currency types")
    func registerMultiple() {
        var registry = CurrencyRegistry()
        registry.register(TST_1.self)
        registry.register(TST_100.self)
        registry.register(TST_100_000_000.self)
        #expect(registry.count == 3)
    }
}

// MARK: - Registration (Non-Generic)

@Suite("CurrencyRegistry — Non-Generic Registration")
struct CurrencyRegistry_NonGenericRegistrationTests {

    @Test("register with code and minimalQuantisation")
    func registerCodeAndQuantisation() {
        var registry = CurrencyRegistry()
        registry.register(code: "XBT", minimalQuantisation: 100_000_000)
        #expect(registry.minimalQuantisation(for: "XBT") == 100_000_000)
    }

    @Test("register overwrites existing entry")
    func registerOverwrite() {
        var registry = CurrencyRegistry()
        registry.register(code: "GBP", minimalQuantisation: 100)
        registry.register(code: "GBP", minimalQuantisation: 1)
        #expect(registry.count == 1)
        #expect(registry.minimalQuantisation(for: "GBP") == 1)
    }
}

// MARK: - Lookup

@Suite("CurrencyRegistry — Lookup")
struct CurrencyRegistry_LookupTests {

    @Test("Returns nil for unregistered code")
    func unregisteredCode() {
        #expect(CurrencyRegistry.isoStandard.minimalQuantisation(for: "ZZZZZ") == nil)
    }

    @Test("Lookup is case-sensitive")
    func caseSensitive() {
        #expect(CurrencyRegistry.isoStandard.minimalQuantisation(for: "gbp") == nil)
        #expect(CurrencyRegistry.isoStandard.minimalQuantisation(for: "GBP") == 100)
    }
}

// MARK: - Count

@Suite("CurrencyRegistry — Count")
struct CurrencyRegistry_CountTests {

    @Test("Empty registry count is 0")
    func emptyZero() {
        #expect(CurrencyRegistry().count == 0)
    }

    @Test("Count after registrations")
    func countAfterRegistration() {
        var registry = CurrencyRegistry()
        registry.register(TST_1.self)
        registry.register(TST_100.self)
        registry.register(TST_100_000_000.self)
        #expect(registry.count == 3)
    }

    @Test("Count unchanged after duplicate registration")
    func countAfterDuplicate() {
        var registry = CurrencyRegistry()
        registry.register(TST_1.self)
        registry.register(TST_100.self)
        registry.register(TST_100_000_000.self)
        registry.register(TST_100.self)
        #expect(registry.count == 3)
    }
}

// MARK: - asResolver()

@Suite("CurrencyRegistry — Resolver")
struct CurrencyRegistry_ResolverTests {

    @Test("Resolver returns same value as direct lookup")
    func resolverMatchesLookup() {
        let registry = CurrencyRegistry.isoStandard
        let resolver = registry.asResolver()
        #expect(resolver("GBP") == registry.minimalQuantisation(for: "GBP"))
        #expect(resolver("JPY") == registry.minimalQuantisation(for: "JPY"))
        #expect(resolver("ZZZZZ") == registry.minimalQuantisation(for: "ZZZZZ"))
    }

    @Test("Resolver captures snapshot — mutations after capture have no effect")
    func resolverSnapshotSemantics() {
        var registry = CurrencyRegistry()
        registry.register(code: "AAA", minimalQuantisation: 1)
        let resolver = registry.asResolver()

        // Mutate registry after capturing
        registry.register(code: "BBB", minimalQuantisation: 100)

        #expect(resolver("AAA") == 1)
        #expect(resolver("BBB") == nil)  // Not in the snapshot
    }
}

// MARK: - Equatable / Hashable

@Suite("CurrencyRegistry — Equatable & Hashable")
struct CurrencyRegistry_EquatableHashableTests {

    @Test("Two empty registries are equal")
    func emptyEqual() {
        #expect(CurrencyRegistry() == CurrencyRegistry())
    }

    @Test("Registries with same entries are equal regardless of insertion order")
    func sameEntriesEqual() {
        var a = CurrencyRegistry()
        a.register(TST_1.self)
        a.register(TST_100.self)

        var b = CurrencyRegistry()
        b.register(TST_100.self)
        b.register(TST_1.self)

        #expect(a == b)
    }

    @Test("Extra entry makes registries unequal")
    func extraEntryNotEqual() {
        var a = CurrencyRegistry()
        a.register(TST_1.self)

        var b = CurrencyRegistry()
        b.register(TST_1.self)
        b.register(TST_100.self)

        #expect(a != b)
    }

    @Test("Equal registries have same hash value")
    func equalHashValues() {
        var a = CurrencyRegistry()
        a.register(TST_1.self)
        a.register(TST_100.self)

        var b = CurrencyRegistry()
        b.register(TST_100.self)
        b.register(TST_1.self)

        #expect(a.hashValue == b.hashValue)
    }
}

// MARK: - Codable Integration

@Suite("CurrencyRegistry — Codable Integration")
struct CurrencyRegistry_CodableIntegrationTests {

    @Test("AnyMoney round-trip with registry resolver")
    func anyMoneyRoundTrip() throws {
        let original = Money<GBP>(minorUnits: 12550).erased

        let encoder = JSONEncoder()
        encoder.anyMoneyEncodingStrategy = .object(amount: .majorUnits)

        let decoder = JSONDecoder()
        decoder.anyMoneyDecodingStrategy = .object(
            amount: .majorUnits,
            resolver: CurrencyRegistry.isoStandard.asResolver()
        )

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AnyMoney.self, from: data)
        #expect(decoded == original)
    }

    @Test("MoneyBag round-trip with registry resolver")
    func moneyBagRoundTrip() throws {
        let original = MoneyBag()
            .adding(Money<GBP>(minorUnits: 500))
            .adding(Money<USD>(minorUnits: 1000))

        let encoder = JSONEncoder()
        encoder.moneyBagEncodingStrategy = .dictionary(amount: .minorUnits)

        let decoder = JSONDecoder()
        decoder.moneyBagDecodingStrategy = .dictionary(
            amount: .minorUnits,
            resolver: CurrencyRegistry.isoStandard.asResolver()
        )

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MoneyBag.self, from: data)
        #expect(decoded == original)
    }

    @Test("Decoding fails for unknown currency code")
    func decodingFailsForUnknownCode() throws {
        let json = #"{"currencyCode":"UNKNOWN","amount":5.0}"#
        let data = try #require(json.data(using: .utf8))

        let decoder = JSONDecoder()
        decoder.anyMoneyDecodingStrategy = .object(
            amount: .majorUnits,
            resolver: CurrencyRegistry.isoStandard.asResolver()
        )

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(AnyMoney.self, from: data)
        }
    }
}
