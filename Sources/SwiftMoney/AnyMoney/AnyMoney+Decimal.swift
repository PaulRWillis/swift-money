#if canImport(Foundation)
import Foundation

extension AnyMoney {
    /// The value as a `Foundation.Decimal`.
    ///
    /// ```swift
    /// Money<GBP>(minorUnits: 150).erased.decimalValue  // Decimal("1.50")
    /// Money<JPY>(minorUnits: 500).erased.decimalValue  // Decimal(500)
    /// ```
    @inlinable
    public var decimalValue: Decimal {
        Decimal(Int64(minorUnits)) / Decimal(minimalQuantisation.int64Value)
    }
}
#endif
