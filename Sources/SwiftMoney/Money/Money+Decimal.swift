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

extension Decimal {
    /// Creates a `Decimal` from a `Money`. Always exact.
    ///
    /// ```swift
    /// let money = Money<GBP>(99.95)   // £99.95
    /// let decimal = Decimal(money)    // Decimal(99.95)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    @inlinable
    public init<C: Currency>(_ value: Money<C>) {
        self = value.decimalValue
    }

    /// Creates a `Decimal` from a `Money`, returning `nil` for NaN.
    ///
    /// ```swift
    /// let money = Money<GBP>(99.95)   // £99.95
    /// let decimal = Decimal(exactly: money)   // Optional(Decimal(99.95))
    ///
    /// let nan = Decimal(exactly: Money.nan)  // nil
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: A `Decimal` if the value is not NaN, otherwise `nil`.
    @inlinable
    public init?<C: Currency>(exactly value: Money<C>) {
        if value.isNaN { return nil }
        self = value.decimalValue
    }
}
