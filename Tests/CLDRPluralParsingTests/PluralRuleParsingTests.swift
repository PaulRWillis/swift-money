import CLDRPluralParsing
import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// The conditions come verbatim from CLDR 48's plurals.json, so a locale's real rule text is what the
// parser is held to.
@Suite("Plural Rule Parsing Tests")
struct PluralRuleParsingTests {

    static func yen(_ minorUnits: Int64) -> PluralOperandValues {
        PluralOperandValues(minorUnits: minorUnits, unitScale: 1)
    }

    static func pounds(_ minorUnits: Int64) -> PluralOperandValues {
        PluralOperandValues(minorUnits: minorUnits, unitScale: 100)
    }

    @Test("A condition of two relations parses to an and group of both")
    func andGroupParsesStructurally() throws {
        let rule = try PluralRule(parsing: "i = 1 and v = 0")

        let integerPartIsOne = PluralRelation(operand: .integerPart, comparison: .equals(NonEmpty(PluralRange(1))))
        let noFractionDigits = PluralRelation(operand: .fractionDigitCount, comparison: .equals(NonEmpty(PluralRange(0))))
        let expected = PluralRule(orOfAndGroups: NonEmpty(NonEmpty(integerPartIsOne, [noFractionDigits])))

        #expect(rule == expected)
    }

    // French's `one`. A comma list with no spaces around it.
    @Test("A comma separated value list matches any of its values")
    func commaListMatchesAnyValue() throws {
        let rule = try PluralRule(parsing: "i = 0,1")

        #expect(rule.matches(Self.yen(0)))
        #expect(rule.matches(Self.yen(1)))
        #expect(!rule.matches(Self.yen(2)))
    }

    // Arabic's `few`.
    @Test("A modulus and a range parse together")
    func modulusAndRangeParse() throws {
        let rule = try PluralRule(parsing: "n % 100 = 3..10")

        #expect(rule.matches(Self.yen(103)))
        #expect(!rule.matches(Self.yen(102)))
        #expect(!rule.matches(Self.pounds(1_03)))   // 1.03 carries a fraction, so n matches nothing
    }

    // Polish's `few`, which needs three relations and a not-equals.
    @Test("A three relation condition parses, not equals included")
    func threeRelationsParse() throws {
        let rule = try PluralRule(parsing: "v = 0 and i % 10 = 2..4 and i % 100 != 12..14")

        #expect(rule.matches(Self.yen(22)))
        #expect(!rule.matches(Self.yen(12)))
        #expect(!rule.matches(Self.pounds(22_00)))   // pounds always show two fraction digits
    }

    // Polish's `many`, which is three and groups joined by or.
    @Test("Or joins whole and groups, not single relations")
    func orJoinsAndGroups() throws {
        let rule = try PluralRule(parsing: "v = 0 and i != 1 and i % 10 = 0..1 or v = 0 and i % 10 = 5..9 or v = 0 and i % 100 = 12..14")

        #expect(rule.matches(Self.yen(0)))
        #expect(rule.matches(Self.yen(5)))
        #expect(rule.matches(Self.yen(12)))
        #expect(!rule.matches(Self.yen(1)))
        #expect(!rule.matches(Self.yen(2)))
    }

    // French's `many`, the reason the compact exponent operand exists.
    @Test("A condition reading the compact exponent parses")
    func compactExponentParses() throws {
        let rule = try PluralRule(parsing: "e = 0 and i != 0 and i % 1000000 = 0 and v = 0 or e != 0..5")

        #expect(rule.matches(Self.yen(1_000_000)))
        #expect(!rule.matches(Self.yen(1)))
        #expect(!rule.matches(Self.pounds(1_000_000_00)))
    }

    @Test("CLDR's mod spelling means the same as %")
    func modSpellingParses() throws {
        let rule = try PluralRule(parsing: "i mod 10 = 2")

        #expect(rule.matches(Self.yen(12)))
        #expect(!rule.matches(Self.yen(13)))
    }

    @Test("Space around a condition is ignored")
    func surroundingSpaceIsIgnored() throws {
        let rule = try PluralRule(parsing: "  n = 1  ")

        #expect(rule.matches(Self.yen(1)))
    }

    // The generator writes each parsed rule back out as Swift source, so every part of a rule has to
    // be readable.
    @Test("A parsed rule can be read back part by part")
    func parsedRuleReadsBack() throws {
        let rule = try PluralRule(parsing: "i % 10 = 2..4")
        let relation = rule.orOfAndGroups.first.first

        #expect(relation.operand == .integerPart)
        #expect(relation.modulus.map(Int.init) == 10)
        #expect(relation.comparison == .equals(NonEmpty(PluralRange(2 ... 4))))
    }

    @Test("A relation this engine does not model is named as unsupported", arguments: [
        "n within 0..2",
        "n is 1",
        "n is not 1",
        "n in 1,2",
        "n not in 1,2",
    ])
    func unmodelledRelationsAreNamed(_ condition: String) throws {
        let error = try #require(throws: PluralRuleParseError.self) {
            try PluralRule(parsing: condition)
        }

        guard case .unsupportedRelation = error else {
            Issue.record("expected an unsupported relation, got \(error)")
            return
        }
    }

    @Test("Text outside CLDR's grammar is rejected", arguments: [
        "",
        "x = 1",
        "i = ",
        "i = 1 and",
        "i % 0 = 1",
        "i = 3..1",
        "i = 1 @integer 1",
    ])
    func malformedConditionsAreRejected(_ condition: String) throws {
        let error = try #require(throws: PluralRuleParseError.self) {
            try PluralRule(parsing: condition)
        }

        guard case .malformedCondition = error else {
            Issue.record("expected a malformed condition, got \(error)")
            return
        }
    }
}
