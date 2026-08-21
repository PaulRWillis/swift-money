/// The means by which a monetary amount knows its currency.
///
/// Conform to ``CurrencyType`` to define a currency. Conforming here directly gives an amount no
/// arithmetic, because the operators are declared only for the two conformances this library
/// provides.
public protocol CurrencyRepresentation: Sendable {
    /// What an amount carries in order to know its currency.
    associatedtype Storage: Hashable & Sendable

    /// The currency an amount is denominated in, given what it carries.
    static func currency(for storage: Storage) -> Currency

    /// The currency an amount is in when nothing else names one, or `nil` where only a name can say.
    ///
    /// A currency fixed at compile time answers with itself, so `"4.99"` is a complete amount. One
    /// only known at runtime answers `nil`, so the same string is not.
    static var impliedCurrency: Currency? { get }

    /// What an amount carries in order to be denominated in `currency`, or `nil` if it cannot be.
    ///
    /// The inverse of ``currency(for:)``. A currency fixed at compile time accepts only its own.
    static func storage(for currency: Currency) -> Storage?
}

public extension CurrencyRepresentation {
    static var impliedCurrency: Currency? { nil }

    static func storage(for _: Currency) -> Storage? { nil }
}

/// A currency fixed at compile time, so that mixing two of them is a compile error.
///
/// Conforming types carry no state and are never instantiated. They exist to be used as a generic
/// parameter, so that a currency is part of an amount's type rather than a value it holds. A caseless
/// `enum` is the natural shape, and a conformer supplies one property:
///
/// ```swift
/// enum LoyaltyPoints: CurrencyType {
///     static let currency = Currency(code: "LTY", unitScale: 1)
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

    static var impliedCurrency: Currency? { currency }

    static func storage(for currency: Currency) -> Currency.Implied? {
        currency == Self.currency ? .implied : nil
    }
}

/// A currency only known at runtime, so that amounts carry it and combining them can fail.
///
/// Used through ``Money``, which is `MoneyOf<AnyCurrency>`.
public enum AnyCurrency: CurrencyRepresentation {
    public typealias Storage = Currency

    @inlinable
    public static func currency(for storage: Currency) -> Currency { storage }

    public static func storage(for currency: Currency) -> Currency? { currency }

    @usableFromInline
    static func requireMatch(
        _ lhs: Currency,
        _ rhs: Currency
    ) throws(MoneyError) {
        guard lhs == rhs else {
            throw .currencyMismatch(lhs: lhs, rhs: rhs)
        }
    }
}
