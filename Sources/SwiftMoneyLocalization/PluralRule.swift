/// A locale's condition for one plural category, as CLDR writes it: `or` between groups of
/// relations, `and` within each group.
///
/// No rule holds for every amount. CLDR leaves the condition for `other` blank, so that category is a
/// fallback rather than a rule.
package struct PluralRule: Equatable, Sendable {
    /// The groups of relations, any one of which satisfies the rule in full.
    package let orOfAndGroups: NonEmpty<NonEmpty<PluralRelation>>

    /// Creates a rule that holds when any one of `orOfAndGroups` holds in full.
    package init(orOfAndGroups: NonEmpty<NonEmpty<PluralRelation>>) {
        self.orOfAndGroups = orOfAndGroups
    }

    /// Returns whether an amount's operands satisfy this rule.
    package func matches(_ operands: PluralOperandValues) -> Bool {
        orOfAndGroups.contains { group in
            group.allSatisfy { $0.matches(operands) }
        }
    }
}
