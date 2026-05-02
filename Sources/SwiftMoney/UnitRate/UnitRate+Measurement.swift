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
            quantity: quantityRate,
            rounding: rounding
        ) else {
            return nil
        }

        // Compute effective rate: minorUnits per original quantity.
        guard let effectiveRate = effectiveRate(
            minorUnits: minorUnits,
            quantity: quantityRate
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

    /// Cross-reduces a signed numerator against a positive denominator
    /// by their GCD, preserving the numerator's sign.
    private func crossReduce(
        numerator: Int64,
        denominator: Int64
    ) -> (numerator: Int64, denominator: Int64) {
        let absoluteNumerator = numerator < 0 ? -numerator : numerator
        let gcd = _gcd(absoluteNumerator, denominator)
        return (numerator / gcd, denominator / gcd)
    }

    /// Three-pass GCD cross-reduction of `quantity × rate × minimalQuantisation`.
    ///
    /// Returns the fully reduced (numerator, denominator) pair ready for
    /// division and rounding.
    private func reducedProduct(
        quantity: Rate
    ) -> (numerator: Int128, denominator: Int128) {
        // Pass 1: cross-reduce quantity numerator against rate denominator.
        let (reducedQuantityNumerator, reducedRateDenominator) = crossReduce(
            numerator: quantity.numeratorValue, denominator: rate.denominatorValue)
        // Pass 2: cross-reduce rate numerator against quantity denominator.
        let (reducedRateNumerator, reducedQuantityDenominator) = crossReduce(
            numerator: rate.numeratorValue, denominator: quantity.denominatorValue)

        let remainingDenominator = Int128(reducedQuantityDenominator)
            * Int128(reducedRateDenominator)

        // Pass 3: reduce minimal quantisation against combined denominator.
        let minimalQuantisation = Int128(C.minimalQuantisation.int64Value)
        let quantisationGCD = _gcd(minimalQuantisation, remainingDenominator)

        let numerator = Int128(reducedQuantityNumerator)
            * Int128(reducedRateNumerator)
            * (minimalQuantisation / quantisationGCD)
        let denominator = remainingDenominator / quantisationGCD
        return (numerator, denominator)
    }

    /// Computes the minor units for a fractional quantity × rate calculation.
    ///
    /// Returns `nil` if the result overflows `Int64` or equals the NaN sentinel.
    private func computeMinorUnits(
        quantity: Rate,
        rounding: FloatingPointRoundingRule
    ) -> Int64? {
        let (numerator, denominator) = reducedProduct(quantity: quantity)
        guard denominator != 0 else { return nil }

        let (truncated, remainder) = numerator.quotientAndRemainder(
            dividingBy: denominator)
        let minorUnits128 = _roundInt128(
            truncated: truncated,
            remainder: remainder,
            denominator: denominator,
            rule: rounding
        )

        guard let minorUnits = Int64(exactly: minorUnits128),
              minorUnits != .min else {
            return nil
        }
        return minorUnits
    }

    /// Computes the effective rate as minor units per original quantity.
    ///
    /// `effectiveRate = minorUnits × quantityDenominator / quantityNumerator`
    ///
    /// Pre-reduces by GCD to minimise overflow risk. Returns `nil` if the
    /// result cannot be expressed in `Int64` without precision loss.
    private func effectiveRate(
        minorUnits: Int64,
        quantity: Rate
    ) -> Rate? {
        let isNegative = (minorUnits < 0) != (quantity.numeratorValue < 0)

        let absoluteMinorUnits = minorUnits < 0 ? -minorUnits : minorUnits
        let absoluteQuantityNumerator = quantity.numeratorValue < 0
            ? -quantity.numeratorValue : quantity.numeratorValue

        let gcd = _gcd(absoluteMinorUnits, absoluteQuantityNumerator)
        let reducedMinorUnits = absoluteMinorUnits / gcd
        let reducedQuantityNumerator = absoluteQuantityNumerator / gcd

        let scaledNumerator = Int128(reducedMinorUnits)
            * Int128(quantity.denominatorValue)

        guard let numerator = Int64(exactly: scaledNumerator),
              reducedQuantityNumerator >= 1 else {
            return nil
        }

        return Rate(_unchecked: isNegative ? -numerator : numerator,
                     denominator: reducedQuantityNumerator)
    }
}
#endif
