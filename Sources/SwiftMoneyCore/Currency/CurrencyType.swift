/// A currency fixed at compile time, so that mixing two of them is a compile error.
///
/// Conforming types carry no state and are never instantiated. They exist to be used as a generic
/// parameter, so that a currency is part of an amount's type rather than a value it holds. A caseless
/// `enum` is the natural shape, and a conformer supplies one property:
///
/// ```swift
/// enum LoyaltyPoints: CurrencyType {
///     static let currency: Currency = {
///         guard let currency = Currency(code: "LTY", unitScale: 1) else {
///             preconditionFailure("LTY must not be a currency the library ships")
///         }
///         return currency
///     }()
/// }
///
/// typealias Points = MoneyOf<LoyaltyPoints>
/// ```
public protocol CurrencyType: CurrencyRepresentation where Storage == Currency.Implied {
    /// The currency this type names.
    static var currency: Currency { get }
}

public extension CurrencyType {
    @inlinable
    static func currency(for _: Currency.Implied) -> Currency { currency }

    @inlinable
    static func storage(forCode code: CurrencyCode?) -> Currency.Implied? {
        code == nil || code == currency.code ? .implied : nil
    }
}
