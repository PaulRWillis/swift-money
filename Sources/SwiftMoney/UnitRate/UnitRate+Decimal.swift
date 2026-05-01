#if canImport(Foundation)
import Foundation

extension UnitRate {

    /// Creates a `UnitRate` from a `Decimal` major-unit price per unit.
    ///
    /// Delegates to ``Rate/init(_:)-1a2b3`` which extracts an exact integer
    /// fraction from the `Decimal` without precision loss.
    ///
    /// ```swift
    /// let oilPrice = UnitRate<USD, String>(Decimal(string: "72.50")!, per: "barrel")
    /// // rate == 145/2
    /// ```
    ///
    /// - Parameters:
    ///   - decimal: The price per unit as a `Decimal`. Returns `nil` if NaN or
    ///     if the significand exceeds `Int64`.
    ///   - unit: The unit this price applies to.
    public init?(_ decimal: Decimal, per unit: U) {
        guard let rate = Rate(decimal) else { return nil }
        self.init(rate, per: unit)
    }
}
#endif
