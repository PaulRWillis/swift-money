import SwiftMoneyLocalization
import Testing

@Suite("CurrencyFullName Tests")
struct CurrencyFullNameTests {

    // English names the pound two ways.
    static let pound = CurrencyFullName(other: "British pounds", byCategory: [.one: "British pound"])

    // German names the dollar once, and CLDR publishes no other form for it.
    static let dollar = CurrencyFullName(other: "US-Dollar")

    @Test("A category with its own name uses it")
    func ownNameIsUsed() {
        #expect(Self.pound.name(for: .one) == "British pound")
        #expect(Self.pound.name(for: .other) == "British pounds")
    }

    @Test("A category with no name of its own falls back to the one every locale publishes")
    func missingNameFallsBack() {
        #expect(Self.pound.name(for: .many) == "British pounds")
        #expect(Self.dollar.name(for: .one) == "US-Dollar")
        #expect(Self.dollar.name(for: .other) == "US-Dollar")
    }
}
