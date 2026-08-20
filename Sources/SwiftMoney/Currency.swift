/// A currency a monetary amount can be denominated in.
///
/// A currency is a code and the number of its smallest units that make one major unit — enough to
/// identify it and to know how finely it divides.
///
/// ```swift
/// let currency = Currency(code: "LTY", unitScale: 1)
/// ```
public struct Currency: Equatable, Hashable, Sendable {
    /// The code identifying the currency, such as `GBP`.
    public let code: CurrencyCode

    /// How many of the currency's smallest units make one major unit.
    public let unitScale: UnitScale

    /// Creates a currency.
    public init(
        code: CurrencyCode,
        unitScale: UnitScale
    ) {
        self.code = code
        self.unitScale = unitScale
    }
}

public extension Currency {
    /// The storage of an amount whose currency is fixed by its type.
    ///
    /// Zero-sized, so fixing a currency at compile time costs an amount nothing to carry it.
    struct Implied: Equatable, Hashable, Sendable {
        // Computed, not a `static let`: a stored static needs lazy initialisation through
        // `swift_once`, and this is touched on every construction of a statically typed amount.
        @usableFromInline
        static var implied: Implied { Implied() }

        @inlinable
        init() {}
    }
}

// MARK: - CustomStringConvertible

extension Currency: CustomStringConvertible {
    public var description: String {
        String(code)
    }
}

// MARK: - ISO4217 Currencies

public extension Currency {
    /// Pound sterling.
    static let gbp = Currency(code: "GBP", unitScale: 100)

    /// The euro.
    static let eur = Currency(code: "EUR", unitScale: 100)
}

// MARK: - ISO4217 Currencies as types

/// A namespace for the ISO4217 currencies the library provides.
public enum Currencies {
    /// The euro.
    public enum EUR: CurrencyType {
        public static let currency: Currency = .eur
    }

    /// Great British Pounds (GBP).
    public enum GBP: CurrencyType {
        public static let currency: Currency = .gbp
    }
}

// MARK: - Typed money

/// A monetary amount in pounds sterling.
///
/// Distinct from ``Currencies/GBP``, which names the currency rather than an amount in it.
public typealias GBP = MoneyOf<Currencies.GBP>

/// A monetary amount in euros.
///
/// Distinct from ``Currencies/EUR``, which names the currency rather than an amount in it.
public typealias EUR = MoneyOf<Currencies.EUR>

/// A monetary amount whose currency is only known at runtime.
///
/// Two amounts combine only when their currencies match, which cannot be checked at compile time, so
/// arithmetic throws ``MoneyError`` instead. Prefer a typed amount such as ``GBP`` where the currency
/// is known statically.
public typealias Money = MoneyOf<AnyCurrency>
