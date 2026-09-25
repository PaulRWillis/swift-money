import SwiftMoneyCore
import SwiftMoneyLocalization

// One locale's tables as plain values, decided before a byte of it reaches the string pool.
//
// Deciding and packing are separate passes because a locale can turn out to be unrepresentable part
// of the way through. Were they one pass, the strings and patterns of a locale that then failed would
// already be in the pool with nothing pointing at them, and every pattern index after it would shift.
//
// The two arrays are held in the order their strings should reach the pool, which is not the order
// they are searched in: `pack` sorts the records afterwards.
struct LocaleTables {
    // What a locale calls one currency in symbol form, and the gap each form takes beside the digits.
    struct Display {
        let code: CurrencyCode
        let standardSymbol: String
        let standardSpacing: Spacing
        let narrowSymbol: String
        let narrowSpacing: Spacing
    }

    // What a locale calls one currency in words: the name CLDR always publishes, and any plural
    // category that words it differently.
    struct FullName {
        let code: CurrencyCode
        let other: String
        let overrides: [(category: PluralCategory, name: String)]
    }

    let decimalSeparator: String
    let groupingSeparator: String
    let minusSign: String
    let isoCodeSpacing: Spacing
    // The gap the standard pattern bakes in beside every symbol, glyph included.
    let symbolSpacing: Spacing
    let primaryGroupingSize: UInt8
    let secondaryGroupingSize: UInt8
    let fullNameSpacing: Spacing

    // How many whole digits the integer part needs before grouping shows; one for most locales.
    let minGroupingDigits: UInt8

    // The locale's ten digit glyphs concatenated, or nil when it writes the ASCII 0 to 9.
    let digits: String?

    // Swift source for the two interned tables, deduplicated by text when packed.
    let pattern: String
    let fullNamePattern: String

    let displays: [Display]
    let fullNames: [FullName]

    // Codes CLDR names in this locale that no currency can carry, reported rather than dropped in
    // silence.
    let unusableCurrencyCodes: Set<String>

    // The imposing systems this locale writes with separators of its own, differing from the system
    // default. Sorted by system name so the packed rows come out the same on any machine.
    let numberingOverrides: [NumberingOverride]

    // One imposing system's separators as this locale writes them, when they differ from the default.
    struct NumberingOverride {
        let system: String
        let decimalSeparator: String
        let groupingSeparator: String
        let minusSign: String
    }
}
