import SwiftMoneyLocalization

// One language's plural rules in the shape the packed table holds them: the language key already pooled,
// the rules in the order CLDR resolves them (a category with no rule is left out, taking `other`).
struct PackedPluralLanguage {
    let key: StringRef
    let rules: [(PluralCategory, PluralRule)]
}
