// Where a numbering system's separators come from. The 77 supported systems split into two real shapes,
// so they are modelled as two cases rather than one struct with sometimes-meaningless fields.
package enum SeparatorProvenance: Equatable, Hashable, Sendable {
    // The system forces its own separators onto every locale, as Arabic-Indic (`arab`) and extended
    // Arabic-Indic (`arabext`) impose `٫`/`٬` on top of any base locale. Carries those separators.
    case imposesOwn(NumberingSystemSymbols)

    // The system keeps the locale's own separators and swaps only the digits, as Devanagari and Bengali
    // do. Carries no separators, so it can never spawn a per-locale override.
    case reusesLocale
}
