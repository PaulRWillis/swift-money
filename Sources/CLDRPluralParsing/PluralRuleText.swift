import SwiftMoneyLocalization

/// One category's plural rule as CLDR publishes it: a condition, then the values CLDR samples it
/// with.
package struct PluralRuleText {
    /// The rule the condition describes, or `nil` when the text carries no condition, as CLDR's
    /// `other` category does not.
    package let rule: PluralRule?

    /// The sample values, with any no monetary amount can take left out.
    package let samples: [PluralSample]

    /// Creates the rule and samples from one entry of CLDR's plural rule data, such as
    /// `"i = 1 and v = 0 @integer 1"`.
    ///
    /// - Throws: ``PluralRuleParseError/malformedSamples(_:)`` when the sample lists are outside
    ///   CLDR's grammar, and the errors of ``PluralRule/init(parsing:)`` for the condition.
    package init(parsing text: String) throws(PluralRuleParseError) {
        let condition = text.prefix { $0 != "@" }

        rule = condition.allSatisfy(\.isWhitespace) ? nil : try PluralRule(parsing: String(condition))
        samples = try Self.samples(in: text.dropFirst(condition.count))
    }

    private static func samples(in text: Substring) throws(PluralRuleParseError) -> [PluralSample] {
        do {
            return try PluralSampleGrammar.sections.parse(text)
        } catch {
            throw .malformedSamples(String(describing: error))
        }
    }
}
