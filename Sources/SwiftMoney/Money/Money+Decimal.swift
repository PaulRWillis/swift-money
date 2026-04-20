#warning("Should this be an `if canImport`?")
import Foundation

extension Money {
    /// The value as a `Foundation.Decimal`. Backwards-compatibility convenience for `Decimal(self)`.
    ///
    /// Returns `Decimal.nan` for NaN.
    @inlinable
    public var decimalValue: Decimal {
        if isNaN { return Decimal.nan }
        return Decimal(_storage) / Decimal(Self.scaleFactor)
    }
}

extension Money {
    /// Creates a value from a `Foundation.Decimal`.
    /// The Decimal value must be a valid representation of a `Money` amount
    /// in its given currency.
    ///
    /// Creates `.nan` if the input is `Decimal.nan`.
    ///
    /// ```swift
    /// let pounds = Decimal(string: "123.45")!
    /// let value = Money<GBP>(pounds)  // £123.45
    ///
    /// let invalidPounds = Decimal(string: "123.456")!
    /// _ = Money<GBP>(invalidPounds)   // terminates execution on precondition
    /// ```
    ///
    /// - Parameter decimal: The `Foundation.Decimal` value to convert.
    /// - Precondition: The  `Decimal` value must be an exact valid amount in
    /// the associated currency.
    /// - Precondition: The scaled result must fit in `Int64`.
    /// - Precondition: The `scaleFactor` of the currency must not be 0.
    public init(_ decimal: Decimal) {
        if decimal.isNaN {
            self = .nan
            return
        }
        var scaled = Decimal()
        var value = decimal
        var factor = Decimal(Self.scaleFactor)

        precondition(
            factor != .zero,
            "Currency scaleFactor is zero. Divide by zero error"
        )

        _ = NSDecimalMultiply(&scaled, &value, &factor, .plain)

        let int64Value = NSDecimalNumber(decimal: scaled).int64Value

        // Overflow check: round-trip must match
        precondition(
            Decimal(int64Value) == scaled,
            "Decimal value \(decimal) overflows Money range"
        )
        // Guard against NaN sentinel
        precondition(
            int64Value != .min,
            "Decimal value \(decimal) maps to NaN sentinel"
        )

        self._storage = int64Value
    }
}

//extension Decimal {
//    /// Creates a `Decimal` from a `Money`.
//    ///
//    /// ```swift
//    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
//    /// Int(v)  // 42
//    /// ```
//    ///
//    /// The `Int` value represents the number of minor units in the money
//    /// type, not the major unit of the money value.
//    ///
//    /// ```swift
//    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
//    /// Int(pounds) // 153
//    ///
//    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
//    /// Int(yen) // 153
//    /// ```
//    ///
//    /// - Parameter value: The money value to convert.
//    /// - Precondition: The value must not be NaN.
//    @inlinable
//    public init<C: Currency>(_ value: Money<C>) {
//        precondition(!value.isNaN, "Cannot convert NaN to Int")
//        guard let narrow = Int(exactly: value.minorUnits) else {
//            preconditionFailure("Money minor units, \(value.minorUnits), exceeds Int range")
//        }
//        self = narrow
//    }

//    /// Creates a `Decimal` from a `Money`, returning `nil` if the
//    /// value is NaN.
//    ///
//    /// ```swift
//    /// Decimal(exactly: Money<GBP>(minorUnits: 42))   // Optional(42.0)
//    /// Decimal(exactly: Money<GBP>.nan)    // nil
//    /// ```
//    ///
//    /// The `Decimal` value represents the decimal representation of the money value.
//    ///
//    /// ```swift
//    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
//    /// Decimal(exactly: pounds) // Optional(1.53)
//    ///
//    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
//    /// Decimal(exactly: yen) // Optional(1.53)
//    /// ```
//    ///
//    /// - Parameter value: The money value to convert.
//    /// - Returns: A `Decimal` if the conversion is exact, otherwise `nil`.
//    @inlinable
//    public init?<C: Currency>(exactly value: Money<C>) {
//        if value.isNaN { return nil }
//        self = value.decimalValue
//    }
//}
