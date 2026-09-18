import CLDRPluralParsing
import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// The rule text comes verbatim from CLDR 48's plurals.json: a condition, then the sample values CLDR
// publishes for it.
@Suite("Plural Rule Text Tests")
struct PluralRuleTextTests {

    @Test("A condition and its samples are read from one line of rule text")
    func conditionAndSamplesAreRead() throws {
        let text = try PluralRuleText(parsing: "i = 1 and v = 0 @integer 1")

        #expect(text.rule != nil)
        #expect(text.samples.map(\.minorUnits) == [1])
        #expect(text.samples.map(\.unitScale) == [1])
    }

    // CLDR's `other` category, which has samples but no condition.
    @Test("Rule text with no condition has no rule")
    func noConditionMeansNoRule() throws {
        let text = try PluralRuleText(parsing: "   @decimal 0.0~1.5, 10.0, …")

        #expect(text.rule == nil)
        #expect(!text.samples.isEmpty)
    }

    @Test("An integer range covers every value in it")
    func integerRangeExpands() throws {
        let text = try PluralRuleText(parsing: "@integer 0, 2~16, 100")

        #expect(text.samples.map(\.minorUnits) == [0] + Array(2 ... 16) + [100])
        #expect(text.samples.allSatisfy { $0.unitScale == 1 })
    }

    @Test("A decimal range steps by one of the currency's smallest units")
    func decimalRangeExpands() throws {
        let text = try PluralRuleText(parsing: "@decimal 0.0~1.5")

        #expect(text.samples.count == 16)
        #expect(text.samples.map(\.minorUnits) == Array(0 ... 15))
        #expect(text.samples.allSatisfy { $0.unitScale == 10 })
    }

    @Test("The fraction digits a sample is written with fix its scale")
    func fractionDigitsFixTheScale() throws {
        let text = try PluralRuleText(parsing: "n = 1 @integer 1 @decimal 1.0, 1.00, 1.000")

        #expect(text.samples.map(\.unitScale) == [1, 10, 100, 1_000])
        #expect(text.samples.map(\.minorUnits) == [1, 10, 100, 1_000])
    }

    @Test("The ellipsis that ends a sample list is not a value", arguments: ["@integer 1, …", "@integer 1, ..."])
    func ellipsisIsNotASample(_ text: String) throws {
        let parsed = try PluralRuleText(parsing: text)

        #expect(parsed.samples.map(\.minorUnits) == [1])
    }

    // A monetary amount is never written in compact notation, so those samples cannot be one.
    @Test("Samples in compact notation are left out")
    func compactSamplesAreLeftOut() throws {
        let integers = try PluralRuleText(parsing: "@integer 1000000, 1c6, 2c6, …")
        let decimals = try PluralRuleText(parsing: "@decimal 1.0000001c6, 1.1c6")

        #expect(integers.samples.map(\.minorUnits) == [1_000_000])
        #expect(decimals.samples.isEmpty)
    }

    // CLDR publishes no sample this large, but a value that overflows the smallest units of an
    // amount is no more usable than one in compact notation.
    @Test("Samples beyond what one amount can hold are left out", arguments: [
        "@decimal 18446744073709551615.5",
        "@integer 9223372036854775808",
    ])
    func oversizedSamplesAreLeftOut(_ text: String) throws {
        let parsed = try PluralRuleText(parsing: text)

        #expect(parsed.samples.isEmpty)
    }

    @Test("Sample text outside CLDR's grammar is rejected", arguments: [
        "@integer",
        "@integer 1 2",
        "@decimal 0.0~1.50",
        "@integer 1 @integer 2",
        "@decimal 1.0 @integer 1",
    ])
    func malformedSamplesAreRejected(_ text: String) throws {
        let error = try #require(throws: PluralRuleParseError.self) {
            try PluralRuleText(parsing: text)
        }

        guard case .malformedSamples = error else {
            Issue.record("expected malformed samples, got \(error)")
            return
        }
    }

    @Test("A condition outside CLDR's grammar is still rejected by its own error")
    func malformedConditionKeepsItsError() throws {
        let error = try #require(throws: PluralRuleParseError.self) {
            try PluralRuleText(parsing: "i = @integer 1")
        }

        guard case .malformedCondition = error else {
            Issue.record("expected a malformed condition, got \(error)")
            return
        }
    }
}
