public struct Money<Currency: SwiftMoney.Currency>: Sendable {
    /// The storage type for money's minor-unit count.
    ///
    /// Wraps `Int64`, rejecting `Int64.min` at construction because its
    /// negation overflows. Code that refers to `Money<C>.MinorUnits`
    /// rather than the concrete type directly will require only a
    /// recompile if the underlying representation changes.
    public typealias MinorUnits = MinorUnit

    @usableFromInline
    internal var _minorUnits: MinorUnit

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
    /// onePound.minorUnits  // MinorUnit(100)
    /// ```
    @inlinable
    public var minorUnits: MinorUnit { _minorUnits }

    /// Creates a zero value.
    ///
    /// ```swift
    /// let zero = Money<GBP>()
    /// zero == .zero  // true
    /// ```
    @inlinable
    public init() {
        self._minorUnits = 0
    }

    /// Creates a new instance from the given integer, if it can be represented
    /// exactly as a `MinorUnit`.
    ///
    /// Returns `nil` if the value cannot be converted.
    ///
    /// ```swift
    /// let v = Money<GBP>(exactly: 42)  // Optional; 42p
    /// ```
    ///
    /// - Parameter source: The integer value to represent.
    /// - Returns: A `Money` if the value fits, otherwise `nil`.
    @inlinable
    public init?<T: BinaryInteger>(exactly source: T) {
        guard let minorUnit = MinorUnit(exactly: source) else { return nil }
        self._minorUnits = minorUnit
    }

    /// Creates a `Money` value with the given number of minor units.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 150) // £1.50
    /// ```
    public init(minorUnits: MinorUnit) {
        self._minorUnits = minorUnits
    }

    /// Creates a `Money` value with the given number of minor units.
    ///
    /// Traps if the value cannot be represented as a `MinorUnit`
    /// (i.e., if it equals `Int64.min`).
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: Int64(150)) // £1.50
    /// ```
    @inlinable
    public init<T: BinaryInteger>(minorUnits value: T) {
        guard let minorUnit = MinorUnit(exactly: value) else {
            preconditionFailure("minorUnits value \(value) cannot be represented as MinorUnit")
        }
        self._minorUnits = minorUnit
    }

    // MARK: - Special values

    /// The sign of this value.
    ///
    /// Returns `.minus` for negative values, `.plus` for zero and positive values.
    @inlinable
    public var sign: FloatingPointSign {
        _minorUnits < 0 ? .minus : .plus
    }

    /// The largest representable value.
    @inlinable
    public static var max: Money {
        Money(minorUnits: .max)
    }

    /// The smallest representable value.
    @inlinable
    public static var min: Money {
        Money(minorUnits: .min)
    }

    /// The smallest positive value in minor units: `1`.
    @inlinable
    public static var leastNonzeroMagnitude: Money {
        Money(minorUnits: 1)
    }

    /// The largest finite magnitude.
    ///
    /// Equal to ``max`` since all representable values are finite.
    @inlinable
    public static var greatestFiniteMagnitude: Money {
        Money(minorUnits: .max)
    }
}

/*
    - formatting
        > Attributed as a FormatStyle
        > Custom currency symbols that are used to replace attributed symbol in AttributedString?

    - additional type-safe values
        > `PositiveMoney` typealias `Credit`?
        > `NegativeMoney` typealias `Debit`?
        > `ZeroMoney`
        > `NonPositiveMoney`
        > `NonNegativeMoney`

    - handling non-decimalised currencies (which ones exist?)

    - poison addition, subtraction, and multiplication operators for Double and Float.
    - additionally poison division operators for all number types: Int, Decimal, Double, Float (Int128? UInts? Binary ...?)

    - String intepolation? (Test separately to `.description`!)
 */
