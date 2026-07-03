public struct Money<Currency: SwiftMoney.Currency>: Sendable {
    #warning("Remove `MinorUnits`")
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
    /// Returns the additive inverse of the specified value.
    ///
    /// The negation operator (prefix `-`) returns the additive inverse of its
    /// argument.
    ///
    /// ```swift
    /// let price = Money<GBP>(4250) // £42.50
    /// let neg = -price  // -£42.50
    /// ```
    ///
    /// The resulting value must be representable in the same type as the
    /// argument. Negating `Money.min` results in a value that cannot
    /// be represented.
    ///
    ///     let z = -Money<GBP>.min
    ///     // Overflow error
    ///
    /// - Returns: The additive inverse of this value.
    public prefix static func - (operand: Money) -> Money {
        var copy = operand
        copy.negate()
        return copy
    }

    /// Replaces this value with its additive inverse.
    ///
    /// The following example uses the `negate()` method to negate the value of
    /// a `Money`, `x`:
    ///
    /// ```swift
    /// var price = Money<GBP>(4250) // £42.50
    /// price.negate()
    /// // price is now -4250 (-£42.50)
    /// ```
    ///
    /// The resulting value must be representable within the value's type.
    /// Negating a `Money.min` results in a value that cannot be
    /// represented.
    ///
    ///     var y = Money<GBP>.min
    ///     y.negate()
    ///     // Overflow error
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

// MARK: - Rate Multiplication

#warning("Why does this require `Foundation`? If because of `FloatingPointRoundingRule`, perhaps this should be replaced by a framework-specific variant")
extension Money {

    /// Returns the result of multiplying this value by the given fractional rate.
    ///
    /// Because money is stored as a discrete integer number of minor units,
    /// fractional multiplication almost always produces a theoretically
    /// fractional intermediate result that must be rounded. The returned
    /// ``RateCalculation`` carries both the rounded amount
    /// and the **actual rate that was applied**, so callers can account for
    /// the rounding in downstream calculations.
    ///
    /// The round-trip invariant holds: `input × effectiveRate == result`.
    ///
    /// ```swift
    /// // £1.01 × 1% — rounds down to £0.01; actual rate is 1/101 not 1/100
    /// let r = Money<GBP>(minorUnits: 101).multiplied(
    ///     by: Rate(numerator: 1, denominator: 100)
    /// )
    /// r.amount      // Money<GBP>(minorUnits: 1)
    /// r.effectiveRate  // Rate(numerator: 1, denominator: 101)
    /// ```
    ///
    /// - Parameters:
    ///   - rate: The fractional rate to multiply by.
    ///   - rounding: The rounding rule to apply when the result is not a whole
    ///     number of minor units. Defaults to `.toNearestOrAwayFromZero`.
    /// - Returns: A `RateCalculation` containing the rounded
    ///   result and the actual rate applied.
    public func multiplied(
        by rate: Rate,
        rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> RateCalculation<Currency> {
        // Zero input: 0 × anything == 0; rate is undefined so return input rate.
        if minorUnits == 0 {
            return RateCalculation(amount: .zero, effectiveRate: rate)
        }

        // Multiply in Int128 to avoid Int64 overflow (max product ≈ 8.5×10³⁷ < Int128.max).
        let product = Int128(minorUnits) * Int128(rate.numeratorValue)
        let denominator = Int128(rate.denominatorValue)
        let (truncated, remainder) = product.quotientAndRemainder(dividingBy: denominator)

        // Apply the caller's rounding rule using pure integer comparisons.
        let minorUnits128 = _roundInt128(
            truncated: truncated,
            remainder: remainder,
            denominator: denominator,
            rule: rounding
        )

        // Bounds check: result must fit in Int64.
        guard let minorUnits = Int64(exactly: minorUnits128) else {
            preconditionFailure("Money fractional multiplication result overflows Int64")
        }

        let resultMoney = Money(minorUnits: minorUnits)
        let effectiveRate = _effectiveRate(result: minorUnits, input: self.minorUnits)

        return RateCalculation(amount: resultMoney, effectiveRate: effectiveRate)
    }

    /// Builds the effective rate = result / input in lowest terms,
    /// normalised so the denominator is positive (Rate contract).
    ///
    /// - Precondition: `input` must not be 0 or `Int64.min`.
    private func _effectiveRate(result: Int64, input: Int64) -> Rate {
        if input > 0 {
            return Rate(_unchecked: result, denominator: input)
        } else {
            return Rate(_unchecked: -result, denominator: -input)
        }
    }
}

// MARK: - Operators

extension Money {

    /// Returns the result of multiplying this `Money` value by a `Rate`.
    ///
    /// Uses `.toNearestOrAwayFromZero` rounding. To specify a different rounding
    /// rule, call ``multiplied(by:rounding:)`` directly.
    ///
    /// ```swift
    /// let r = Money<GBP>(minorUnits: 101) * Rate(numerator: 1, denominator: 100)
    /// r.amount      // Money<GBP>(minorUnits: 1)
    /// r.effectiveRate  // Rate(numerator: 1, denominator: 101)
    /// ```
    public static func * (
        lhs: Money,
        rhs: Rate
    ) -> RateCalculation<Currency> {
        lhs.multiplied(by: rhs)
    }

    /// Returns the result of multiplying this `Money` value by a `Decimal` rate.
    ///
    /// Converts `rhs` to a ``Rate`` via ``Rate/init(_:)``
    /// and then calls ``multiplied(by:rounding:)`` with
    /// `.toNearestOrAwayFromZero` rounding.
    ///
    /// > Warning: `Decimal` floating-point literals (e.g. `* 0.01`) are
    /// > initialised via `Double` and lose precision. Always prefer
    /// > `Decimal(string: "0.01")!` or an explicit
    /// > `Rate(numerator: 1, denominator: 100)`.
    ///
    /// ```swift
    /// // Precise:
    /// let r = Money<GBP>(minorUnits: 101) * Decimal(string: "0.01")!
    ///
    /// // Imprecise (Decimal literal goes through Double):
    /// // let r = Money<GBP>(minorUnits: 101) * 0.01  ← avoid
    /// ```
    ///
    /// - Returns: `nil` if `rhs` cannot be converted to a `Rate`
    ///   (e.g. it is NaN, has an exponent ≥ 19, or its significand overflows `Int64`).
    public static func * (
        lhs: Money,
        rhs: Decimal
    ) -> RateCalculation<Currency>? {
        guard let rate = Rate(rhs) else { return nil }
        return lhs.multiplied(by: rate)
    }
}

#warning("Should this be in its own `Utils` file?")
// MARK: - Internal helpers

/// Applies a `FloatingPointRoundingRule` to an integer division result expressed
/// as `truncated + remainder/denominator`.
///
/// `truncated` is the result of truncating division (toward zero). `remainder`
/// carries the same sign as the dividend (Swift's `%` contract). `denominator`
/// is always positive (enforced by `Rate`).
///
/// Proof that the tie comparison `abs(r)*2` never overflows `Int128`:
/// - `abs(remainder) < denominator ≤ Int64.max`
/// - Therefore `abs(remainder)*2 < 2×Int64.max ≪ Int128.max`
internal func _roundInt128(
    truncated: Int128,
    remainder: Int128,
    denominator: Int128,
    rule: FloatingPointRoundingRule
) -> Int128 {
    guard remainder != 0 else { return truncated }

    switch rule {
    case .towardZero:
        // Truncating division already rounds toward zero.
        return truncated

    case .down:
        // Floor: subtract 1 if there is a negative fractional part.
        return remainder < 0 ? truncated - 1 : truncated

    case .up:
        // Ceiling: add 1 if there is a positive fractional part.
        return remainder > 0 ? truncated + 1 : truncated

    case .awayFromZero:
        // Away from zero: add 1 for positive remainder, subtract 1 for negative.
        return remainder > 0 ? truncated + 1 : truncated - 1

    case .toNearestOrAwayFromZero:
        // Round half away from zero (HALF_UP / commercial rounding).
        let absoluteRemainder = remainder < 0 ? -remainder : remainder
        let halfway = absoluteRemainder * 2 >= denominator
        if !halfway { return truncated }
        return remainder > 0 ? truncated + 1 : truncated - 1

    case .toNearestOrEven:
        // Banker's rounding (IEEE 754 default): round half to even.
        let absoluteRemainder = remainder < 0 ? -remainder : remainder
        let doubledRemainder = absoluteRemainder * 2
        if doubledRemainder < denominator { return truncated }          // below half: truncate
        if doubledRemainder > denominator {                              // above half: round away
            return remainder > 0 ? truncated + 1 : truncated - 1
        }
        // Exact half: round to even — adjust only if truncated is odd.
        let isTruncatedOdd = truncated % 2 != 0
        if isTruncatedOdd {
            return remainder > 0 ? truncated + 1 : truncated - 1
        }
        return truncated

    @unknown default:
        // Safe fallback: HALF_UP.
        let absoluteRemainder = remainder < 0 ? -remainder : remainder
        let halfway = absoluteRemainder * 2 >= denominator
        if !halfway { return truncated }
        return remainder > 0 ? truncated + 1 : truncated - 1
    }
}

// MARK: - FormatStyle

extension Money {

    /// A format style that produces a localised currency string for a `Money` value.
    ///
    /// `Money.FormatStyle` mirrors the modifier API of `IntegerFormatStyle.Currency`
    /// and delegates to it internally, automatically scaling minor units to major
    /// units for display via the currency's `minimalQuantisation`.
    ///
    /// ```swift
    /// let style = Money<GBP>.FormatStyle()
    ///     .locale(Locale(identifier: "en_GB"))
    ///     .sign(strategy: .always())
    ///
    /// style.format(Money<GBP>(minorUnits: 150))  // "+£1.50"
    /// ```
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {

        public typealias Configuration = CurrencyFormatStyleConfiguration

        // MARK: - Stored state (var for copy-on-modify pattern)

        private var locale: Locale
        private var signDisplayStrategy: Configuration.SignDisplayStrategy
        private var presentation: Configuration.Presentation
        private var grouping: Configuration.Grouping?
        private var precision: Configuration.Precision?
        private var decimalSeparatorStrategy: Configuration.DecimalSeparatorDisplayStrategy?
        private var roundedRule: Configuration.RoundingRule?
        private var roundedIncrement: Int?
        private var notation: Configuration.Notation?

        // MARK: - Initialiser

        public init() {
            self.locale = .autoupdatingCurrent
            self.signDisplayStrategy = .automatic
            self.presentation = .standard
            self.grouping = nil
            self.precision = nil
            self.decimalSeparatorStrategy = nil
            self.roundedRule = nil
            self.roundedIncrement = nil
            self.notation = nil
        }

        // MARK: - Modifiers

        public func locale(_ locale: Locale) -> FormatStyle {
            var copy = self
            copy.locale = locale
            return copy
        }

        public func sign(strategy: Configuration.SignDisplayStrategy) -> FormatStyle {
            var copy = self
            copy.signDisplayStrategy = strategy
            return copy
        }

        public func presentation(_ presentation: Configuration.Presentation) -> FormatStyle {
            var copy = self
            copy.presentation = presentation
            return copy
        }

        public func grouping(_ grouping: Configuration.Grouping) -> FormatStyle {
            var copy = self
            copy.grouping = grouping
            return copy
        }

        public func precision(_ precision: Configuration.Precision) -> FormatStyle {
            var copy = self
            copy.precision = precision
            return copy
        }

        public func decimalSeparator(
            strategy: Configuration.DecimalSeparatorDisplayStrategy
        ) -> FormatStyle {
            var copy = self
            copy.decimalSeparatorStrategy = strategy
            return copy
        }

        public func rounded(
            rule: Configuration.RoundingRule = .toNearestOrEven,
            increment: Int? = nil
        ) -> FormatStyle {
            var copy = self
            copy.roundedRule = rule
            copy.roundedIncrement = increment
            return copy
        }

        public func notation(_ notation: Configuration.Notation) -> FormatStyle {
            var copy = self
            copy.notation = notation
            return copy
        }
    }
}

// MARK: - Internal style builders

#warning("Should these be private? Are they really needed?")
extension Money.FormatStyle {
    /// Builds the `IntegerFormatStyle<Int64>.Currency` that `format(_:)` uses.
    internal func _integerFormatStyle() -> IntegerFormatStyle<Int64>.Currency {
        let minQScale = 1.0 / Double(Currency.minimalQuantisation.int64Value)

        var style = IntegerFormatStyle<Int64>.Currency(
            code: Currency.code.stringValue,
            locale: locale
        )
        style = style.presentation(presentation)
        style = style.scale(minQScale)
        // Only set sign when non-automatic: explicitly setting sign-auto in the ICU skeleton
        // conflicts with group-off on macOS 15+/26, and auto is ICU's implicit default anyway.
        if signDisplayStrategy != .automatic { style = style.sign(strategy: signDisplayStrategy) }
        if let grouping                 { style = style.grouping(grouping) }
        if let precision                { style = style.precision(precision) }
        if let decimalSeparatorStrategy { style = style.decimalSeparator(strategy: decimalSeparatorStrategy) }
        if let roundedRule              { style = style.rounded(rule: roundedRule, increment: roundedIncrement) }
        if let notation                 { style = style.notation(notation) }
        return style
    }

    /// Builds a `Decimal.FormatStyle.Currency` with the same display parameters
    /// as `_integerFormatStyle()` but **without** the minor-unit scale.
    ///
    /// Used by `Money.ParseStrategy` to convert a formatted currency string back
    /// to a major-unit `Decimal` before manually inverting the scale.
    ///
    /// `IntegerFormatStyle<Int64>.Currency.parseStrategy` cannot be used for this
    /// because it does not invert the scale; it truncates the displayed value to
    /// an integer directly. Parsing via `Decimal.FormatStyle.Currency` (same ICU
    /// locale data, same display modifiers, no scale) gives us the exact
    /// displayed decimal value, from which scale inversion is straightforward.
    internal func _decimalFormatStyle() -> Decimal.FormatStyle.Currency {
        var style = Decimal.FormatStyle.Currency(
            code: Currency.code.stringValue,
            locale: locale
        )
        style = style.presentation(presentation)
        // Mirror the sign-auto guard from _integerFormatStyle().
        if signDisplayStrategy != .automatic { style = style.sign(strategy: signDisplayStrategy) }
        if let grouping                 { style = style.grouping(grouping) }
        if let precision                { style = style.precision(precision) }
        if let decimalSeparatorStrategy { style = style.decimalSeparator(strategy: decimalSeparatorStrategy) }
        if let roundedRule              { style = style.rounded(rule: roundedRule, increment: roundedIncrement) }
        if let notation                 { style = style.notation(notation) }
        // scale is intentionally NOT applied — the caller inverts scale manually.
        return style
    }

    /// Parses a formatted currency string back to a `Money` value.
    ///
    /// Algorithm:
    /// 1. Parse the string via `_decimalFormatStyle()` → displayed major-unit `Decimal`.
    /// 2. Convert: `minor_units = displayed × minQ`.
    /// 3. Round half-up and convert to `Int64`.
    internal func _parse(_ value: String) throws -> Money<Currency> {
        let quantisation = Decimal(Currency.minimalQuantisation.int64Value)

        let displayed = try _decimalFormatStyle().parseStrategy.parse(value)

        var product = displayed * quantisation
        var rounded = Decimal()
        NSDecimalRound(&rounded, &product, 0, .plain)   // round half-up

        let roundedMinorUnits = (rounded as NSDecimalNumber).int64Value
        guard Decimal(roundedMinorUnits) == rounded else { throw Money<Currency>.ParseStrategy.ParseError.overflow }
        guard roundedMinorUnits != .min             else { throw Money<Currency>.ParseStrategy.ParseError.overflow }
        return Money<Currency>(minorUnits: roundedMinorUnits)
    }
}

// MARK: - Foundation.FormatStyle conformance

extension Money.FormatStyle: Foundation.FormatStyle {
    public func format(_ value: Money) -> String {
        value.minorUnits.formatted(_integerFormatStyle())
    }
}

// MARK: - Convenience

extension Money {
    /// Formats `self` using the default `Money.FormatStyle()`.
    public func formatted() -> String {
        FormatStyle().format(self)
    }

    /// Formats `self` using the given format style.
    public func formatted(_ format: FormatStyle) -> String {
        format.format(self)
    }
}

// MARK: - Static factory shorthand
//
// Enables dot-syntax at call sites where the argument type is known:
//   money.formatted(.grouping(.never))
//   money.formatted(.precision(.fractionLength(0)).locale(enGB))

extension Money.FormatStyle {
    /// Returns a style with the given locale.
    ///
    /// ```swift
    /// money.formatted(.locale(Locale(identifier: "en_GB")))
    /// ```
    public static func locale(_ locale: Locale) -> Self {
        Self().locale(locale)
    }

    /// Returns a style with the given sign strategy.
    ///
    /// ```swift
    /// money.formatted(.sign(strategy: .always()))
    /// ```
    public static func sign(strategy: Configuration.SignDisplayStrategy) -> Self {
        Self().sign(strategy: strategy)
    }

    /// Returns a style with the given presentation.
    ///
    /// ```swift
    /// money.formatted(.presentation(.isoCode))
    /// ```
    public static func presentation(_ presentation: Configuration.Presentation) -> Self {
        Self().presentation(presentation)
    }

    /// Returns a style with the given grouping.
    ///
    /// ```swift
    /// money.formatted(.grouping(.never))
    /// ```
    public static func grouping(_ grouping: Configuration.Grouping) -> Self {
        Self().grouping(grouping)
    }

    /// Returns a style with the given precision.
    ///
    /// ```swift
    /// money.formatted(.precision(.fractionLength(0)))
    /// ```
    public static func precision(_ precision: Configuration.Precision) -> Self {
        Self().precision(precision)
    }

    /// Returns a style with the given decimal separator strategy.
    ///
    /// ```swift
    /// money.formatted(.decimalSeparator(strategy: .always))
    /// ```
    public static func decimalSeparator(strategy: Configuration.DecimalSeparatorDisplayStrategy) -> Self {
        Self().decimalSeparator(strategy: strategy)
    }

    /// Returns a style with the given rounding rule and optional increment.
    ///
    /// ```swift
    /// money.formatted(.rounded(rule: .up))
    /// ```
    public static func rounded(
        rule: Configuration.RoundingRule = .toNearestOrEven,
        increment: Int? = nil
    ) -> Self {
        Self().rounded(rule: rule, increment: increment)
    }

    /// Returns a style with the given notation.
    ///
    /// ```swift
    /// money.formatted(.notation(.compactName))
    /// ```
    public static func notation(_ notation: Configuration.Notation) -> Self {
        Self().notation(notation)
    }
}

// MARK: - ParseStrategy

extension Money {

    /// A parse strategy that reconstructs a `Money` value from a formatted
    /// currency string produced by `Money.FormatStyle`.
    ///
    /// Obtain a strategy through `Money<C>.FormatStyle.parseStrategy` or the
    /// `ParseableFormatStyle` conformance; do not initialise directly.
    ///
    /// ```swift
    /// let style = Money<GBP>.FormatStyle().locale(Locale(identifier: "en_GB"))
    /// let pounds = try style.parseStrategy.parse("£1.50")
    /// // pounds == Money<GBP>(minorUnits: 150)
    /// ```
    ///
    /// ## Round-trip guarantee
    ///
    /// Any string produced by the corresponding `FormatStyle.format(_:)` will
    /// parse back to the original value:
    ///
    /// ```swift
    /// let style = Money<GBP>.FormatStyle().locale(Locale(identifier: "en_GB"))
    /// let original = Money<GBP>(minorUnits: 1234)
    /// let string   = style.format(original)           // "£12.34"
    /// let parsed   = try style.parseStrategy.parse(string)
    /// // parsed == original
    /// ```
    public struct ParseStrategy: Foundation.ParseStrategy, Codable, Hashable, Sendable {

        public typealias ParseInput  = String
        public typealias ParseOutput = Money<Currency>

        internal let formatStyle: Money<Currency>.FormatStyle

        internal init(formatStyle: Money<Currency>.FormatStyle) {
            self.formatStyle = formatStyle
        }

        /// Parses `value` and returns the corresponding `Money`.
        ///
        /// Delegates all arithmetic to `FormatStyle._parse(_:)`, which has
        /// direct access to the private stored `userScale` property.
        ///
        /// - Parameter value: A string in the format produced by the associated
        ///   `Money.FormatStyle`.
        /// - Returns: The `Money` value whose `format()` output matches `value`.
        /// - Throws: A Foundation `ParseError` if `value` does not match the
        ///   expected format, or ``ParseError/overflow`` if the result is
        ///   outside the `Int64` representable range.
        public func parse(_ value: String) throws -> Money<Currency> {
            try formatStyle._parse(value)
        }
    }
}

// MARK: - ParseError

extension Money.ParseStrategy {

    /// Errors thrown when a `Money.ParseStrategy` cannot parse an input string.
    public enum ParseError: Error, LocalizedError, Sendable {

        /// The parsed integer value is outside the representable range.
        case overflow

        public var errorDescription: String? {
            switch self {
            case .overflow:
                return "The parsed value cannot be represented as a Money amount (Int64 overflow)."
            }
        }
    }
}

// MARK: - ParseableFormatStyle conformance

extension Money.FormatStyle: ParseableFormatStyle {
    /// The parse strategy derived from this format style.
    ///
    /// The returned strategy uses the same ICU skeleton parameters as
    /// `format(_:)`, guaranteeing a correct format ↔ parse round-trip.
    public var parseStrategy: Money<Currency>.ParseStrategy {
        Money<Currency>.ParseStrategy(formatStyle: self)
    }
}

// MARK: - Convenience initialiser

extension Money {
    
    /// Creates a `Money` value by parsing a formatted currency string.
    ///
    /// ```swift
    /// let style = Money<GBP>.FormatStyle().locale(Locale(identifier: "en_GB"))
    /// let money = try Money<GBP>("£12.34", format: style)
    /// money.minorUnits  // 1234
    /// ```
    ///
    /// - Parameters:
    ///   - string: A string in the format produced by `format`.
    ///   - format: The `Money.FormatStyle` used to interpret the string.
    /// - Throws: A parse error if `string` does not match `format`.
    public init(_ string: String, format: Money<Currency>.FormatStyle) throws {
        self = try format.parseStrategy.parse(string)
    }
}
#endif
