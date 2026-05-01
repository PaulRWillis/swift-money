#if canImport(Foundation)
import Foundation

extension UnitRate where U: Dimension {

    /// Returns this rate re-expressed per a different unit, using an exact
    /// integer conversion factor.
    ///
    /// If this rate is `R` per `oldUnit`, and `1 newUnit = factor × oldUnit`,
    /// the returned rate is `R × factor` per `newUnit` (i.e. the denominator
    /// of the `Rate` is multiplied by `factor`).
    ///
    /// ### Example
    ///
    /// ```swift
    /// let perKWh = UnitRate<GBP, UnitEnergy>(Rate("23/1000000")!, per: .kilowattHours)
    /// let perKJ = perKWh.converted(to: .kilojoules, factor: 3600)
    /// // rate == 23/3600000000 per kJ
    /// ```
    ///
    /// - Parameters:
    ///   - newUnit: The target unit within the same dimension.
    ///   - factor: How many of the current unit equal one of `newUnit`.
    ///     Must be positive.
    /// - Returns: A new `UnitRate` expressed per `newUnit`.
    /// - Precondition: `factor > 0`.
    public func converted(to newUnit: U, factor: Int64) -> UnitRate {
        precondition(factor > 0, "Conversion factor must be positive")

        // rate per newUnit = rate.numerator / (rate.denominator × factor)
        // We construct via Rate(numerator:denominator:) which GCD-reduces.
        let newDenominator = rate.denominatorValue &* factor
        precondition(
            newDenominator > 0 && (rate.denominatorValue == 0 || newDenominator / rate.denominatorValue == factor),
            "Conversion factor causes denominator overflow"
        )

        if rate.numeratorValue == 0 {
            return UnitRate(.zero, per: newUnit)
        }

        let newRate = Rate(_unchecked: rate.numeratorValue, denominator: newDenominator)
        return UnitRate(newRate, per: newUnit)
    }

    /// Returns this rate re-expressed per a different unit within the same
    /// dimension, using Foundation's unit conversion coefficients.
    ///
    /// The conversion factor between the current unit and `newUnit` must be
    /// an exact positive integer; if it is not (e.g. miles ↔ meters with
    /// coefficient 1609.344), this method returns `nil`.
    ///
    /// ### Example
    ///
    /// ```swift
    /// let perKWh = UnitRate<GBP, UnitEnergy>(Rate("23/1000000")!, per: .kilowattHours)
    /// let perKJ = perKWh.converted(to: .kilojoules)  // 23/3600000000 per kJ
    /// ```
    ///
    /// - Parameter newUnit: The target unit within the same dimension.
    /// - Returns: A new `UnitRate` per `newUnit`, or `nil` if the conversion
    ///   factor is not an exact integer.
    public func converted(to newUnit: U) -> UnitRate? {
        // Compute how many of the current unit make one of the new unit.
        // 1 kWh = 3600 kJ, so if current=kWh, new=kJ, factor = 3600.
        // In Foundation terms: currentUnit has a larger baseUnitValue.
        // factor = currentUnit.baseValue / newUnit.baseValue
        let currentBase = unit.converter.baseUnitValue(fromValue: 1.0)
        let newBase = newUnit.converter.baseUnitValue(fromValue: 1.0)

        guard newBase > 0 else { return nil }
        let factor = currentBase / newBase

        // Factor must be a positive integer.
        guard factor > 0,
              factor.rounded(.towardZero) == factor,
              factor <= Double(Int64.max) else {
            return nil
        }

        return converted(to: newUnit, factor: Int64(factor))
    }
}
#endif
