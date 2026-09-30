public extension MoneyOf where C: CurrencyType {
    /// Creates an amount from a whole number of the currency's major units.
    ///
    /// ```swift
    /// GBP(majorUnits: 15)   // £15.00
    /// JPY(majorUnits: 15)   // ¥15
    /// ```
    ///
    /// The currency's scale is read for you, so a count of pounds is never mistaken for a count of
    /// pence.
    ///
    /// - Parameter majorUnits: The number of whole major units.
    /// - Returns: `nil` if the amount is too large to hold once scaled to minor units.
    @inlinable
    init?(majorUnits: Int) {
        // `Int` always fits `Int64` exactly, so the product is checked at 64-bit width.
        self.init(majorUnits: Int64(majorUnits))
    }

    /// Creates an amount from a whole number of the currency's major units.
    ///
    /// - Parameter majorUnits: The number of whole major units.
    /// - Returns: `nil` if the amount is too large to hold once scaled to minor units.
    @inlinable
    init?(majorUnits: Int64) {
        guard let minorUnits = scaledToMinorUnits(majorUnits, in: C.currency) else {
            return nil
        }

        self.init(unchecked: minorUnits, storage: .implied)
    }

    /// Creates an amount from a whole number of the currency's major units, given in any integer
    /// type.
    ///
    /// - Parameter majorUnits: The number of whole major units.
    /// - Returns: `nil` if the amount is too large to hold once scaled to minor units.
    @inlinable
    init?(majorUnits: some BinaryInteger) {
        guard let narrow = Int64(exactly: majorUnits) else {
            return nil
        }

        self.init(majorUnits: narrow)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Creates an amount from a whole number of a currency's major units.
    ///
    /// ```swift
    /// Money(majorUnits: 15, currency: .gbp)   // £15.00
    /// Money(majorUnits: 1, currency: .jpy)    // ¥1
    /// ```
    ///
    /// - Parameters:
    ///   - majorUnits: The number of whole major units.
    ///   - currency: The currency to denominate the amount in.
    /// - Returns: `nil` if the amount is too large to hold once scaled to minor units.
    @inlinable
    init?(
        majorUnits: Int,
        currency: Currency
    ) {
        self.init(majorUnits: Int64(majorUnits), currency: currency)
    }

    /// Creates an amount from a whole number of a currency's major units.
    ///
    /// - Parameters:
    ///   - majorUnits: The number of whole major units.
    ///   - currency: The currency to denominate the amount in.
    /// - Returns: `nil` if the amount is too large to hold once scaled to minor units.
    @inlinable
    init?(
        majorUnits: Int64,
        currency: Currency
    ) {
        guard let minorUnits = scaledToMinorUnits(majorUnits, in: currency) else {
            return nil
        }

        self.init(unchecked: minorUnits, storage: currency)
    }

    /// Creates an amount from a whole number of a currency's major units, given in any integer type.
    ///
    /// - Parameters:
    ///   - majorUnits: The number of whole major units.
    ///   - currency: The currency to denominate the amount in.
    /// - Returns: `nil` if the amount is too large to hold once scaled to minor units.
    @inlinable
    init?(
        majorUnits: some BinaryInteger,
        currency: Currency
    ) {
        guard let narrow = Int64(exactly: majorUnits) else {
            return nil
        }

        self.init(majorUnits: narrow, currency: currency)
    }
}

// A whole count of major units in minor units, or `nil` when the product leaves `Int64`.
//
// A count that does not fit `Int64` never needs a wider product: every scale is at least one, so its
// minor units could not fit either. That is why the generic initializers stop at `Int64(exactly:)`.
@inlinable
func scaledToMinorUnits(
    _ majorUnits: Int64,
    in currency: Currency
) -> Int64? {
    let (product, overflow) = majorUnits.multipliedReportingOverflow(by: Int64(currency.unitScale))

    return overflow ? nil : product
}
