import CLDRPluralParsing
import SwiftMoneyLocalization
import Testing

// CLDR publishes, beside every plural rule, the values that rule is meant to cover. Running those
// samples back through the rules is the ground truth for the evaluator, and needs no ICU: each
// sample must resolve to the category it was published under.
//
// The rule text is copied verbatim from CLDR 48's plurals.json. The locales are the five the library
// ships, plus Polish, Russian, Arabic and Welsh, which between them use every part of the grammar:
// modulus, ranges, not-equals, several or groups, and all six categories.
@Suite("Plural Rule Conformance Tests")
struct PluralRuleConformanceTests {

    static let locales: [(locale: String, rules: [(PluralCategory, String)])] = [
        (locale: "en", rules: [
            (.one, "i = 1 and v = 0 @integer 1"),
            (.other, " @integer 0, 2~16, 100, 1000, 10000, 100000, 1000000, … @decimal 0.0~1.5, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, …"),
        ]),
        (locale: "de", rules: [
            (.one, "i = 1 and v = 0 @integer 1"),
            (.other, " @integer 0, 2~16, 100, 1000, 10000, 100000, 1000000, … @decimal 0.0~1.5, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, …"),
        ]),
        (locale: "fr", rules: [
            (.one, "i = 0,1 @integer 0, 1 @decimal 0.0~1.5"),
            (.many, "e = 0 and i != 0 and i % 1000000 = 0 and v = 0 or e != 0..5 @integer 1000000, 1c6, 2c6, 3c6, 4c6, 5c6, 6c6, … @decimal 1.0000001c6, 1.1c6, 2.0000001c6, 2.1c6, 3.0000001c6, 3.1c6, …"),
            (.other, " @integer 2~17, 100, 1000, 10000, 100000, 1c3, 2c3, 3c3, 4c3, 5c3, 6c3, … @decimal 2.0~3.5, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 1.0001c3, 1.1c3, 2.0001c3, 2.1c3, 3.0001c3, 3.1c3, …"),
        ]),
        (locale: "ja", rules: [
            (.other, " @integer 0~15, 100, 1000, 10000, 100000, 1000000, … @decimal 0.0~1.5, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, …"),
        ]),
        (locale: "pl", rules: [
            (.one, "i = 1 and v = 0 @integer 1"),
            (.few, "v = 0 and i % 10 = 2..4 and i % 100 != 12..14 @integer 2~4, 22~24, 32~34, 42~44, 52~54, 62, 102, 1002, …"),
            (.many, "v = 0 and i != 1 and i % 10 = 0..1 or v = 0 and i % 10 = 5..9 or v = 0 and i % 100 = 12..14 @integer 0, 5~19, 100, 1000, 10000, 100000, 1000000, …"),
            (.other, "   @decimal 0.0~1.5, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, …"),
        ]),
        (locale: "ru", rules: [
            (.one, "v = 0 and i % 10 = 1 and i % 100 != 11 @integer 1, 21, 31, 41, 51, 61, 71, 81, 101, 1001, …"),
            (.few, "v = 0 and i % 10 = 2..4 and i % 100 != 12..14 @integer 2~4, 22~24, 32~34, 42~44, 52~54, 62, 102, 1002, …"),
            (.many, "v = 0 and i % 10 = 0 or v = 0 and i % 10 = 5..9 or v = 0 and i % 100 = 11..14 @integer 0, 5~19, 100, 1000, 10000, 100000, 1000000, …"),
            (.other, "   @decimal 0.0~1.5, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, …"),
        ]),
        (locale: "ar", rules: [
            (.zero, "n = 0 @integer 0 @decimal 0.0, 0.00, 0.000, 0.0000"),
            (.one, "n = 1 @integer 1 @decimal 1.0, 1.00, 1.000, 1.0000"),
            (.two, "n = 2 @integer 2 @decimal 2.0, 2.00, 2.000, 2.0000"),
            (.few, "n % 100 = 3..10 @integer 3~10, 103~110, 1003, … @decimal 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 103.0, 1003.0, …"),
            (.many, "n % 100 = 11..99 @integer 11~26, 111, 1011, … @decimal 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 111.0, 1011.0, …"),
            (.other, " @integer 100~102, 200~202, 300~302, 400~402, 500~502, 600, 1000, 10000, 100000, 1000000, … @decimal 0.1~0.9, 1.1~1.7, 10.1, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, …"),
        ]),
        (locale: "cy", rules: [
            (.zero, "n = 0 @integer 0 @decimal 0.0, 0.00, 0.000, 0.0000"),
            (.one, "n = 1 @integer 1 @decimal 1.0, 1.00, 1.000, 1.0000"),
            (.two, "n = 2 @integer 2 @decimal 2.0, 2.00, 2.000, 2.0000"),
            (.few, "n = 3 @integer 3 @decimal 3.0, 3.00, 3.000, 3.0000"),
            (.many, "n = 6 @integer 6 @decimal 6.0, 6.00, 6.000, 6.0000"),
            (.other, " @integer 4, 5, 7~20, 100, 1000, 10000, 100000, 1000000, … @decimal 0.1~0.9, 1.1~1.7, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, …"),
        ]),
    ]

    @Test("Every CLDR sample resolves to the category it is published under", arguments: locales)
    func samplesResolveToTheirOwnCategory(_ row: (locale: String, rules: [(PluralCategory, String)])) throws {
        var rules: [PluralCategory: PluralRule] = [:]
        var samples: [(PluralCategory, PluralSample)] = []

        for (category, text) in row.rules {
            let parsed = try PluralRuleText(parsing: text)
            parsed.rule.map { rules[category] = $0 }
            samples += parsed.samples.map { (category, $0) }
        }

        #expect(!samples.isEmpty, "\(row.locale) should publish samples")

        for (category, sample) in samples {
            let resolved = Self.category(of: sample, by: rules)
            #expect(resolved == category, "\(row.locale) \(sample): resolved \(resolved), published \(category)")
        }
    }

    // CLDR resolves a category by taking the first rule that holds, and `other` when none does.
    static func category(of sample: PluralSample, by rules: [PluralCategory: PluralRule]) -> PluralCategory {
        let operands = PluralOperandValues(minorUnits: sample.minorUnits, unitScale: sample.unitScale)

        return PluralCategory.allCases.first { rules[$0]?.matches(operands) == true } ?? .other
    }
}
