import Foundation

extension Money {

    // MARK: - Fractional Multiplication

    /// Returns the result of multiplying this value by the given fractional rate.
    ///
    /// Because money is stored as a discrete integer number of minor units,
    /// fractional multiplication almost always produces a theoretically
    /// fractional intermediate result that must be rounded. The returned
    /// ``FractionalMultiplicationResult`` carries both the rounded amount
    /// and the **actual rate that was applied**, so callers can account for
    /// the rounding in downstream calculations.
    ///
    /// The round-trip invariant holds: `input × actualRate == result`.
    ///
    /// ```swift
    /// // £1.01 × 1% — rounds down to £0.01; actual rate is 1/101 not 1/100
    /// let r = Money<GBP>(minorUnits: 101).multiplied(
    ///     by: FractionalRate(numerator: 1, denominator: 100)
    /// )
    /// r.result      // Money<GBP>(minorUnits: 1)
    /// r.actualRate  // FractionalRate(numerator: 1, denominator: 101)
    /// ```
    ///
    /// - Parameters:
    ///   - rate: The fractional rate to multiply by.
    ///   - rounding: The rounding rule to apply when the result is not a whole
    ///     number of minor units. Defaults to `.toNearestOrAwayFromZero`.
    /// - Returns: A `FractionalMultiplicationResult` containing the rounded
    ///   result and the actual rate applied.
    /// - Precondition: `self` must not be NaN.
    public func multiplied(
        by rate: FractionalRate,
        rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> FractionalMultiplicationResult<Currency> {
        precondition(!isNaN, "Cannot multiply NaN")

        // Zero input: 0 × anything == 0; rate is undefined so return input rate.
        if _storage == 0 {
            return FractionalMultiplicationResult(result: .zero, actualRate: rate)
        }

        // Compute the theoretical (unrounded) result entirely in minor units,
        // using Decimal arithmetic to avoid Int64 intermediate overflow.
        var a = Decimal(_storage)
        var n = Decimal(rate.numeratorValue)
        var d = Decimal(rate.denominatorValue)
        var product = Decimal()
        var unrounded = Decimal()
        NSDecimalMultiply(&product, &a, &n, .plain)
        NSDecimalDivide(&unrounded, &product, &d, .plain)

        // Round to the nearest whole minor unit.
        var rounded = Decimal()
        NSDecimalRound(&rounded, &unrounded, 0, _nsRoundingMode(rounding, for: unrounded))

        // Convert the rounded Decimal to Int64.
        let minorUnits = NSDecimalNumber(decimal: rounded).int64Value
        // Overflow check: round-trip must reproduce the rounded Decimal.
        precondition(
            Decimal(minorUnits) == rounded,
            "Money fractional multiplication result overflows Int64"
        )
        // Guard against NaN sentinel.
        precondition(
            minorUnits != .min,
            "Money fractional multiplication produced NaN sentinel"
        )

        let resultMoney = Money(_unchecked: minorUnits)

        // Build the actual rate = result / input (in lowest terms).
        // Normalise so that the denominator is positive (FractionalRate contract).
        let actualRate: FractionalRate
        if _storage > 0 {
            actualRate = FractionalRate(numerator: minorUnits, denominator: _storage)
        } else {
            // _storage < 0 (non-zero, non-NaN): flip both signs so denominator > 0.
            actualRate = FractionalRate(numerator: -minorUnits, denominator: -_storage)
        }

        return FractionalMultiplicationResult(result: resultMoney, actualRate: actualRate)
    }
}

// MARK: - Operators

extension Money {

    /// Returns the result of multiplying this `Money` value by a `FractionalRate`.
    ///
    /// Uses `.toNearestOrAwayFromZero` rounding. To specify a different rounding
    /// rule, call ``multiplied(by:rounding:)`` directly.
    ///
    /// ```swift
    /// let r = Money<GBP>(minorUnits: 101) * FractionalRate(numerator: 1, denominator: 100)
    /// r.result      // Money<GBP>(minorUnits: 1)
    /// r.actualRate  // FractionalRate(numerator: 1, denominator: 101)
    /// ```
    ///
    /// - Precondition: `lhs` must not be NaN.
    public static func * (
        lhs: Money,
        rhs: FractionalRate
    ) -> FractionalMultiplicationResult<Currency> {
        lhs.multiplied(by: rhs)
    }

    /// Returns the result of multiplying this `Money` value by a `Decimal` rate.
    ///
    /// Converts `rhs` to a ``FractionalRate`` via ``FractionalRate/init(_:)``
    /// and then calls ``multiplied(by:rounding:)`` with
    /// `.toNearestOrAwayFromZero` rounding.
    ///
    /// > Warning: `Decimal` floating-point literals (e.g. `* 0.01`) are
    /// > initialised via `Double` and lose precision. Always prefer
    /// > `Decimal(string: "0.01")!` or an explicit
    /// > `FractionalRate(numerator: 1, denominator: 100)`.
    ///
    /// ```swift
    /// // Precise:
    /// let r = Money<GBP>(minorUnits: 101) * Decimal(string: "0.01")!
    ///
    /// // Imprecise (Decimal literal goes through Double):
    /// // let r = Money<GBP>(minorUnits: 101) * 0.01  ← avoid
    /// ```
    ///
    /// - Precondition: `lhs` must not be NaN.
    /// - Precondition: `rhs` must not be NaN.
    public static func * (
        lhs: Money,
        rhs: Decimal
    ) -> FractionalMultiplicationResult<Currency> {
        lhs.multiplied(by: FractionalRate(rhs))
    }
}

// MARK: - Private helpers

/// Maps a `FloatingPointRoundingRule` to the equivalent `NSDecimalNumber.RoundingMode`.
///
/// For the direction-sensitive rules (`.towardZero`, `.awayFromZero`), the
/// sign of the intermediate (pre-rounding) `value` determines which mode to use.
private func _nsRoundingMode(
    _ rule: FloatingPointRoundingRule,
    for value: Decimal
) -> NSDecimalNumber.RoundingMode {
    switch rule {
    case .toNearestOrAwayFromZero:
        return .plain
    case .toNearestOrEven:
        return .bankers
    case .up:
        return .up
    case .down:
        return .down
    case .towardZero:
        // Truncate: round toward zero.
        // Positive values → floor (.down); negative values → ceiling (.up).
        return value.isSignMinus ? .up : .down
    case .awayFromZero:
        // Round away from zero.
        // Positive values → ceiling (.up); negative values → floor (.down).
        return value.isSignMinus ? .down : .up
    @unknown default:
        return .plain
    }
}
