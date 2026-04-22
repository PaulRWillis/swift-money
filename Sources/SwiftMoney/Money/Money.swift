public struct Money<Currency: SwiftMoney.Currency> {
    /// The storage type for money's minor-unit count.
    ///
    /// Currently `Int64`. A future version may widen this to `Int128`;
    /// code that refers to `Money<C>.MinorUnits` rather than `Int64`
    /// directly will require only a recompile rather than source edits.
    public typealias MinorUnits = Int64

    @usableFromInline
    internal typealias Storage = MinorUnits

    @usableFromInline
    internal var _storage: Storage

    /// The currency type
    public var currency: any SwiftMoney.Currency.Type {
        Currency.self
    }

    /// The minimal quantisation of this currency (number of minor units per major unit).
    @usableFromInline
    internal static var minimalQuantisation: MinimalQuantisation { Currency.minimalQuantisation }

    /// The raw minor units of this money value.
    ///
    /// Represents the value in the currency's smallest denomination.
    /// For example, `Money<GBP>(minorUnits: 150)` represents £1.50.
    ///
    /// ```swift
    /// let onePound = Money<GBP>(minorUnits: 100) // £1.00
    /// onePound.minorUnits  // 100
    /// ```
    @inlinable
    public var minorUnits: MinorUnits { _storage }

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

    /// Creates a new instance from the given integer, if it can be represented
    /// exactly within the Int64 range.
    ///
    /// Returns `nil` if the value cannot be converted to `Int64`.
    ///
    /// ```swift
    /// let v = Money<GBP>(exactly: 42)     // Optional(42); 42p
    /// let big = Money(exactly: Int64.max)  // nil (overflow)
    /// ```
    ///
    /// - Parameter source: The integer value to represent.
    /// - Returns: A `Money` if the value fits, otherwise `nil`.
    @inlinable
    public init?<T: BinaryInteger>(exactly source: T) {
        guard let int64 = Int64(exactly: source) else { return nil }
        self._storage = int64
    }

    /// Creates a `Money` value with the given number of minor units.
    ///
    /// - Precondition: `minorUnits` must not equal `Int.min` on 64-bit platforms
    ///   (equivalently `Int64.min`), which is reserved as the NaN sentinel.
    ///   Use `Money.nan` to obtain a NaN value explicitly.
    public init(minorUnits: Int) {
        let value = Storage(minorUnits)
        precondition(
            value != Storage.min,
            "Use Money.nan — \(Storage.min) is reserved as the NaN sentinel"
        )
        self._storage = value
    }

    /// Creates a `Money` value with the given number of minor units.
    ///
    /// - Precondition: `minorUnits` must not equal `MinorUnits.min` (`Int64.min`),
    ///   which is reserved as the NaN sentinel. Use `Money.nan` to obtain a NaN
    ///   value explicitly.
    public init(minorUnits: MinorUnits) {
        precondition(
            minorUnits != Storage.min,
            "Use Money.nan — \(Storage.min) is reserved as the NaN sentinel"
        )
        self._storage = minorUnits
    }

    /// Creates a `Money` value directly from the raw storage integer, bypassing
    /// the NaN-sentinel guard.
    ///
    /// Used internally by factory properties (`nan`, `max`, `min`, etc.) and
    /// by `Codable` decoding where the sentinel value must be preserved.
    @usableFromInline
    internal init(_unchecked storage: Storage) {
        self._storage = storage
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
        Money(_unchecked: Storage.min)
    }

    /// A Boolean value indicating whether this value is NaN (not-a-number).
    @inlinable
    public var isNaN: Bool {
        _storage == .min
    }

    /// A Boolean value indicating whether this value is finite (not NaN).
    ///
    /// `Money` has no infinity representation, so all non-NaN
    /// values are finite.
    @inlinable
    public var isFinite: Bool {
        !isNaN
    }

    /// The sign of this value.
    ///
    /// Returns `.minus` for negative values (including negative zero, which
    /// cannot occur in this type), `.plus` for zero and positive values.
    /// NaN returns `.plus`.
    @inlinable
    public var sign: FloatingPointSign {
        _storage < 0 && !isNaN ? .minus : .plus
    }

    /// The largest representable value in minor units: `9,223,372,036,854,775,807`.
    @inlinable
    public static var max: Money {
        Money(minorUnits: Storage.max)
    }

    /// The smallest representable value in minor units: `-9,223,372,036,854,775,807`.
    ///
    /// `Int64.min` is reserved as the NaN sentinel, so `.min` uses `Int64.min + 1`.
    @inlinable
    public static var min: Money {
        Money(minorUnits: Storage.min + 1)
    }

    /// The smallest positive value in minor units: `1`.
    @inlinable
    public static var leastNonzeroMagnitude: Money {
        Money(minorUnits: 1)
    }

    /// The largest finite magnitude in minor units: `9,223,372,036,854,775,807`.
    ///
    /// Equal to ``max`` since all representable values are finite.
    @inlinable
    public static var greatestFiniteMagnitude: Money {
        Money(minorUnits: Storage.max)
    }

    /// The least (most negative) finite magnitude in minor units: `-9,223,372,036,854,775,807`.
    ///
    /// Equal to ``min`` since all representable values are finite.
    @inlinable
    public static var leastFiniteMagnitude: Money {
        min
    }
}

extension Money: CustomStringConvertible {
    public var description: String {
        self.formatted()
    }
}

#warning("Add tests to ensure these are conformed to as expected")
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
