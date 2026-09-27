import SwiftMoneyCore

// How a locale writes a currency's full name beside an amount, per plural category: the arrangement
// CLDR always publishes (`other`), plus any category that arranges it differently. A category equal to
// `other` is left out and resolves to it. A name never takes accounting parentheses and its negative is
// a plain minus, so one ``MoneyFormatAffixes`` per category is enough — unlike the symbol pattern.
package struct FullNameLayout: Equatable {
    package let other: MoneyFormatAffixes
    package let byCategory: [PluralCategory: MoneyFormatAffixes]

    package init(other: MoneyFormatAffixes, byCategory: [PluralCategory: MoneyFormatAffixes] = [:]) {
        self.other = other
        self.byCategory = byCategory
    }

    func affixes(for category: PluralCategory) -> MoneyFormatAffixes {
        byCategory[category] ?? other
    }
}
