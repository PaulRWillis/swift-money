// `LocalizedStringResource` and `String(localized:)` are Apple-platform Foundation only, absent from
// swift-corelibs-foundation, so this convenience compiles on Darwin alone. A non-Darwin caller resolves
// its own strings and builds a ``CustomCurrencyDisplay`` directly.
#if canImport(Darwin)

import Foundation
import SwiftMoneyLocalization

/// A custom currency's symbol display sourced from localized strings, resolved for a locale into a
/// ``CustomCurrencyDisplay``.
///
/// A Foundation convenience for the common case where the symbol lives in a string catalog and varies
/// by locale. Build one with a `LocalizedStringResource` per symbol, then call ``resolved(for:)`` inside
/// ``CustomCurrencyFormattable/display(for:)`` to get the display for that locale.
///
/// ```swift
/// static func display(for locale: LocaleIdentifier) -> CustomCurrencyDisplay? {
///     CustomCurrencyLocalizedDisplay(symbol: "gem.symbol").resolved(for: Locale(identifier: locale.value))
/// }
/// ```
public struct CustomCurrencyLocalizedDisplay: Sendable {
    private let symbol: LocalizedStringResource
    private let narrowSymbol: LocalizedStringResource?
    private let placement: CurrencySymbolPlacement
    private let spacing: CurrencySpacing
    private let narrowSpacing: CurrencySpacing?

    /// Creates a localized display for a custom currency's symbol.
    ///
    /// - Parameters:
    ///   - symbol: The localized symbol to show.
    ///   - narrowSymbol: The localized symbol for the narrow presentation, or `nil` to reuse `symbol`.
    ///   - placement: Where the symbol sits. Follows the locale by default.
    ///   - spacing: The gap between the symbol and the digits. Follows the locale by default.
    ///   - narrowSpacing: The gap for the narrow presentation, or `nil` to reuse `spacing`.
    public init(
        symbol: LocalizedStringResource,
        narrowSymbol: LocalizedStringResource? = nil,
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

    /// The display with its symbols resolved for a locale.
    ///
    /// - Parameter locale: The locale to resolve the localized strings in.
    /// - Returns: A ``CustomCurrencyDisplay`` carrying the resolved symbols and this display's placement
    ///   and spacing.
    /// - Precondition: The symbol does not resolve to an empty string.
    public func resolved(for locale: Locale) -> CustomCurrencyDisplay {
        guard let resolvedSymbol = CurrencySymbol(Self.string(symbol, for: locale)) else {
            preconditionFailure("A localized currency symbol must not resolve to empty.")  // coverage:ignore
        }

        let resolvedNarrow = narrowSymbol.flatMap { CurrencySymbol(Self.string($0, for: locale)) }

        return CustomCurrencyDisplay(
            symbol: resolvedSymbol,
            narrowSymbol: resolvedNarrow,
            placement: placement,
            spacing: spacing,
            narrowSpacing: narrowSpacing
        )
    }

    // The resource resolved in a specific locale, rather than the process's current one.
    private static func string(_ resource: LocalizedStringResource, for locale: Locale) -> String {
        var localized = resource
        localized.locale = locale
        return String(localized: localized)
    }
}

#endif
