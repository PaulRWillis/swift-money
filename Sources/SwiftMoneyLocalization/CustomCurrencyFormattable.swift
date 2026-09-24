import SwiftMoneyCore

/// A currency that carries its own display, so its amounts format for a locale like a shipped currency.
///
/// Conform a custom currency type (a token, loyalty points, an in-app gem) to supply the symbol and, if
/// wanted, the full name the formatter renders. The display comes from the type, never from a loose
/// parameter, so an amount and its display cannot disagree and a shipped currency cannot be restyled.
///
/// ```swift
/// extension Currencies {
///     enum Coin: CustomCurrencyFormattable {
///         static let currency: Currency = {
///             guard let currency = Currency(code: "COIN", unitScale: 2) else {
///                 preconditionFailure("COIN must not be a currency the library ships")
///             }
///             return currency
///         }()
///
///         static func display(for locale: LocaleIdentifier) -> CustomCurrencyDisplay? {
///             CustomCurrencyDisplay(symbol: "🪙")
///         }
///     }
/// }
/// typealias COIN = MoneyOf<Currencies.Coin>
/// ```
public protocol CustomCurrencyFormattable: CurrencyType {
    /// The currency's symbol display for a locale, or `nil` where the currency has no display there.
    ///
    /// - Parameter locale: The locale to display in.
    static func display(for locale: LocaleIdentifier) -> CustomCurrencyDisplay?
}
