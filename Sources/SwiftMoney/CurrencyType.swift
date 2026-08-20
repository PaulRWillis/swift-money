/// Storage for a currency that is already known to the type system.
///
/// Zero sized, so an amount whose currency is fixed at compile time costs nothing to carry it.
public struct NoStorage: Equatable, Hashable, Sendable {
    // Computed, not a `static let`: a stored static needs lazy initialisation through `swift_once`,
    // and this is touched on every construction of a statically typed amount.
    @usableFromInline
    static var empty: NoStorage { NoStorage() }

    @usableFromInline
    @inlinable
    init() {}
}

/// A type that names the currency a monetary amount is denominated in.
///
/// Conform to ``StaticCurrencyType`` to define a currency. This protocol is what ``MoneyOf`` is
/// generic over, and it decides two things: what an amount stores to know its currency, and whether
/// combining two amounts can fail.
///
/// A currency fixed at compile time stores ``NoStorage`` and cannot fail, so its arithmetic needs no
/// `try`. A currency only known at runtime stores the currency itself and fails when two do not
/// match.
public protocol CurrencyType: Sendable {
    /// What an amount carries in order to know its currency.
    associatedtype Storage: Hashable & Sendable

    /// Why combining two amounts of this currency can fail.
    associatedtype ArithmeticError: Error

    /// The currency an amount is denominated in, given what it carries.
    static func currency(for storage: Storage) -> Currency

    /// The storage two amounts share, or a failure if they are not the same currency.
    static func combining(
        _ lhs: Storage,
        _ rhs: Storage
    ) throws(ArithmeticError) -> Storage
}

/// A currency fixed at compile time, so that mixing two of them is a compile error.
///
/// Conforming types carry no state and are never instantiated. They exist to be used as a generic
/// parameter, so that a currency is part of a type rather than a value it holds. A caseless `enum` is
/// the natural shape, and a conformer supplies one property:
///
/// ```swift
/// enum LoyaltyPoints: StaticCurrencyType {
///     static let currency = Currency(code: "LTY", minimalQuantization: 1)
/// }
///
/// typealias Points = MoneyOf<LoyaltyPoints>
/// ```
public protocol StaticCurrencyType: CurrencyType
where Storage == NoStorage, ArithmeticError == Never {
    /// The currency this type names.
    static var currency: Currency { get }
}

public extension StaticCurrencyType {
    @inlinable
    static func currency(for _: NoStorage) -> Currency { currency }

    @inlinable
    static func combining(
        _ lhs: NoStorage,
        _ rhs: NoStorage
    ) throws(Never) -> NoStorage {
        lhs
    }
}

/// A currency only known at runtime, so that amounts carry it and combining them can fail.
///
/// Used through ``Money``, which is `MoneyOf<AnyCurrency>`.
public enum AnyCurrency: CurrencyType {
    public typealias Storage = Currency
    public typealias ArithmeticError = MoneyError

    @inlinable
    public static func currency(for storage: Currency) -> Currency { storage }

    @inlinable
    public static func combining(
        _ lhs: Currency,
        _ rhs: Currency
    ) throws(MoneyError) -> Currency {
        guard lhs == rhs else {
            throw .currencyMismatch(lhs: lhs, rhs: rhs)
        }

        return lhs
    }
}
