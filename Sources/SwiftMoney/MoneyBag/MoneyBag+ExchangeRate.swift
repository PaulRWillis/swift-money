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
        var fracNum: Int128 = 0     // numerator of accumulated fractional part
        var fracDen: Int128 = 1     // denominator of accumulated fractional part (LCM of q_i)

        for anyMoney in _storage.values {
            guard let fromType = anyMoney.currency else { return nil }

            // SE-0352: local generic function opens `fromType` (any Currency.Type)
            // binding `From` to the concrete type at the call site below.
            func computeExact<From: Currency>(_ from: From.Type) -> (quotient: Int128, remainder: Int128, denominator: Int128)? {
                guard let rate = provider.rate(from: from, to: target) else { return nil }
                // product = minorUnits × numerator — fits in Int128 (max ≈ 8.5×10³⁷ < Int128.max)
                let product = Int128(anyMoney.minorUnits) * Int128(rate.rate.numeratorValue)
                let q = Int128(rate.rate.denominatorValue)
                let (quotient, remainder) = product.quotientAndRemainder(dividingBy: q)
                return (quotient, remainder, q)
            }

            guard let (q0, r, q) = computeExact(fromType) else { return nil }

            integerSum += q0

            // Fold remainder into the running fraction using LCM-based addition:
            //   fracNum/fracDen + r/q  =  (fracNum*(q/g) + r*(fracDen/g)) / newDen
            // where g = gcd(fracDen, q), newDen = fracDen/g * q
            if r != 0 {
                let g = _gcd(fracDen > 0 ? fracDen : -fracDen, q > 0 ? q : -q)
                let (newDen, overflowD) = (fracDen / g).multipliedReportingOverflow(by: q)
                precondition(!overflowD, "MoneyBag.total: LCM denominator overflow — exchange rates have incompatible denominators")
                let newNum = fracNum * (q / g) + r * (fracDen / g)
                fracNum = newNum
                fracDen = newDen

                // Keep fracNum/fracDen reduced to prevent unbounded growth.
                let absNum = fracNum < 0 ? -fracNum : fracNum
                let numGcd = _gcd(absNum, fracDen)
                if numGcd > 1 {
                    fracNum /= numGcd
                    fracDen /= numGcd
                }
            }
        }

        // Capture the pre-rounding integer sum for the exact fraction output.
        let preRoundIntegerSum = integerSum

        // Apply a single rounding event to the accumulated fractional remainder.
        if fracNum != 0 {
            let (fracQ, fracR) = fracNum.quotientAndRemainder(dividingBy: fracDen)
            let adjustment = _roundInt128(
                truncated: fracQ,
                remainder: fracR,
                denominator: fracDen,
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

        // Build the exact fraction (preRoundIntegerSum + fracNum/fracDen) reduced by GCD.
        // exactNum = preRoundIntegerSum * fracDen + fracNum
        let exactNumUnreduced = preRoundIntegerSum * fracDen + fracNum
        let absExact = exactNumUnreduced < 0 ? -exactNumUnreduced : exactNumUnreduced
        let exactGcd = _gcd(absExact == 0 ? 1 : absExact, fracDen)
        let exactNumerator   = exactNumUnreduced / exactGcd
        let exactDenominator = fracDen / exactGcd

        return MoneyConversionResult(
            total: Money<Target>(_unchecked: finalMinorUnits),
            exactNumerator: exactNumerator,
            exactDenominator: exactDenominator
        )
    }
}
