#if canImport(Foundation)
import Foundation

extension Decimal {
    /// Creates a `Decimal` from an `AnyMoney`. Always exact.
    ///
    /// ```swift
    /// let any = Money<GBP>(minorUnits: 150).erased
    /// let decimal = Decimal(any) // Decimal("1.50")
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    public init(_ value: AnyMoney) {
        self = Decimal(value.minorUnits) / Decimal(value.minimalQuantisation.int64Value)
    }
}
#endif
