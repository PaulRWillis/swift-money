import Foundation

public struct Money<Currency: SwiftMoney.Currency> {
    @usableFromInline
    internal let _storage: Int64

    /// The currency type
    public var currency: any SwiftMoney.Currency.Type {
        Currency.self
    }

    /// The raw minor units of a money value in a given currency.
    ///
    /// ```swift
    /// let onePound = Money<GBP>(minorUnits: 100) // £1.00
    /// onePound.minorUnits  // 100
    @inlinable
    public var minorUnits: Int64 { _storage }

    /// Creates a zero value.
    ///
    /// ```swift
    /// let zero = Money<GBP>()
    /// zero == .zero  // true
    /// ```
    @inlinable
    public init() {
        self._storage = 0
    }

    public init(minorUnits: Int64) {
        self._storage = minorUnits
    }

    // MARK: - Special values

    /// The NaN (not-a-number) sentinel value.
    ///
    /// Uses `Int64.min` (-9,223,372,036,854,775,808) as the sentinel because:
    /// - It has no valid negation in `Int64` (negating `Int64.min` overflows)
    /// - It is outside the range of any practical financial value
    /// - Checking `.isNaN` is a single integer comparison
    ///
    /// ```swift
    /// let missing: Money<GBP> = .nan
    /// missing.isNaN  // true
    /// ```
    @inlinable
    public static var nan: Money {
        Money(minorUnits: .min)
    }

    /// A Boolean value indicating whether this value is NaN (not-a-number).
    @inlinable
    public var isNaN: Bool {
        _storage == .min
    }

    /// The zero value.
    @inlinable
    public static var zero: Money {
        Money(minorUnits: 0)
    }

    /// A Boolean value indicating whether this value is finite (not NaN).
    ///
    /// `Money` has no infinity representation, so all non-NaN
    /// values are finite.
    @inlinable
    public var isFinite: Bool {
        !isNaN
    }
}

extension Money: CustomStringConvertible {
    public var description: String {
        self.formatted()
    }
}

#warning("Add tests to ensure these are conformed to as expected")
extension Money: Equatable {}

extension Money: Hashable {}

extension Money: Sendable {}

extension Money: Codable {}




/*

    - `.zero`
    - `.magnitude`

    - formatting (CurrencyFormatStyle from IntegerFormatStyle)

    - addition
        > associative: a + (b + c) == (a + b) + c
        > commutative: a + b == b + a

    - multiplication
        > integeral
        > fractional
        > distributive: a x (b + c) == (a x b) + (a x c)

    - distribution
        > integral (chunks)
        > `Distribution` type (`Distribution<Money>`?)

    - formatting
        > parsing using formatting options
        > attributed
        > decimalSeparator
        > grouping
        > notation
        > precision
        > presentation
        > rounded
        > scale
        > sign
        > currencyCode
        >`precision` and `notation`, etc., with comprehensive documentation for all formatting options
            (see bookmarks for Swift Forums discussion on compact notation)
        > Attributed as a FormatStyle
        > Add `Money.Currency` as in `IntegerFormatStyle.Currency`?


    - non-decimal currencies

    - serialisation
        > custom encoding + decoding

    - conformance to `DebugCustomStringConvertible`

    - additional type-safe values
        > `PositiveMoney` typealias `Credit`?
        > `NegativeMoney` typealias `Debit`?
        > `ZeroMoney`
        > `NonPositiveMoney`
        > `NonNegativeMoney`

    - handling non-decimalised currencies (which ones exist?)

    - handling "transaction minor units" vs. "tender minor units" as in Swiss Francs (CHF) of 0.01 vs. 0.05

    - init from Decimal?
        > Potentially by multiplying by minor units?
        > How handle small values like £0.003 (3/10ths pence)?

    - init from String (optional)
    - init from minor units (non optional)?

    - poison addition, subtraction, and multiplication operators for Double and Float.
    - additionally poison division operators for all number types: Int, Decimal, Double, Float (Int128? UInts? Binary ...?)

    - comparators (<, >, etc.)

    - negating prefix (-)

    - conformance to `AdditiveArithmetic`?

    * Minimal quantisation
    - When choosing 0.0001 USD as the minimal quantisation of USD, this allows us to represent a quadrillion dollars. This is more than the current M1 money supply of USD.

    - String intepolation? (Test separately to `.description`!)

    - `intValue` and `decimalValue`
 */
