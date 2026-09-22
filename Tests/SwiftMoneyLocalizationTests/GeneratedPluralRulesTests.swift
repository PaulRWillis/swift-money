import SwiftMoneyLocalization
import Testing

// The rules come from CLDR through the generator, so these check that what it wrote says what CLDR
// says, category by category, for the languages the library ships.
@Suite("Generated Plural Rules Tests")
struct GeneratedPluralRulesTests {

    // The rules the generator packed into the blob, decoded once for these checks.
    static let rules = MoneyLocalization.cldr.pluralRules.allRules()

    static func yen(_ minorUnits: Int64) -> PluralOperandValues {
        PluralOperandValues(minorUnits: minorUnits, unitScale: 1)
    }

    static func pounds(_ minorUnits: Int64) -> PluralOperandValues {
        PluralOperandValues(minorUnits: minorUnits, unitScale: 100)
    }

    @Test("Every shipped language has rules, Japanese having none at all", arguments: ["en", "de", "fr", "ja"])
    func everyLanguageIsCovered(_ language: String) throws {
        let rules = try #require(Self.rules[language])

        #expect(rules.isEmpty == (language == "ja"))
    }

    @Test("A region takes no rules of its own")
    func regionsAreNotListed() {
        #expect(Self.rules["en-GB"] == nil)
    }

    @Test("English and German call one whole unit `one` and everything else `other`", arguments: ["en", "de"])
    func oneWholeUnitIsSingular(_ language: String) throws {
        let one = try #require(Self.rules[language]?[.one])

        #expect(one.matches(Self.yen(1)))
        #expect(!one.matches(Self.yen(2)))
        #expect(!one.matches(Self.pounds(1_00)))   // 1.00 shows fraction digits, so it is not `one`
    }

    @Test("French calls zero and one `one`, and whole millions `many`")
    func frenchHasItsOwnRules() throws {
        let french = try #require(Self.rules["fr"])
        let one = try #require(french[.one])
        let many = try #require(french[.many])

        #expect(one.matches(Self.yen(0)))
        #expect(one.matches(Self.yen(1)))
        #expect(!one.matches(Self.yen(2)))
        #expect(many.matches(Self.yen(1_000_000)))
        #expect(!many.matches(Self.yen(1)))
    }

    @Test("No language has a rule for other, which is the fallback", arguments: ["en", "de", "fr", "ja"])
    func otherIsNeverARule(_ language: String) throws {
        let rules = try #require(Self.rules[language])

        #expect(rules[.other] == nil)
    }
}
