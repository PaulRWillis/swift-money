/// How a custom currency shows its symbol in one locale: the glyph or code, and any override of where
/// it sits and how it is spaced.
///
/// Built once and returned from ``CustomCurrencyFormattable/display(for:)``. Only the symbol is
/// required; every other field defaults to inheriting the locale, so the simplest useful value is one
/// line:
///
/// ```swift
/// CustomCurrencyDisplay(symbol: "💎")                        // en_US "💎500.00", de_DE "500,00 💎"
/// CustomCurrencyDisplay(symbol: "🪙", placement: .trailing)  // en_US "500.00🪙"
/// ```
///
/// This is the symbol axis, matching the shipped `.standard`/`.narrow`/`.isoCode` presentations. To
/// name a currency in full ("points"), supply ``CustomCurrencyNames`` from
/// ``CustomCurrencyFormattable/names(for:)`` instead.
public struct CustomCurrencyDisplay: Equatable, Hashable, Sendable {
    package let symbol: CurrencySymbol
    package let narrowSymbol: CurrencySymbol?
    package let placement: CurrencySymbolPlacement
    package let spacing: CurrencySpacing
    package let narrowSpacing: CurrencySpacing?

    /// Creates a display for a custom currency's symbol.
    ///
    /// - Parameters:
    ///   - symbol: The symbol to show, a glyph such as `💎` or a code such as `GEM`.
    ///   - narrowSymbol: The symbol for the narrow presentation, or `nil` to reuse `symbol`.
    ///   - placement: Where the symbol sits. Follows the locale by default.
    ///   - spacing: The gap between the symbol and the digits. Follows the locale by default.
    ///   - narrowSpacing: The gap for the narrow presentation, or `nil` to reuse `spacing`.
    public init(
        symbol: CurrencySymbol,
        narrowSymbol: CurrencySymbol? = nil,
        placement: CurrencySymbolPlacement = .automatic,
        spacing: CurrencySpacing = .automatic,
        narrowSpacing: CurrencySpacing? = nil
    ) {
        self.symbol = symbol
        self.narrowSymbol = narrowSymbol
        self.placement = placement
        self.spacing = spacing
        self.narrowSpacing = narrowSpacing
    }
}
