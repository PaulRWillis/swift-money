extension UnitRate {

    /// Computes the price for a given quantity at this unit rate.
    ///
    /// The calculation is:
    /// ```
    /// price = round(quantity × rate.numerator × minimalQuantisation / rate.denominator)
    /// ```
    /// performed in `Int128` with GCD pre-reduction to maximise the range of
    /// inputs that can be computed without overflow.
    ///
    /// ### Example
    ///
    /// ```swift
    /// let oilPrice = UnitRate<USD, String>(Rate("14500/200")!, per: "barrel")
    /// let result = oilPrice.price(forQuantity: 1000)
    /// result.amount  // Money<USD>(minorUnits: 7_250_000) — $72,500.00
    /// ```
    ///
    /// - Parameters:
    ///   - quantity: The number of units consumed. May be negative (e.g. export).
    ///   - rounding: The rounding rule for fractional minor units.
    ///     Defaults to `.toNearestOrAwayFromZero`.
    /// - Returns: A ``RateCalculation`` containing the rounded price and the
    ///   effective rate that was applied.
    /// - Precondition: The intermediate product must fit in `Int128` after
    ///   GCD reduction. Traps on overflow.
    public func price(
        forQuantity quantity: Int64,
        rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> RateCalculation<C> {
        let minimalQuantisation = C.minimalQuantisation.int64Value

        // Zero quantity: 0 × anything == 0; effective rate is undefined, use zero.
        if quantity == 0 {
            return RateCalculation(amount: .zero, effectiveRate: .zero)
        }

        // Zero numerator: any quantity × 0 == 0.
        if rate.numeratorValue == 0 {
            return RateCalculation(amount: .zero, effectiveRate: rate)
        }

        let denominator = rate.denominatorValue

        // GCD pre-reduction to maximise range before Int128 multiplication.
        // Reduce quantity against denominator, and minQ against the remaining denominator.
        let absoluteQuantity = quantity < 0 ? -quantity : quantity
        let quantityDenominatorGCD = _gcd(absoluteQuantity, denominator)
        let reducedQuantity = quantity / quantityDenominatorGCD
        let remainingDenominator = denominator / quantityDenominatorGCD

        let quantisationDenominatorGCD = _gcd(minimalQuantisation, remainingDenominator)
        let reducedMinimalQuantisation = minimalQuantisation / quantisationDenominatorGCD
        let reducedDenominator = remainingDenominator / quantisationDenominatorGCD

        // Multiply in Int128. After reduction the product is much smaller.
        let product = Int128(reducedQuantity) * Int128(rate.numeratorValue) * Int128(reducedMinimalQuantisation)
        let denominator128 = Int128(reducedDenominator)

        let (truncated, remainder) = product.quotientAndRemainder(dividingBy: denominator128)

        // Apply rounding.
        let minorUnits128 = _roundInt128(
            truncated: truncated,
            remainder: remainder,
            denominator: denominator128,
            rule: rounding
        )

        // Bounds check.
        guard let minorUnits = Int64(exactly: minorUnits128) else {
            preconditionFailure("UnitRate price calculation overflows Int64")
        }
        precondition(
            minorUnits != .min,
            "UnitRate price calculation produced NaN sentinel"
        )

        let resultMoney = Money<C>(_unchecked: minorUnits)

        // Build effective rate = result / quantity (normalised so denominator > 0).
        let effectiveRate: Rate
        if quantity > 0 {
            effectiveRate = Rate(_unchecked: minorUnits, denominator: quantity)
        } else {
            effectiveRate = Rate(_unchecked: -minorUnits, denominator: -quantity)
        }

        return RateCalculation(amount: resultMoney, effectiveRate: effectiveRate)
    }
}
