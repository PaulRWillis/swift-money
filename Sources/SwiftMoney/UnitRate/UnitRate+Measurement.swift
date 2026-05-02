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

        // Zero values (0.0, -0.0) always take the integer fast path above.
        // No non-integer Double can produce a Decimal with numerator 0.
        precondition(qtyNum != 0, "Zero quantity must take the integer fast path")

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

        // Bounds check. Int64.min is reserved as the NaN sentinel for Money,
        // so the valid range is (Int64.min, Int64.max] — strictly greater than min.
        guard minorUnits128 > Int128(Int64.min),
              minorUnits128 <= Int128(Int64.max) else {
            return nil
        }
        let minorUnits = Int64(minorUnits128)

        let resultMoney = Money<C>(_unchecked: minorUnits)

        // Effective rate: minorUnits per original quantity (as fraction).
        // effectiveRate = minorUnits / (qtyNum/qtyDen) = minorUnits × qtyDen / qtyNum
        //
        // Pre-reduce minorUnits and qtyNum by their GCD to minimise the
        // intermediate product and keep values within Int64 range. If the
        // result still overflows, the calculation cannot be expressed without
        // precision loss — return nil.
        let effNum: Int64
        let effDen: Int64
        if qtyNum > 0 {
            let absMinorUnits = minorUnits < 0 ? -minorUnits : minorUnits
            let g = _gcd(absMinorUnits, qtyNum)
            let reducedMU = minorUnits / g
            let reducedQN = qtyNum / g
            let scaledNum = Int128(reducedMU) * Int128(qtyDen)
            let scaledDen = Int128(reducedQN)
            guard scaledNum >= Int128(Int64.min), scaledNum <= Int128(Int64.max),
                  scaledDen >= 1, scaledDen <= Int128(Int64.max) else {
                return nil
            }
            effNum = Int64(scaledNum)
            effDen = Int64(scaledDen)
        } else {
            let absMU = minorUnits < 0 ? -minorUnits : minorUnits
            let absQN = -qtyNum  // qtyNum < 0 here
            let g = _gcd(absMU, absQN)
            let reducedMU = -minorUnits / g  // negate for positive numerator
            let reducedQN = absQN / g
            let scaledNum = Int128(reducedMU) * Int128(qtyDen)
            let scaledDen = Int128(reducedQN)
            guard scaledNum >= Int128(Int64.min), scaledNum <= Int128(Int64.max),
                  scaledDen >= 1, scaledDen <= Int128(Int64.max) else {
                return nil
            }
            effNum = Int64(scaledNum)
            effDen = Int64(scaledDen)
        }

        let effectiveRate = Rate(_unchecked: effNum, denominator: effDen)
        return RateCalculation(amount: resultMoney, effectiveRate: effectiveRate)
    }
}
#endif
