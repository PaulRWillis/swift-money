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

    #warning("Remove")
    /// The largest finite magnitude in minor units: `9,223,372,036,854,775,807`.
    ///
    /// Equal to ``max`` since all representable values are finite.
    public static var greatestFiniteMagnitude: Money {
        Money(_storage: .max)
    }

    #warning("Remove")
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

// MARK: - AdditiveArithmetic

/// Conformance to `AdditiveArithmetic`, providing `+`, `-`, `+=`, `-=`, `and `.zero`.
extension Money: AdditiveArithmetic {
    /// The zero value.
    ///
    /// Returns a value representing zero in the currency's minor units.
    public static var zero: Money {
        Money(_storage: .zero)
    }

    /// Returns the sum of two values.
    ///
    /// Traps on overflow or if the result cannot be represented in the valid range for this type.
    ///
    /// ```swift
    /// let a = Money<GBP>(minorUnits: 105) // £1.05
    /// let b = Money<GBP>(minorUnits: 325) // £3.25
    /// let sum = a + b  // 430 (£4.30)
    /// ```
    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(_storage: lhs._storage + rhs._storage)
    }

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// var total = Money<GBP>(minorUnits: 100) // £1.00
    /// total += Money<GBP>(minorUnits: 5)
    /// // total is now 105 (£1.05)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to add.
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    /// Returns the difference of two values.
    ///
    /// Traps on overflow or if the result cannot be represented in the valid range for this type.
    ///
    /// ```swift
    /// let a = Money<GBP>(minorUnits: 1050) // £10.50
    /// let b = Money<GBP>(minorUnits: 325) // £3.25
    /// let diff = a - b  // 725 (£7.25)
    /// ```
    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(_storage: lhs._storage - rhs._storage)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// var balance = Money<GBP>(minorUnits: 100_00) // £100.00
    /// balance -= Money<GBP>(minorUnits: 2550) // £25.50
    /// // balance is now 7450 // £74.50
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to subtract.
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }
}

// MARK: - Integral Multiplication

public extension Money {
    /// Returns the result of multiplying a `Money` value by an `Int64` scalar.
    ///
    /// Traps on overflow or if the result cannot be represented in the valid range for this type.
    static func * (lhs: Money, rhs: Int64) -> Money {
        Money(_storage: lhs._storage * rhs)
    }

    /// Returns the result of multiplying an `Int64` scalar by a `Money` value.
    ///
    /// Traps if the result overflows `Int64`.
    ///
    /// - Precondition: The result must fit in `Int64`.
    static func * (lhs: Int64, rhs: Money) -> Money {
        rhs * lhs
    }

    /// Multiplies a `Money` value by an `Int64` scalar in place.
    ///
    /// Traps on overflow.
    static func *= (lhs: inout Money, rhs: Int64) {
        lhs = lhs * rhs
    }
}

#warning("Should there be poisoning of `/` as well?")
// MARK: - Unavailable floating-point multiplication operators
//
// Money is not a number. Multiplying a Money value by a floating-point scalar
// is meaningless and dangerous — it destroys the integer-precision guarantee
// on which all monetary arithmetic in this library depends.
//
// Use `multiplied(by:rounding:)` with a `Rate` for fractional scaling,
// or `*` with an `Int`/`Int64` scalar for integral scaling.
//
// These overloads exist solely to produce a clear compile-time diagnostic;
// they are never callable at runtime.
extension Money {

    @available(*, unavailable, message: "Multiplying Money by Double loses precision. Use multiplied(by:rounding:) with a Rate, or * with an integer scalar.")
    public static func * (lhs: Money, rhs: Double) -> Money { fatalError() }

    @available(*, unavailable, message: "Multiplying Money by Double loses precision. Use multiplied(by:rounding:) with a Rate, or * with an integer scalar.")
    public static func * (lhs: Double, rhs: Money) -> Money { fatalError() }

    @available(*, unavailable, message: "Multiplying Money by Float loses precision. Use multiplied(by:rounding:) with a Rate, or * with an integer scalar.")
    public static func * (lhs: Money, rhs: Float) -> Money { fatalError() }

