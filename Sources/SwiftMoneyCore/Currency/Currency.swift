/// A currency a monetary amount can be denominated in.
///
/// A currency is a code and the number of its smallest units that make one major unit: enough to
/// identify it and to know how finely it divides.
///
/// ```swift
/// let points = Currency(code: "LTY", unitScale: 1)   // Currency?, nil only for a shipped code at a wrong scale
/// ```
public struct Currency: Equatable, Hashable, Sendable {
    /// The code identifying the currency, such as `GBP`.
    public let code: CurrencyCode

    /// How many of the currency's smallest units make one major unit.
    public let unitScale: UnitScale

    /// Creates a currency from a code and the number of its smallest units per major unit.
    ///
    /// Define any currency the library doesn't ship — a cryptocurrency (`BTC`), a commodity (`XAU`),
    /// loyalty points (`LTY`), or an ISO code that has no minor unit. For a currency the library does
    /// ship, prefer its vetted value, such as ``Currency/gbp`` or ``Currencies/GBP``.
    ///
    /// - Parameters:
    ///   - code: The code identifying the currency.
    ///   - unitScale: How many of the currency's smallest units make one major unit.
    /// - Returns: `nil` if `code` is a currency the library ships at a different scale — for example
    ///   `Currency(code: "GBP", unitScale: 1)`, since pounds have 100 minor units.
    public init?(
        code: CurrencyCode,
        unitScale: UnitScale
    ) {
        if let shipped = Currency(iso: code), shipped.unitScale != unitScale {
            return nil
        }

        self.init(unchecked: code, unitScale: unitScale)
    }

    /// Creates a currency, trusting the code and scale without validating them.
    ///
    /// Used to build the currencies the library itself ships, whose values are already vetted, and so
    /// must not route back through the validating initialiser (which reads the shipped table).
    init(
        unchecked code: CurrencyCode,
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
        // Computed, not a `static let`: a stored static needs lazy initialization through
        // `swift_once`, and this is touched on every construction of a statically typed amount.
        @usableFromInline
        static var implied: Implied { Implied() }

        @inlinable
        init() {}
    }
}

extension Currency: CustomStringConvertible {
    public var description: String {
        String(code)
    }
}

/// A namespace for the ISO 4217 currencies, one caseless `enum` per code.
///
/// The members are generated from the list ISO's maintenance agency publishes. Use one as a generic
/// parameter to fix a currency at compile time: `MoneyOf<Currencies.CHF>`.
public enum Currencies {}

// Only a handful of currencies get a name at the top level, because a typealias per code would put
// 165 of them into every file that imports this library, among them `ALL`, `TOP` and a `TRY` that
// reads like the keyword. Any other currency is `MoneyOf<Currencies.XYZ>`, which an adopter can
// alias to whatever suits their own code.

/// A monetary amount in pounds sterling.
///
/// Distinct from ``Currencies/GBP``, which names the currency rather than an amount in it.
public typealias GBP = MoneyOf<Currencies.GBP>

/// A monetary amount in euros.
///
/// Distinct from ``Currencies/EUR``, which names the currency rather than an amount in it.
public typealias EUR = MoneyOf<Currencies.EUR>

/// A monetary amount in US dollars.
///
/// Distinct from ``Currencies/USD``, which names the currency rather than an amount in it.
public typealias USD = MoneyOf<Currencies.USD>

/// A monetary amount in Japanese yen.
///
/// Distinct from ``Currencies/JPY``, which names the currency rather than an amount in it. Yen have
/// no subdivision, so an amount of them is a whole number of yen.
public typealias JPY = MoneyOf<Currencies.JPY>

/// A monetary amount whose currency is only known at runtime.
///
/// Two amounts combine only when their currencies match, which cannot be checked at compile time, so
/// arithmetic throws ``MoneyError`` instead. Prefer a typed amount such as ``GBP`` where the currency
/// is known statically.
public typealias Money = MoneyOf<AnyCurrency>
