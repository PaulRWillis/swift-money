#if canImport(Foundation)
import Foundation

extension UnitRate where U: Dimension {

    /// Computes the price for a `Measurement`, auto-converting to this rate's unit.
    ///
    /// The measurement is first converted to this rate's stored ``unit`` using
    /// Foundation's unit conversion. If the converted value is an exact integer,
    /// it delegates to ``price(forQuantity:rounding:)``. Otherwise, the value
    /// is expressed as a rational fraction via `Decimal` and computed exactly
    /// in `Int128`.
    ///
    /// ### Example
    ///
    /// ```swift
    /// let rate = UnitRate<GBP, UnitEnergy>(Rate("23/1000000")!, per: .kilowattHours)
    /// let usage = Measurement(value: 1000.5, unit: UnitEnergy.kilowattHours)
    /// let result = rate.price(for: usage)
    /// // 1000.5 × 23 × 100 / 1_000_000 = 2.3011… → rounds to 2 minor units
    /// result?.amount  // Money<GBP>(minorUnits: 2)
    /// ```
    ///
    /// - Parameters:
    ///   - measurement: The quantity to price. Auto-converted to this rate's unit.
    ///   - rounding: The rounding rule for fractional minor units.
    ///     Defaults to `.toNearestOrAwayFromZero`.
    /// - Returns: A ``RateCalculation`` containing the rounded price and effective
    ///   rate, or `nil` if the quantity is NaN, infinite, or cannot be expressed
    ///   as an exact rational within `Int64` bounds.
    public func price(
        for measurement: Measurement<U>,
        rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> RateCalculation<C>? {
        let converted = measurement.converted(to: unit)
        let value = converted.value

        guard value.isFinite else { return nil }

        // Fast path: exact integer quantity.
        if value.rounded(.towardZero) == value,
           value >= Double(Int64.min),
           value <= Double(Int64.max) {
            let quantity = Int64(value)
            return price(forQuantity: quantity, rounding: rounding)
        }

        // Slow path: express the value as a rational fraction via Decimal.
        // Use String(Double) → Decimal(string:) to recover the shortest exact
        // decimal representation. Decimal(Double) captures 17+ digits of binary
        // noise whose significand overflows Int64.
        guard let decimal = Decimal(string: String(value)), !decimal.isNaN else { return nil }
        guard let qtyRate = Rate(decimal) else { return nil }

        // Compute: (qtyNum / qtyDen) × (rateNum / rateDen) × minQ
        // = qtyNum × rateNum × minQ / (qtyDen × rateDen)
        let qtyNum = qtyRate.numeratorValue
        let qtyDen = qtyRate.denominatorValue
        let rateNum = rate.numeratorValue
        let rateDen = rate.denominatorValue
        let minQ = C.minimalQuantisation.int64Value

        // Zero quantity.
        if qtyNum == 0 {
            return RateCalculation(amount: .zero, effectiveRate: .zero)
        }

        // Zero rate.
        if rateNum == 0 {
            return RateCalculation(amount: .zero, effectiveRate: rate)
        }

        // GCD pre-reduction across the four factors and two denominators.

        // Reduce pairwise: qtyNum vs rateDen, rateNum vs qtyDen, minQ vs remaining.
        let absQtyNum = qtyNum < 0 ? -qtyNum : qtyNum
        let absRateNum = rateNum < 0 ? -rateNum : rateNum

        let g1 = _gcd(absQtyNum, rateDen)
        let redQtyNum = qtyNum / g1
        let redRateDen = rateDen / g1

        let g2 = _gcd(absRateNum, qtyDen)
        let redRateNum = rateNum / g2
        let redQtyDen = qtyDen / g2

        let remainingDen = Int128(redQtyDen) * Int128(redRateDen)

        // Try to reduce minQ against remaining denominator.
        let minQ128 = Int128(minQ)
        let denForMinQ: Int64
        if remainingDen <= Int128(Int64.max) && remainingDen > 0 {
            denForMinQ = Int64(remainingDen)
        } else {
            denForMinQ = 1
        }
        let g3 = _gcd(minQ, denForMinQ)
        let redMinQ = minQ / g3
        let finalDen = remainingDen / Int128(g3)

        let product = Int128(redQtyNum) * Int128(redRateNum) * Int128(redMinQ)

        guard finalDen != 0 else { return nil }
        let (truncated, remainder) = product.quotientAndRemainder(dividingBy: finalDen)

        let minorUnits128 = _roundInt128(
            truncated: truncated,
            remainder: remainder,
            denominator: finalDen,
            rule: rounding
        )

        // Bounds check.
        guard minorUnits128 >= Int128(Int64.min),
              minorUnits128 <= Int128(Int64.max) else {
            return nil
        }
        let minorUnits = Int64(minorUnits128)
        guard minorUnits != .min else { return nil }

        let resultMoney = Money<C>(_unchecked: minorUnits)

        // Effective rate: minorUnits per original quantity (as fraction).
        // effectiveRate = minorUnits × qtyDen / (qtyNum × minQ_original)
        // But for simplicity, use the combined denominator approach:
        // The "quantity" in major-unit terms for effective rate is qtyNum/qtyDen.
        // effectiveRate = minorUnits / (qtyNum/qtyDen) = minorUnits × qtyDen / qtyNum
        let effNum: Int64
        let effDen: Int64
        if qtyNum > 0 {
            // Normalise so denominator is positive.
            let scaledNum = Int128(minorUnits) * Int128(qtyDen)
            let scaledDen = Int128(qtyNum)
            // Reduce to Int64.
            guard scaledNum >= Int128(Int64.min), scaledNum <= Int128(Int64.max),
                  scaledDen >= 1, scaledDen <= Int128(Int64.max) else {
                // Fallback: report zero effective rate if it can't be expressed.
                return RateCalculation(amount: resultMoney, effectiveRate: .zero)
            }
            effNum = Int64(scaledNum)
            effDen = Int64(scaledDen)
        } else {
            let scaledNum = Int128(-minorUnits) * Int128(qtyDen)
            let scaledDen = Int128(-qtyNum)
            guard scaledNum >= Int128(Int64.min), scaledNum <= Int128(Int64.max),
                  scaledDen >= 1, scaledDen <= Int128(Int64.max) else {
                return RateCalculation(amount: resultMoney, effectiveRate: .zero)
            }
            effNum = Int64(scaledNum)
            effDen = Int64(scaledDen)
        }

        let effectiveRate = Rate(_unchecked: effNum, denominator: effDen)
        return RateCalculation(amount: resultMoney, effectiveRate: effectiveRate)
    }
}
#endif