    @available(*, unavailable, message: "Multiplying Money by Float loses precision. Use multiplied(by:rounding:) with a Rate, or * with an integer scalar.")
    public static func * (lhs: Float, rhs: Money) -> Money { fatalError() }
}

// MARK: - Distribution

extension Money {
    /// Distributes this value into `n` equal-or-near-equal parts.
    ///
    /// Uses integer division in minor units:
    /// - `quotient` = `minorUnits / n` (truncating towards zero)
    /// - If the remainder is zero, returns `.exact(share: quotient, count: n)`.
    /// - Otherwise returns `.uneven` where `larger = quotient + sign`,
    ///   `largerCount = |minorUnits % n|`, `smaller = quotient`, and
    ///   `sign` is `+1` for non-negative amounts or `-1` for negative amounts.
    ///
    /// The sum invariant `distribution.sum == self` always holds.
    ///
    /// - Parameter n: Number of parts; must be ≥ 1.
    public func distributed(into n: DistributionParts) -> Distribution<Currency> {
        let amount = minorUnits
        let parts = Int64(n.intValue)
        let quotient  = amount / parts
        let remainder = amount % parts          // same sign as amount (Swift semantics)
        let remainderCount = Int(abs(remainder))
        let smaller = Money(minorUnits: quotient)

        guard remainderCount > 0 else {
            return .exact(share: smaller, count: n.intValue)
        }

        let sign: Int64 = amount >= 0 ? 1 : -1
        return .uneven(
            larger: Money(minorUnits: quotient + sign),
            largerCount: remainderCount,
            smaller: smaller,
            smallerCount: n.intValue - remainderCount
        )
    }
}

// MARK: - Equatable

extension Money: Equatable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// ```swift
    /// let a = Money<GBP>(minorUnits: 105)
    /// let b = Money<GBP>(minorUnits: 105)
    /// a == b  // true
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: `true` if the two values have the same raw storage.
    /// - Complexity: O(1) -- single integer comparison.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.minorUnits == rhs.minorUnits
    }
}

// MARK: - Comparable

extension Money: Comparable {
    /// Returns a Boolean value indicating whether the first value is less than
    /// the second.
    ///
    /// ```swift
    /// let a = Money<GBP>(minorUnits: 20)
    /// let b = Money<GBP>(minorUnits: 10)
    /// a < b  // true
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: `true` if `lhs` is strictly less than `rhs`.
    /// - Complexity: O(1) -- single integer comparison.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.minorUnits < rhs.minorUnits
    }
}

// MARK: - Hashable

extension Money: Hashable {
    /// Hashes the raw storage value into the given hasher.
    ///
    /// Two values that compare equal with `==` always produce the same hash,
    /// satisfying the `Hashable` contract.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(minorUnits)
    }
}

// MARK: - Magnitude

extension Money {
    /// The magnitude type.
    public typealias Magnitude = Money

    /// The absolute value of this instance.
    ///
    /// Returns the non-negative value. Traps if the value is not representable (e.g. minimum value).
    ///
    /// ```swift
    /// let v = Money("-5.0")!
    /// v.magnitude  // 5.0
    /// ```
    public var magnitude: Magnitude {
        _storage < .zero ? Self(_storage: -_storage) : self
    }
}

// MARK: - Negation

extension Money {
    /// Returns the additive inverse of this value.
    ///
    /// ```swift
    /// let price = Money<GBP>(4250) // £42.50
    /// let neg = -price  // -£42.50
    /// ```
    ///
    /// - Parameter operand: The value to negate.
    /// - Returns: The negated value.
    public prefix static func - (operand: Money) -> Money {
        var copy = operand
        copy.negate()
        return copy
    }

    /// Replaces this value with its additive inverse.
    ///
    /// Traps if the value is not representable (e.g. minimum value).
    ///
    /// ```swift
    /// var price = Money<GBP>(4250) // £42.50
    /// price.negate()
    /// // price is now -4250 (-£42.50)
    /// ```
    public mutating func negate() {
        self = Self(_storage: -_storage)
    }
}

// MARK: - CustomStringConvertible

extension Money: CustomStringConvertible {
    public var description: String {
        self.formatted()
    }
}

// MARK: - CustomDebugStringConvertible

