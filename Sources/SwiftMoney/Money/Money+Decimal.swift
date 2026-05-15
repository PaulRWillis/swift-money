#if canImport(Foundation)
import Foundation

extension Money {
    /// The value as a `Foundation.Decimal`. Backwards-compatibility convenience for `Decimal(self)`.
    @inlinable
    public var decimalValue: Decimal {
        Decimal(Int64(_minorUnits)) / Decimal(Self.minimalQuantisation.int64Value)
    }
}

extension Money {
    /// Creates a value from a `Foundation.Decimal`.
    /// The `Decimal` value must be a valid representation of a `Money` amount
    /// in its given currency.
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
    /// - Precondition: The `Decimal` must not be NaN.
    /// - Precondition: The  `Decimal` value must be an exact valid amount in
    /// the associated currency.
    /// - Precondition: The scaled result must fit in `Int64`.
    /// - Precondition: The `scaleFactor` of the currency must not be 0.
    public init(_ decimal: Decimal) {
        precondition(!decimal.isNaN, "Cannot create Money from Decimal.nan")

        let factor = Decimal(Self.minimalQuantisation.int64Value)

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

        guard let minorUnit = MinorUnit(exactly: int64Value) else {
            preconditionFailure("Decimal value \(decimal) produces unrepresentable minor units")
        }
        self._minorUnits = minorUnit
    }

    /// Creates a value from a `Foundation.Decimal`. Returns `nil` if the
    /// scaled result does not fit in `Int64`, if the `scaleFactor` of the currency is 0,
    /// if the `Decimal` is NaN, or if the `Decimal` value is not a valid representation
    /// of a `Money` amount in its given currency.
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

        let factor = Decimal(Self.minimalQuantisation.int64Value)

        guard factor != .zero else { return nil }

        let scaled = decimal * factor
        let int64Value = NSDecimalNumber(decimal: scaled).int64Value

        // Overflow check: round-trip must match
        guard Decimal(int64Value) == scaled else { return nil }

        guard let minorUnit = MinorUnit(exactly: int64Value) else { return nil }
        self._minorUnits = minorUnit
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
}
#endif
