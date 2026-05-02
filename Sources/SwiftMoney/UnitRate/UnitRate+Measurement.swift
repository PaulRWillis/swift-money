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
        let convertedValue = measurement.converted(to: unit).value

        guard convertedValue.isFinite else { return nil }

        // Fast path: exact integer quantity.
        let isInteger = convertedValue.rounded(.towardZero) == convertedValue
        let isWithinInt64Range = convertedValue >= Double(Int64.min)
            && convertedValue <= Double(Int64.max)
        if isInteger, isWithinInt64Range {
            return price(forQuantity: Int64(convertedValue), rounding: rounding)
        }

        // Slow path: express the value as a rational fraction via Decimal.
        guard let quantityRate = rationalQuantity(from: convertedValue) else { return nil }

        // Zero rate.
        if rate.numeratorValue == 0 {
            return RateCalculation(amount: .zero, effectiveRate: rate)
        }

        // Compute minor units via GCD-reduced rational arithmetic.
        guard let minorUnits = computeMinorUnits(
            quantityNumerator: quantityRate.numeratorValue,
            quantityDenominator: quantityRate.denominatorValue,
            rateNumerator: rate.numeratorValue,
            rateDenominator: rate.denominatorValue,
            minimalQuantisation: C.minimalQuantisation.int64Value,
            rounding: rounding
        ) else {
            return nil
        }

        // Compute effective rate: minorUnits per original quantity.
        guard let effectiveRate = effectiveRate(
            minorUnits: minorUnits,
            quantityNumerator: quantityRate.numeratorValue,
            quantityDenominator: quantityRate.denominatorValue
        ) else {
            return nil
        }

        return RateCalculation(
            amount: Money<C>(_unchecked: minorUnits),
            effectiveRate: effectiveRate
        )
    }

    // MARK: - Private helpers

    /// Converts a `Double` value to an exact rational ``Rate`` via the shortest
    /// decimal representation.
    ///
    /// Uses `String(Double)` → `Decimal(string:)` to recover the shortest exact
    /// decimal representation, avoiding `Decimal(Double)` which introduces
    /// 17+ digit floating-point noise.
    private func rationalQuantity(from value: Double) -> Rate? {
        guard let decimal = Decimal(string: String(value)),
              !decimal.isNaN else {
            return nil
        }
        guard let quantityRate = Rate(decimal) else { return nil }
        // Zero values (0.0, -0.0) always take the integer fast path.
        // No non-integer Double can produce a Decimal with numerator 0.
        precondition(quantityRate.numeratorValue != 0,
                     "Zero quantity must take the integer fast path")
        return quantityRate
    }

    /// Computes the minor units for a fractional quantity × rate calculation.
    ///
    /// Performs three passes of GCD pre-reduction across all factors to maximise
    /// the range of inputs computable without overflow, then multiplies in
    /// `Int128` and applies rounding.
    ///
    /// Returns `nil` if the result overflows `Int64` or equals the NaN sentinel.
    private func computeMinorUnits(
        quantityNumerator: Int64,
        quantityDenominator: Int64,
        rateNumerator: Int64,
        rateDenominator: Int64,
        minimalQuantisation: Int64,
        rounding: FloatingPointRoundingRule
    ) -> Int64? {
        let absoluteQuantityNumerator = quantityNumerator < 0
            ? -quantityNumerator : quantityNumerator
        let absoluteRateNumerator = rateNumerator < 0
            ? -rateNumerator : rateNumerator

        // GCD pass 1: reduce quantity numerator against rate denominator.
        let quantityRateGCD = _gcd(absoluteQuantityNumerator, rateDenominator)
        let reducedQuantityNumerator = quantityNumerator / quantityRateGCD
        let reducedRateDenominator = rateDenominator / quantityRateGCD

        // GCD pass 2: reduce rate numerator against quantity denominator.
        let rateQuantityGCD = _gcd(absoluteRateNumerator, quantityDenominator)
        let reducedRateNumerator = rateNumerator / rateQuantityGCD
        let reducedQuantityDenominator = quantityDenominator / rateQuantityGCD

        let remainingDenominator = Int128(reducedQuantityDenominator)
            * Int128(reducedRateDenominator)

        // GCD pass 3: reduce minimal quantisation against remaining denominator.
        let canReduceWithRemainingDenominator =
            remainingDenominator <= Int128(Int64.max) && remainingDenominator > 0
        let denominatorForQuantisationGCD = canReduceWithRemainingDenominator
            ? Int64(remainingDenominator) : 1
        let quantisationGCD = _gcd(minimalQuantisation, denominatorForQuantisationGCD)
        let reducedMinimalQuantisation = minimalQuantisation / quantisationGCD
        let finalDenominator = remainingDenominator / Int128(quantisationGCD)

        let product = Int128(reducedQuantityNumerator)
            * Int128(reducedRateNumerator)
            * Int128(reducedMinimalQuantisation)

        guard finalDenominator != 0 else { return nil }
        let (truncated, remainder) = product.quotientAndRemainder(
            dividingBy: finalDenominator
        )

        let minorUnits128 = _roundInt128(
            truncated: truncated,
            remainder: remainder,
            denominator: finalDenominator,
            rule: rounding
        )

        // Int64.min is reserved as the NaN sentinel for Money,
        // so the valid range is (Int64.min, Int64.max].
        guard let minorUnits = Int64(exactly: minorUnits128),
              minorUnits != .min else {
            return nil
        }

        return minorUnits
    }

    /// Computes the effective rate as minor units per original quantity.
    ///
    /// `effectiveRate = minorUnits / (quantityNumerator / quantityDenominator)`
    /// `= minorUnits × quantityDenominator / quantityNumerator`
    ///
    /// Pre-reduces by GCD to minimise overflow risk. Returns `nil` if the
    /// result cannot be expressed in `Int64` without precision loss.
    private func effectiveRate(
        minorUnits: Int64,
        quantityNumerator: Int64,
        quantityDenominator: Int64
    ) -> Rate? {
        let absoluteMinorUnits = minorUnits < 0 ? -minorUnits : minorUnits
        let absoluteQuantityNumerator = quantityNumerator < 0
            ? -quantityNumerator : quantityNumerator

        let minorUnitsQuantityGCD = _gcd(absoluteMinorUnits,
                                         absoluteQuantityNumerator)
        let reducedMinorUnits = minorUnits / minorUnitsQuantityGCD
        let reducedQuantityNumerator = quantityNumerator / minorUnitsQuantityGCD

        // Normalise so denominator is positive: if quantity is negative,
        // negate both numerator and denominator.
        let isQuantityNegative = quantityNumerator < 0
        let signedMinorUnits = isQuantityNegative
            ? -reducedMinorUnits : reducedMinorUnits
        let signedQuantityNumerator = isQuantityNegative
            ? -reducedQuantityNumerator : reducedQuantityNumerator

        let scaledNumerator = Int128(signedMinorUnits)
            * Int128(quantityDenominator)
        let scaledDenominator = Int128(signedQuantityNumerator)

        guard let effectiveNumerator = Int64(exactly: scaledNumerator),
              let effectiveDenominator = Int64(exactly: scaledDenominator),
              effectiveDenominator >= 1 else {
            return nil
        }

        return Rate(_unchecked: effectiveNumerator,
                     denominator: effectiveDenominator)
    }
}
#endif
