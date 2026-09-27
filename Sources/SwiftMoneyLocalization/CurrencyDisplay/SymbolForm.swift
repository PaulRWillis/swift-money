/// Whether a currency symbol reads as a glyph or as letters where it sits next to the number.
///
/// CLDR arranges a symbol differently depending on this: a glyph (`"€"`, `"£"`, `"kr"`) keeps the
/// locale's ordinary placement, but a symbol with a letter touching the number (an ISO code, `"US$"`,
/// `"F CFA"`) takes the locale's `-alphaNextToNumber` pattern instead, which some locales arrange on
/// the other side. Baked at generation time — Embedded has no Unicode property tables to classify a
/// scalar at render time — so the choice is per (currency, presentation), not a runtime computation.
package enum SymbolForm: Equatable, Hashable, Sendable {
    /// A glyph beside the number, such as `"€"`, `"£"` or `"kr"`.
    case glyph

    /// A letter touches the number, such as an ISO code, `"US$"` or `"F CFA"`.
    case letters
}
