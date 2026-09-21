import SwiftMoneyCore
import SwiftMoneyLocalization

// One locale's data in the shape the packed tables hold it: strings already pooled, patterns already
// interned, currencies already in the order a binary search needs. Read straight from CLDR, so the
// records here are what the sections are written from and nothing decides anything later.
struct PackedLocale {
    let key: StringRef
    let numberFormat: NumberFormat

    // Sorted by code, because the runtime finds a currency in them by binary search.
    let displays: [Display]
    let fullNames: [FullName]

    // The locale's separators and grouping, and where its patterns sit among the interned ones.
    struct NumberFormat {
        let decimalSeparator: StringRef
        let groupingSeparator: StringRef
        let minusSign: StringRef
        let isoCodeSpacing: StringRef
        let primaryGroupingSize: UInt8
        let secondaryGroupingSize: UInt8
        let fullNameSpacing: Spacing
        let patternIndex: UInt16
        let fullNamePatternIndex: UInt16
    }

    // One currency's symbols in this locale, each with the spacing CLDR resolves for it.
    struct Display {
        let code: CurrencyCode
        let standardSymbol: StringRef
        let standardSpacing: StringRef
        let narrowSymbol: StringRef
        let narrowSpacing: StringRef
    }

    // What this locale calls one currency: the name it always publishes, and any category that names it
    // differently.
    struct FullName {
        let code: CurrencyCode
        let other: StringRef
        let overrides: [(category: PluralCategory, name: StringRef)]
    }
}
