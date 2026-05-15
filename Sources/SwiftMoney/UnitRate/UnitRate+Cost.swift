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
        if quantity == 0 {
            return RateCalculation(amount: .zero, effectiveRate: .zero)
        }

        if rate.numeratorValue == 0 {
            return RateCalculation(amount: .zero, effectiveRate: rate)
        }

        let minorUnits = computeMinorUnits(
            quantity: quantity,
            rounding: rounding
        )

        guard let minorUnit = MinorUnit(exactly: minorUnits) else {
            preconditionFailure("UnitRate price produced unrepresentable value")
        }
        let resultMoney = Money<C>(minorUnits: minorUnit)
        let effectiveRate = effectiveRate(minorUnits: minorUnits, quantity: quantity)
        return RateCalculation(amount: resultMoney, effectiveRate: effectiveRate)
    }

    // MARK: - Private helpers

    /// GCD-reduces and multiplies `quantity × rate × minimalQuantisation`,
    /// rounds, and returns the result as a validated `Int64`.
    private func computeMinorUnits(
        quantity: Int64,
        rounding: FloatingPointRoundingRule
    ) -> Int64 {
        let minimalQuantisation = C.minimalQuantisation.int64Value
        let denominator = rate.denominatorValue
        precondition(quantity != .min, "UnitRate price: quantity must not be Int64.min")
        let absoluteQuantity = quantity < 0 ? -quantity : quantity

        // GCD pass 1: reduce quantity against denominator.
        let quantityDenominatorGCD = _gcd(absoluteQuantity, denominator)
        let reducedQuantity = quantity / quantityDenominatorGCD
        let remainingDenominator = denominator / quantityDenominatorGCD

        // GCD pass 2: reduce minimal quantisation against remaining denominator.
        let quantisationDenominatorGCD = _gcd(minimalQuantisation, remainingDenominator)
        let reducedMinimalQuantisation = minimalQuantisation / quantisationDenominatorGCD
        let reducedDenominator = Int128(remainingDenominator / quantisationDenominatorGCD)

        let product = Int128(reducedQuantity)
            * Int128(rate.numeratorValue)
            * Int128(reducedMinimalQuantisation)

        let (truncated, remainder) = product.quotientAndRemainder(dividingBy: reducedDenominator)

        let minorUnits128 = _roundInt128(
            truncated: truncated,
            remainder: remainder,
            denominator: reducedDenominator,
            rule: rounding
        )

        guard let minorUnits = Int64(exactly: minorUnits128) else {
            preconditionFailure("UnitRate price calculation overflows Int64")
        }
        return minorUnits
    }

    /// Builds the effective rate as `minorUnits / quantity`, normalised
    /// so the denominator is positive.
    private func effectiveRate(minorUnits: Int64, quantity: Int64) -> Rate {
        if quantity > 0 {
            return Rate(_unchecked: minorUnits, denominator: quantity)
        }
        // quantity < 0: negate both to normalise denominator to positive.
        precondition(minorUnits != .min && quantity != .min,
                     "Effective rate computation requires negation of Int64.min, which overflows")
        return Rate(_unchecked: -minorUnits, denominator: -quantity)
    }
}
