#if canImport(Foundation)
import Foundation

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