extension Money: CustomDebugStringConvertible {
    /// A debug-friendly representation showing the currency type, raw minor
    /// units, and formatted value.
    ///
    /// ```swift
    /// Money<GBP>(minorUnits: 150).debugDescription
    /// // "Money<GBP>(minorUnits: 150) — \"£1.50\""
    /// ```
    public var debugDescription: String {
        "Money<\(Currency.code)>(minorUnits: \(minorUnits)) — \"\(formatted())\""
    }
}

// MARK: - Integer Conversions

extension Int {
    /// Creates an `Int` from a `Money`.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
    /// Int(v)  // 42
    /// ```
    ///
    /// The `Int` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The minor units must fit in `Int`.
    public init<C: Currency>(_ value: Money<C>) {
        guard let narrow = Int(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds Int range")
        }
        self = narrow
    }

    /// Creates an `Int` from a `Money`, returning `nil` if the
    /// minor units exceed `Int` range.
    ///
    /// ```swift
    /// Int(exactly: Money<GBP>(minorUnits: 42))   // Optional(42)
    /// ```
    ///
    /// The `Int` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: An `Int` if the conversion is exact, otherwise `nil`.
    public init?<C: Currency>(exactly value: Money<C>) {
        guard let narrow = Int(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

#warning("Remove `Int64` conversion")
extension Int64 {
    /// Creates an `Int64` from a `Money`.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: -79) // -79p or -£0.79
    /// Int64(v)  // -79
    /// ```
    ///
    /// The `Int64` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int64(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int64(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The minor units must fit in `Int64`.
    public init<C: Currency>(_ value: Money<C>) {
        guard let narrow = Int64(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds Int64 range")
        }
        self = narrow
    }

    /// Creates an `Int64` from a `Money`, returning `nil` if the
    /// minor units exceed `Int64` range.
    ///
    /// ```swift
    /// Int64(exactly: Money<GBP>(minorUnits: 42))   // Optional(42)
    /// ```
    ///
    /// The `Int64` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int64(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int64(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: An `Int64` if the conversion is exact, otherwise `nil`.
    public init?<C: Currency>(exactly value: Money<C>) {
        guard let narrow = Int64(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

#warning("Remove `Int32` conversion")
extension Int32 {
    /// Creates an `Int32` from a `Money`.
    /// Traps if the integer part exceeds `Int32` range.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
    /// Int32(v)  // 42
    /// ```
    ///
    /// The `Int` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The integer part must fit in `Int32`.
    public init<C: Currency>(_ value: Money<C>) {
        guard let narrow = Int32(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds Int32 range")
        }
        self = narrow
    }

    /// Creates an `Int32` from a `Money`, returning `nil` if the
    /// minor units exceed `Int32` range.
    ///
    /// ```swift
    /// Int32(exactly: Money<GBP>(minorUnits: 42))   // Optional(42)
    /// ```
    ///
    /// The `Int32` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int32(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int32(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: An `Int32` if the conversion is exact, otherwise `nil`.
    public init?<C: Currency>(exactly value: Money<C>) {
        guard let narrow = Int32(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

// MARK: - Unsigned Integer Conversions

#warning("Remove `UInt` conversion")
extension UInt {
    /// Creates a `UInt` from a `Money`.
    /// Traps if the integer part exceeds `UInt` range.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
    /// UInt(v)  // 42
    /// ```
    ///
    /// The `UInt` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// UInt(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// UInt(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The integer part must fit in `UInt`.
    public init<C: Currency>(_ value: Money<C>) {
        guard let narrow = UInt(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds UInt range")
        }
        self = narrow
    }

    /// Creates a `UInt` from a `Money`, returning `nil` if the
    /// minor units exceed `UInt` range.
    ///
    /// ```swift
    /// UInt(exactly: Money<GBP>(minorUnits: 42))    // Optional(42)
    /// ```
    ///
    /// The `UInt` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// UInt(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// UInt(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: A `UInt` if the conversion is exact, otherwise `nil`.
    public init?<C: Currency>(exactly value: Money<C>) {
        guard let narrow = UInt(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

#warning("Remove `UInt64` conversion")
extension UInt64 {
    /// Creates a `UInt64` from a `Money`.
    /// Traps if the integer part exceeds `UInt64` range.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
    /// UInt64(v)  // 42
    /// ```
    ///
    /// The `Int` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// UInt64(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// UInt64(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The integer part must fit in `UInt64`.
    public init<C: Currency>(_ value: Money<C>) {
        guard let narrow = UInt64(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds UInt64 range")
        }
        self = narrow
    }

    /// Creates a `UInt64` from a `Money`, returning `nil` if the
    /// minor units exceed `UInt64` range.
    ///
    /// ```swift
    /// UInt64(exactly: Money<GBP>(minorUnits: 42))    // Optional(42)
    /// ```
    ///
    /// The `UInt64` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// UInt64(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// UInt64(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: A `UInt64` if the conversion is exact, otherwise `nil`.
    public init?<C: Currency>(exactly value: Money<C>) {
        guard let narrow = UInt64(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

#warning("Remove `UInt32` conversion")
extension UInt32 {
    /// Creates a `UInt32` from a `Money`.
    /// Traps if the integer part exceeds `UInt32` range.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
    /// UInt32(v)  // 42
    /// ```
    ///
    /// The `Int` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// UInt32(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// UInt32(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The integer part must fit in `UInt32`.
    public init<C: Currency>(_ value: Money<C>) {
        guard let narrow = UInt32(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds UInt32 range")
        }
        self = narrow
    }

    /// Creates a `UInt32` from a `Money`, returning `nil` if the
    /// minor units exceed `UInt32` range.
    ///
    /// ```swift
    /// UInt32(exactly: Money<GBP>(minorUnits: 42))    // Optional(42)
    /// ```
    ///
    /// The `UInt32` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// UInt32(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// UInt32(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: A `UInt32` if the conversion is exact, otherwise `nil`.
    public init?<C: Currency>(exactly value: Money<C>) {
        guard let narrow = UInt32(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

// MARK: - ExpressibleByIntegerLiteral (poisoned)

extension Money {
    @available(*, unavailable, message: "Use Money(minorUnits:) for explicit minor-unit values")
    public init(integerLiteral value: IntegerLiteralType) {
        fatalError("Use Money(minorUnits:) for explicit minor-unit values")
    }
}

#warning("Remove minimum/maximum")
// MARK: - minimum / maximum

extension Money {
    /// Returns the lesser of the two given values.
    ///
    /// ```swift
    /// Money<GBP>.minimum(3, 5)     // 3
    /// Money<GBP>.minimum(-1, 1)    // -1
    /// ```
    ///
    /// - Parameters:
    ///   - x: A value to compare.
    ///   - y: Another value to compare.
    /// - Returns: The lesser of `x` and `y`.
    /// - Complexity: O(1) -- single integer comparison.
    public static func minimum(_ x: Self, _ y: Self) -> Self {
        x.minorUnits <= y.minorUnits ? x : y
    }

    /// Returns the greater of the two given values.
    ///
    /// ```swift
    /// Money.maximum(3, 5)     // 5
    /// Money.maximum(-1, 1)    // 1
    /// ```
    ///
    /// - Parameters:
    ///   - x: A value to compare.
    ///   - y: Another value to compare.
    /// - Returns: The greater of `x` and `y`.
    /// - Complexity: O(1) -- single integer comparison.
    public static func maximum(_ x: Self, _ y: Self) -> Self {
        x.minorUnits >= y.minorUnits ? x : y
    }
}

// MARK: - Random

#warning("Remove `random` functions")
extension Money {

    /// Returns a random value within the specified closed range.
    ///
    /// - Parameter range: The range in which to create a random value.
    /// - Returns: A random value within the bounds of `range`.
    public static func random(in range: ClosedRange<Money>) -> Money {
        let raw = Int64.random(
            in: range.lowerBound.minorUnits...range.upperBound.minorUnits
        )
        return Money(minorUnits: raw)
    }

    /// Returns a random value within the specified closed range, using the given
    /// generator as a source for randomness.
    ///
    /// - Parameters:
    ///   - range: The range in which to create a random value.
    ///   - generator: The random number generator to use when creating the
    ///     new random value.
    /// - Returns: A random value within the bounds of `range`.
    public static func random<T: RandomNumberGenerator>(
        in range: ClosedRange<Money>,
        using generator: inout T
    ) -> Money {
        let raw = Int64.random(
            in: range.lowerBound.minorUnits...range.upperBound.minorUnits,
            using: &generator
        )
        return Money(minorUnits: raw)
    }

    /// Returns a random value within the specified half-open range.
    ///
    /// - Parameter range: The range in which to create a random value.
    ///   `range` must not be empty.
    /// - Returns: A random value within the bounds of `range`.
    /// - Precondition: `range` must not be empty.
    public static func random(in range: Range<Money>) -> Money {
        let raw = Int64.random(
            in: range.lowerBound.minorUnits..<range.upperBound.minorUnits
        )
        return Money(minorUnits: raw)
    }

    /// Returns a random value within the specified half-open range, using the given
    /// generator as a source for randomness.
    ///
    /// - Parameters:
    ///   - range: The range in which to create a random value.
    ///     `range` must not be empty.
    ///   - generator: The random number generator to use when creating the
    ///     new random value.
    /// - Returns: A random value within the bounds of `range`.
    /// - Precondition: `range` must not be empty.
    public static func random<T: RandomNumberGenerator>(
        in range: Range<Money>,
        using generator: inout T
    ) -> Money {
        let raw = Int64.random(
            in: range.lowerBound.minorUnits..<range.upperBound.minorUnits,
            using: &generator
        )
        return Money(minorUnits: raw)
    }
}

#if canImport(Foundation)
import Foundation

// MARK: - Codable

extension Money: Codable {

    // MARK: Private coding key

    private enum CodingKey: String, Swift.CodingKey {
        case currencyCode
        case amount
    }

    // MARK: - Encoding

    /// Encodes this `Money` value using the strategy configured on the encoder.
    ///
    /// The active strategy is read from `encoder.userInfo[.moneyEncodingStrategy]`
    /// (set via ``JSONEncoder/moneyEncodingStrategy``). When no strategy is
    /// configured, ``MoneyEncodingStrategy/object`` is used, producing:
    ///
    /// ```json
    /// {"currencyCode":"GBP","amount":1.25}
    /// ```
    ///
    /// - SeeAlso: ``JSONEncoder/moneyEncodingStrategy``
    public func encode(to encoder: any Encoder) throws {
        let strategy = encoder.userInfo[.moneyEncodingStrategy] as? MoneyEncodingStrategy ?? .object
        switch strategy {
        case .minorUnits:
            try _encodeMinorUnits(to: encoder)
        case .majorUnits:
            try _encodeMajorUnits(to: encoder)
        case .string(let locale):
            try _encodeString(locale: locale, to: encoder)
        case .object(let amountStrategy):
            try _encodeObject(amountStrategy: amountStrategy, to: encoder)
        }
    }

    // MARK: - Decoding

    /// Creates a `Money` by decoding from the given decoder.
    ///
    /// The active strategy is read from `decoder.userInfo[.moneyDecodingStrategy]`
    /// (set via ``JSONDecoder/moneyDecodingStrategy``). When no strategy is
    /// configured, ``MoneyDecodingStrategy/object`` is used, expecting:
    ///
    /// ```json
    /// {"currencyCode":"GBP","amount":1.25}
    /// ```
    ///
    /// The decoding strategy **must** match the encoding strategy that produced
    /// the data, or a `DecodingError` will be thrown.
    ///
    /// - SeeAlso: ``JSONDecoder/moneyDecodingStrategy``
    public init(from decoder: any Decoder) throws {
        let strategy = decoder.userInfo[.moneyDecodingStrategy] as? MoneyDecodingStrategy ?? .object
        switch strategy {
        case .minorUnits:
            self = try Money._decodeMinorUnits(from: decoder)
        case .majorUnits:
            self = try Money._decodeMajorUnits(from: decoder)
        case .string(let locale):
            self = try Money._decodeString(locale: locale, from: decoder)
        case .object(let amountStrategy):
            self = try Money._decodeObject(amountStrategy: amountStrategy, from: decoder)
        }
    }

    // MARK: - Private encode helpers

    private func _encodeMinorUnits(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(minorUnits)
    }

    private func _encodeMajorUnits(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_majorUnitsDecimal())
    }

    private func _encodeString(locale: Locale, to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.formatted(Money<Currency>.FormatStyle().locale(locale)))
    }

    private func _encodeObject(amountStrategy: MoneyAmountEncodingStrategy, to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKey.self)
        try container.encode(Currency.code.stringValue, forKey: .currencyCode)
        switch amountStrategy {
        case .minorUnits:
            try container.encode(minorUnits, forKey: .amount)
        case .majorUnits:
            try container.encode(_majorUnitsDecimal(), forKey: .amount)
        case .string(let locale):
            try container.encode(self.formatted(Money<Currency>.FormatStyle().locale(locale)), forKey: .amount)
        }
    }

    // MARK: - Private decode helpers

    private static func _decodeMinorUnits(from decoder: any Decoder) throws -> Money<Currency> {
        let container = try decoder.singleValueContainer()
        let minorUnits = try container.decode(Int64.self)
        guard let money = Money<Currency>(exactly: minorUnits) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Minor-unit value \(minorUnits) cannot be represented as Money."
            )
        }
        return money
    }

    private static func _decodeMajorUnits(from decoder: any Decoder) throws -> Money<Currency> {
        let container = try decoder.singleValueContainer()
        let decimal = try container.decode(Decimal.self)
        return try _decimalToMoney(decimal, codingPath: decoder.codingPath)
    }

    private static func _decodeString(locale: Locale, from decoder: any Decoder) throws -> Money<Currency> {
        let container = try decoder.singleValueContainer()
        let formattedAmount = try container.decode(String.self)
        do {
            return try Money<Currency>(formattedAmount, format: Money<Currency>.FormatStyle().locale(locale))
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Could not parse '\(formattedAmount)' as \(Currency.code) using the configured locale."
            )
        }
    }

    private static func _decodeObject(amountStrategy: MoneyAmountDecodingStrategy, from decoder: any Decoder) throws -> Money<Currency> {
        let container = try decoder.container(keyedBy: CodingKey.self)

        let encodedCurrencyCode = try container.decode(String.self, forKey: .currencyCode)
        guard encodedCurrencyCode == Currency.code.stringValue else {
            let context = DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Currency mismatch: expected \(Currency.code), got '\(encodedCurrencyCode)'."
            )
            throw DecodingError.typeMismatch(Money<Currency>.self, context)
        }

        switch amountStrategy {
        case .minorUnits:
            let minorUnits = try container.decode(Int64.self, forKey: .amount)
            guard let money = Money<Currency>(exactly: minorUnits) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .amount,
                    in: container,
                    debugDescription: "Minor-unit value \(minorUnits) cannot be represented as Money."
                )
            }
            return money
        case .majorUnits:
            let decimal = try container.decode(Decimal.self, forKey: .amount)
            return try _decimalToMoney(decimal, codingPath: container.codingPath)
        case .string(let locale):
            let formattedAmount = try container.decode(String.self, forKey: .amount)
            do {
                return try Money<Currency>(formattedAmount, format: Money<Currency>.FormatStyle().locale(locale))
            } catch {
                throw DecodingError.dataCorruptedError(
                    forKey: .amount,
                    in: container,
                    debugDescription: "Could not parse '\(formattedAmount)' as \(Currency.code) using the configured locale."
                )
            }
        }
    }

    // MARK: - Shared arithmetic helpers

    /// Converts minor units to major-unit `Decimal` for encoding.
    private func _majorUnitsDecimal() -> Decimal {
        let quantisation = Decimal(Currency.minimalQuantisation.int64Value)
        return Decimal(minorUnits) / quantisation
    }

    /// Converts a major-unit `Decimal` into a `Money` value by multiplying by
    /// `minimalQuantisation` and rounding to the nearest minor unit (`.plain`).
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the result overflows `Int64`.
    private static func _decimalToMoney(_ decimal: Decimal, codingPath: [any Swift.CodingKey]) throws -> Money<Currency> {
        let quantisation = Decimal(Currency.minimalQuantisation.int64Value)
        var product = decimal * quantisation
        var rounded = Decimal()
        NSDecimalRound(&rounded, &product, 0, .plain)
        let roundedMinorUnits = (rounded as NSDecimalNumber).int64Value
        guard Decimal(roundedMinorUnits) == rounded else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Decoded major-unit value \(decimal) overflows the Int64 minor-unit range."
            )
            throw DecodingError.dataCorrupted(context)
        }
        guard let money = Money<Currency>(exactly: roundedMinorUnits) else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Decoded minor-unit value \(roundedMinorUnits) cannot be represented as Money."
            )
            throw DecodingError.dataCorrupted(context)
        }
        return money
    }
}

// MARK: - Decimal -> Money Conversion

extension Money {
    /// Creates a value from a `Foundation.Decimal`.
    /// The `Decimal` value must be a valid representation of a `Money` amount
    /// in its given currency.
    ///
    /// Traps if the input is `Decimal.nan`.
    ///
    /// ```swift
    /// let pounds = Decimal(123.45)
    /// _ = Money<GBP>(pounds)  // £123.45
    ///
    /// let invalidPounds = Decimal(123.456)
    /// _ = Money<GBP>(invalidPounds)   // terminates execution on precondition
    /// ```
    ///
    /// - Parameter decimal: The `Foundation.Decimal` value to convert.
    /// - Precondition: The  `Decimal` value must be an exact valid amount in
    /// the associated currency.
    /// - Precondition: The scaled result must fit in `Int64`.
    /// - Precondition: The `scaleFactor` of the currency must not be 0.
    public init(_ decimal: Decimal) {
        #warning("This whole function replicates `init(exactly:)` -- call that and throw precondition if nil")

        precondition(!decimal.isNaN, "Cannot create Money from Decimal.nan")

        let factor = Decimal(Currency.minimalQuantisation.int64Value)

        precondition(
            factor != .zero,
            "Currency minimalQuantisation is zero — divide by zero error"
        )

        let scaled = decimal * factor
        let int64Value = NSDecimalNumber(decimal: scaled).int64Value

        // Overflow check: round-trip must match
        precondition(
            Decimal(int64Value) == scaled,
            "Decimal value \(decimal) overflows Money range"
        )

        #warning("Can we use a `MinorUnits` here instead of the precondition?")
        // Guard: must be representable as Storage
        precondition(
            int64Value != .min,
            "Decimal value \(decimal) is not representable as a minor-unit value"
        )

        self = Self(minorUnits: int64Value)
    }

    /// Creates a value from a `Foundation.Decimal`. Returns `nil` if the
    /// scaled result does not fit in `Int64`, if the `scaleFactor` of the currency is 0,
    /// or if the `Decimal` value is not a valid representation of a `Money` amount
    /// in its given currency
    ///
    /// Returns `nil` if the input is `Decimal.nan`.
    ///
    /// ```swift
    /// let pounds = Decimal(123.45)
    /// _ = Money<GBP>(exactly: pounds)  // Optional(Money<GBP>(123.45))
    ///
    /// let invalidPounds = Decimal(123.456)
    /// _ = Money<GBP>(exactly: invalidPounds)   // nil
    /// ```
    ///
    /// - Parameter decimal: The `Foundation.Decimal` value to convert.
    /// - Returns: A `Money` if the value is representable, otherwise `nil`.
    public init?(exactly decimal: Decimal) {
        if decimal.isNaN { return nil }

        let factor = Decimal(Currency.minimalQuantisation.int64Value)

        guard factor != .zero else { return nil }

        let scaled = decimal * factor
        let int64Value = NSDecimalNumber(decimal: scaled).int64Value

        // Overflow check: round-trip must match
        guard Decimal(int64Value) == scaled else { return nil }

        // Guard: must be representable as Storage
        guard int64Value != .min else { return nil }

        self = Self(minorUnits: int64Value)
    }
}

extension Decimal {
    /// Creates a `Decimal` from a `Money`. Always exact.
    ///
    /// ```swift
    /// let money = Money<GBP>(99.95)   // £99.95
    /// let decimal = Decimal(money)    // Decimal(99.95)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    public init<C: Currency>(_ value: Money<C>) {
        self = Decimal(value.minorUnits) / Decimal(C.minimalQuantisation.int64Value)
    }
}
#endif
