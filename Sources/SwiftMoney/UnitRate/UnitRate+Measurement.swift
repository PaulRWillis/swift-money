#if canImport(Foundation)
import Foundation

extension UnitRate where U: Dimension {

    /// Computes the price for a `Measurement`, auto-converting to this rate's unit.
    ///
    /// The measurement is first converted to this rate's stored ``unit`` using
    /// Foundation's unit conversion. The converted value must be exactly
    /// representable as an `Int64`; if it is not (e.g. fractional quantities or
    /// overflow), the method returns `nil`.
    ///
    /// ### Example
    ///
    /// ```swift
    /// let rate = UnitRate<GBP, UnitEnergy>(Rate("23/1000000")!, per: .kilowattHours)
    /// let usage = Measurement(value: 2_000, unit: UnitEnergy.megawattHours)
    /// let result = rate.price(for: usage)
    /// // Converts 2000 MWh → 2_000_000 kWh, then prices at £0.000023/kWh
    /// result?.amount  // Money<GBP>(minorUnits: 4600) — £46.00
    /// ```
    ///
    /// - Parameters:
    ///   - measurement: The quantity to price. Auto-converted to this rate's unit.
    ///   - rounding: The rounding rule for fractional minor units.
    ///     Defaults to `.toNearestOrAwayFromZero`.
    /// - Returns: A ``RateCalculation`` containing the rounded price and effective
    ///   rate, or `nil` if the converted quantity cannot be represented as `Int64`.
    public func price(
        for measurement: Measurement<U>,
        rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> RateCalculation<C>? {
        let converted = measurement.converted(to: unit)
        let value = converted.value

        // Check the value is an exact integer within Int64 range.
        guard value.rounded(.towardZero) == value,
              value >= Double(Int64.min),
              value <= Double(Int64.max) else {
            return nil
        }

        let quantity = Int64(value)
        return price(forQuantity: quantity, rounding: rounding)
    }
}
#endif
