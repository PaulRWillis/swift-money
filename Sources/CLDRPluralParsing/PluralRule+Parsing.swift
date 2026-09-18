import SwiftMoneyLocalization

package extension PluralRule {
    /// Creates a rule from a locale's CLDR condition text, such as `"i = 1 and v = 0"`.
    ///
    /// - Parameter condition: One condition from CLDR's plural rule data, with its sample lists
    ///   already removed. Surrounding whitespace is ignored.
    /// - Throws: ``PluralRuleParseError/unsupportedRelation(_:)`` for a relation CLDR's grammar
    ///   allows but this engine does not model, and
    ///   ``PluralRuleParseError/malformedCondition(_:)`` for anything else it cannot read.
    init(parsing condition: String) throws(PluralRuleParseError) {
        if let word = PluralConditionGrammar.unmodelledRelation(in: condition) {
            throw .unsupportedRelation(word)
        }

        do {
            self.init(orOfAndGroups: try PluralConditionGrammar.condition.parse(condition))
        } catch {
            throw .malformedCondition(String(describing: error))
        }
    }
}
