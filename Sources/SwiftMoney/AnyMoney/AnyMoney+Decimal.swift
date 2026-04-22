import Foundation

extension AnyMoney {
    /// The value as a `Foundation.Decimal`.
    ///
    /// Returns `Decimal.nan` for NaN, mirroring `Money<C>.decimalValue`.
    ///
    /// ```swift
    /// Money<GBP>(minorUnits: 150).erased.decimalValue  // Decimal("1.50")
    /// Money<JPY>(minorUnits: 500).erased.decimalValue  // Decimal(500)
    /// Money<GBP>.nan.erased.decimalValue               // Decimal.nan
    /// ```
    @inlinable
    public var decimalValue: Decimal {
        if isNaN { return Decimal.nan }
        return Decimal(minorUnits) / Decimal(minimalQuantisation.int64Value)
    }
}
