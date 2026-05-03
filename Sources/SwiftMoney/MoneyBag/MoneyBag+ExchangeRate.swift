extension MoneyBag {

    /// Converts all accumulated amounts to a single currency and returns the sum.
    ///
    /// Each currency in the bag is converted to `Target` via
    /// `provider.rate(from:to:)`. Amounts already in `Target` must also be
    /// supplied by the provider (return an identity rate
    /// `ExchangeRate(from: 1, to: 1)!` for same-currency pairs).
    ///
    /// ## Single-rounding guarantee
    ///
    /// All conversions are accumulated as **exact integer fractions** before a
    /// **single** rounding event is applied at the end, no matter how many
    /// currencies are in the bag. The maximum rounding error is bounded by
    /// `0.5` minor units of `Target`, regardless of bag size.
    ///
    /// The exact (unrounded) total is preserved in
    /// ``MoneyConversionResult/exactNumerator`` `/`
    /// ``MoneyConversionResult/exactDenominator`` for full auditability.
    ///
    /// ## Rounding default
    ///
    /// The default rounding rule is `.toNearestOrEven` (banker's rounding /
    /// IEEE 754 `roundTiesToEven`), which minimises cumulative bias when the
    /// same operation is applied repeatedly across a sequence of transactions.
    /// Per-transaction conversions (``ExchangeRate/convert(_:rounding:)``) use
    /// `.toNearestOrAwayFromZero` (HALF_UP) to match traditional bank-statement
    /// convention and the EC euro-changeover rounding mandate.
    ///
    /// ```swift
    /// var bag = MoneyBag()
    /// bag.add(Money<GBP>(minorUnits: 500))   // £5.00
    /// bag.add(Money<EUR>(minorUnits: 1000))  // €10.00
    ///
    /// let result = bag.total(in: GBP.self, using: myProvider)!
    /// result.total  // Money<GBP>(minorUnits: 1350)  — £13.50
    /// ```
    ///
    /// ## Nil conditions
    ///
    /// Returns `nil` when:
    /// - Any entry's currency metatype is `nil` (the bag entry was decoded from
    ///   `Codable` and the concrete type is not known at runtime).
    /// - The provider returns `nil` for any currency pair.
    ///
    /// Returns a result with `total == .zero` when the bag is empty.
    ///
    /// - Parameters:
    ///   - target:   The target currency to convert everything into.
    ///   - provider: An ``ExchangeRateProvider`` supplying conversion rates.
    ///   - rounding: The rounding rule applied to the aggregated exact total.
    ///     Defaults to `.toNearestOrEven` (banker's rounding, IEEE 754 default).
    /// - Returns: A ``MoneyConversionResult`` containing the rounded total and
    ///   the exact fractional value for audit purposes, or `nil` if conversion
    ///   is impossible.
    public func total<Target: Currency>(
        in target: Target.Type,
        using provider: some ExchangeRateProvider,
        rounding: FloatingPointRoundingRule = .toNearestOrEven
    ) -> MoneyConversionResult<Target>? {
        guard !isEmpty else {
            return MoneyConversionResult(total: .zero, exactNumerator: 0, exactDenominator: 1)
        }

        // Accumulate all conversions as exact fractions: intSum + fracNum/fracDen.
        // Each per-entry exact division contributes:
        //   Integer part → integerSum
        //   Fractional part (remainder/denominator) → folded into fracNum/fracDen via LCM
        var integerSum: Int128 = 0
        var fractionalNumerator: Int128 = 0
        var fractionalDenominator: Int128 = 1

        for anyMoney in _storage.values {
            guard let fromType = anyMoney.currency else { return nil }

            // SE-0352: local generic function opens `fromType` (any Currency.Type)
            // binding `From` to the concrete type at the call site below.
            func computeExact<From: Currency>(_ from: From.Type) -> (quotient: Int128, remainder: Int128, denominator: Int128)? {
                guard let rate = provider.rate(from: from, to: target) else { return nil }
                // product = minorUnits × numerator — fits in Int128 (max ≈ 8.5×10³⁷ < Int128.max)
                let product = Int128(anyMoney.minorUnits) * Int128(rate.rate.numeratorValue)
                let denominator = Int128(rate.rate.denominatorValue)
                let (quotient, remainder) = product.quotientAndRemainder(dividingBy: denominator)
                return (quotient, remainder, denominator)
            }

            guard let (entryQuotient, entryRemainder, entryDenominator) = computeExact(fromType) else { return nil }

            integerSum += entryQuotient

            // Fold remainder into the running fraction using LCM-based addition:
            //   fractionalNumerator/fractionalDenominator + entryRemainder/entryDenominator
            //   = (fractionalNumerator*(entryDenominator/gcd) + entryRemainder*(fractionalDenominator/gcd)) / lcmDenominator
            let hasRemainder = entryRemainder != 0
            if hasRemainder {
                let commonDivisor = _gcd(
                    fractionalDenominator > 0 ? fractionalDenominator : -fractionalDenominator,
                    entryDenominator > 0 ? entryDenominator : -entryDenominator
                )
                let (lcmDenominator, denominatorOverflowed) = (fractionalDenominator / commonDivisor).multipliedReportingOverflow(by: entryDenominator)
                precondition(!denominatorOverflowed, "MoneyBag.total: LCM denominator overflow — exchange rates have incompatible denominators")
                let combinedNumerator = fractionalNumerator * (entryDenominator / commonDivisor) + entryRemainder * (fractionalDenominator / commonDivisor)
                fractionalNumerator = combinedNumerator
                fractionalDenominator = lcmDenominator

                // Keep fractionalNumerator/fractionalDenominator reduced to prevent unbounded growth.
                let absoluteNumerator = fractionalNumerator < 0 ? -fractionalNumerator : fractionalNumerator
                let numeratorGcd = _gcd(absoluteNumerator, fractionalDenominator)
                let isReducible = numeratorGcd > 1
                if isReducible {
                    fractionalNumerator /= numeratorGcd
                    fractionalDenominator /= numeratorGcd
                }
            }
        }

        // Capture the pre-rounding integer sum for the exact fraction output.
        let preRoundIntegerSum = integerSum

        // Apply a single rounding event to the accumulated fractional remainder.
        let hasFractionalPart = fractionalNumerator != 0
        if hasFractionalPart {
            let (truncatedQuotient, roundingRemainder) = fractionalNumerator.quotientAndRemainder(dividingBy: fractionalDenominator)
            let adjustment = _roundInt128(
                truncated: truncatedQuotient,
                remainder: roundingRemainder,
                denominator: fractionalDenominator,
                rule: rounding
            )
            integerSum += adjustment
        }

        // Bounds check: result must fit in Int64 and must not equal the NaN sentinel.
        precondition(
            integerSum >= Int128(Int64.min) && integerSum <= Int128(Int64.max),
            "MoneyBag.total: converted total overflows Int64"
        )
        let finalMinorUnits = Int64(integerSum)
        precondition(finalMinorUnits != .min, "MoneyBag.total: result is NaN sentinel")

        // Build the exact fraction (preRoundIntegerSum + fractionalNumerator/fractionalDenominator) reduced by GCD.
        // exactNumeratorUnreduced = preRoundIntegerSum * fractionalDenominator + fractionalNumerator
        let exactNumeratorUnreduced = preRoundIntegerSum * fractionalDenominator + fractionalNumerator
        let absoluteExactNumerator = exactNumeratorUnreduced < 0 ? -exactNumeratorUnreduced : exactNumeratorUnreduced
        let exactCommonDivisor = _gcd(absoluteExactNumerator == 0 ? 1 : absoluteExactNumerator, fractionalDenominator)
        let exactNumerator   = exactNumeratorUnreduced / exactCommonDivisor
        let exactDenominator = fractionalDenominator / exactCommonDivisor

        return MoneyConversionResult(
            total: Money<Target>(_unchecked: finalMinorUnits),
            exactNumerator: exactNumerator,
            exactDenominator: exactDenominator
        )
    }
}
