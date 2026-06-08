public struct Money<Currency: SwiftMoney.Currency>: Sendable {
    /// The storage type for money's minor-unit count.
    ///
    /// Currently `Int64`. A future version may widen this to `Int128`;
    /// code that refers to `Money<C>.MinorUnits` rather than `Int64`
    /// directly will require only a recompile rather than source edits.
    public typealias MinorUnits = Int64

    internal typealias Storage = MinorUnit

    private var _minorUnits: Storage

    /// The currency type
    public var currency: any SwiftMoney.Currency.Type {
        Currency.self
    }

    /// The raw minor units of this money value.
    ///
    /// Represents the value in the currency's smallest denomination.
    /// For example, `Money<GBP>(minorUnits: 150)` represents £1.50.
    ///
    /// ```swift
    /// let onePound = Money<GBP>(minorUnits: 100) // £1.00
    /// onePound.minorUnits  // 100
    /// ```
    public var minorUnits: MinorUnits { Int64(_minorUnits) }

    /// Creates a zero value.
    ///
    /// ```swift
    /// let zero = Money<GBP>()
    /// zero == .zero  // true
    /// ```
    public init() {
        self._minorUnits = .zero
    }

    /// Creates a `Money` value directly from a `MinorUnit`.
    ///
    /// Used internally where a `MinorUnit` is already validated.
    internal init(_storage: Storage) {
        self._minorUnits = _storage
    }

    /// The internal storage, exposed for module-level access (e.g. `AnyMoney`).
    internal var _storage: Storage { _minorUnits }

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
    public init?<T: BinaryInteger>(exactly source: T) {
        guard let storage = Storage(exactly: source) else {
            return nil
        }
        
        self._minorUnits = storage
    }

    /// Creates a `Money` value with the given number of minor units.
    ///
    /// - Precondition: `minorUnits` must not equal `Int.min` on 64-bit platforms
    ///   (equivalently `Int64.min`), which is reserved as an internal sentinel.
    public init(minorUnits: Int) {
        guard let storage = Storage(exactly: minorUnits) else {
            preconditionFailure(
                "\(Int64.min) is reserved and cannot be used as a minor-unit value"
            )
        }
        self._minorUnits = storage
    }

    /// Creates a `Money` value with the given number of minor units.
    ///
    /// - Precondition: `minorUnits` must not equal `MinorUnits.min` (`Int64.min`),
    ///   which is reserved as an internal sentinel.
    public init(minorUnits: MinorUnits) {
        guard let storage = Storage(exactly: minorUnits) else {
            preconditionFailure(
                "\(Int64.min) is reserved and cannot be used as a minor-unit value"
            )
        }
        self._minorUnits = storage
    }

    // MARK: - Special values

    /// The sign of this value.
    ///
    /// Returns `.minus` for negative values, `.plus` for zero and positive values.
    public var sign: FloatingPointSign {
        _minorUnits < .zero ? .minus : .plus
    }

    /// The largest representable value in minor units: `9,223,372,036,854,775,807`.
    public static var max: Money {
        Money(_storage: .max)
    }

    /// The smallest representable value in minor units: `-9,223,372,036,854,775,807`.
    ///
    /// `Int64.min` is excluded by `MinorUnit`'s invariant, so `.min` is `Int64.min + 1`.
    public static var min: Money {
        Money(_storage: .min)
    }

    /// The smallest positive value in minor units: `1`.
    public static var leastNonzeroMagnitude: Money {
        Money(minorUnits: 1)
    }

    // TODO: Remove
    /// The largest finite magnitude in minor units: `9,223,372,036,854,775,807`.
    ///
    /// Equal to ``max`` since all representable values are finite.
    public static var greatestFiniteMagnitude: Money {
        Money(_storage: .max)
    }

    // TODO: Remove
    /// The least (most negative) finite magnitude in minor units: `-9,223,372,036,854,775,807`.
    ///
    /// Equal to ``min`` since all representable values are finite.
    public static var leastFiniteMagnitude: Money {
        min
    }
}

// MARK: - AnyMoney conversion

extension Money {
    /// A type-erased copy of this value.
    ///
    /// Use this to store typed `Money<C>` values in heterogeneous collections,
    /// pass across runtime boundaries, or persist via `Codable`:
    ///
    /// ```swift
    /// let arr: [AnyMoney] = [
    ///     Money<GBP>(minorUnits: 500).erased,
    ///     Money<EUR>(minorUnits: 1000).erased,
    /// ]
    /// ```
    ///
    /// To recover a typed value, use ``Money/init(_:)-anyMoney``.
    public var erased: AnyMoney {
        AnyMoney(self)
    }

    /// Creates a typed `Money` value from a type-erased `AnyMoney`, if the
    /// currency matches.
    ///
    /// Returns `nil` when the currency code of `anyMoney` does not match `C`,
    /// or when the stored value is the sentinel minimum.
    ///
    /// ```swift
    /// let any = Money<GBP>(minorUnits: 500).erased
    /// let typed: Money<GBP>? = Money<GBP>(any)   // Money<GBP>(500)
    /// let wrong: Money<EUR>? = Money<EUR>(any)   // nil
    /// ```
    ///
    /// - Parameter anyMoney: The type-erased money value to convert.
    public init?(_ anyMoney: AnyMoney) {
        guard anyMoney.currencyCode == Currency.code else { return nil }
        guard anyMoney.minorUnits != .min else { return nil }
        self.init(minorUnits: anyMoney.minorUnits)
    }
}
