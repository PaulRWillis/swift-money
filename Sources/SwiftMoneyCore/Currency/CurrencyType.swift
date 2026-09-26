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

    /// What an amount carries in order to be in the currency a code names, or `nil` where this
    /// representation cannot be that currency.
    ///
    /// The inverse of ``currency(for:)``. ``CurrencyType`` supplies it, so defining a currency does
    /// not mean writing one.
    ///
    /// - Parameter code: The code naming the currency, or `nil` where nothing named one, in which
    ///   case only a representation that fixes a currency of its own can answer.
    static func storage(forCode code: CurrencyCode?) -> Storage?

    /// What an amount carries in order to be in the currency a decoded ``CurrencyField`` names, or
    /// `nil` where this representation cannot be that currency.
    ///
    /// A representation that already fixes its own currency has no use for a scale — its
    /// ``storage(forCode:)`` already resolves the one currency it can ever be, so the default
    /// implementation below ignores ``CurrencyField/custom(code:rawScale:)``'s scale entirely. Only a
    /// representation whose currency is known solely at runtime needs it, to rebuild a currency the
    /// code alone does not resolve (one the library does not ship).
    ///
    /// - Parameter field: What a decoded payload named as the currency.
    static func storage(for field: CurrencyField) -> Storage?
}

public extension CurrencyRepresentation {
    static func storage(forCode _: CurrencyCode?) -> Storage? { nil }

    static func storage(for field: CurrencyField) -> Storage? {
        switch field {
        case .none:
            storage(forCode: nil)
        case let .code(code):
            storage(forCode: code)
        case let .custom(code, _):
            storage(forCode: code)
        }
    }
}

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

/// A currency only known at runtime, so that amounts carry it and combining them can fail.
///
/// Used through ``Money``, which is `MoneyOf<AnyCurrency>`.
public enum AnyCurrency: CurrencyRepresentation {
    public typealias Storage = Currency

    @inlinable
    public static func currency(for storage: Currency) -> Currency { storage }

    @inlinable
    public static func storage(forCode code: CurrencyCode?) -> Currency? {
        code.flatMap(Currency.init(iso:))
    }

    /// Resolves a currency the ISO table ships from the code alone, or a currency the table does not
    /// ship from the code and its scale together. Validates the scale itself, since this is the one
    /// representation that ever looks at it — a malformed scale here is refused, not silently
    /// dropped, but it never reaches a representation that would have ignored it anyway.
    @inlinable
    public static func storage(for field: CurrencyField) -> Currency? {
        switch field {
        case .none:
            return nil

        case let .code(code):
            return Currency(iso: code)

        case let .custom(code, rawScale):
            guard let scale = UnitScale(decimalPlaces: rawScale) else {
                return nil
            }

            return Currency(code: code, unitScale: scale)
        }
    }

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
