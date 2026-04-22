#if canImport(Foundation)
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

        // Multiply in Int128 to avoid Int64 overflow (max product ≈ 8.5×10³⁷ < Int128.max).
        let product = Int128(_storage) * Int128(rate.numeratorValue)
        let denominator = Int128(rate.denominatorValue)
        let (truncated, remainder) = product.quotientAndRemainder(dividingBy: denominator)

        // Apply the caller's rounding rule using pure integer comparisons.
        let minorUnits128 = _roundInt128(
            truncated: truncated,
            remainder: remainder,
            denominator: denominator,
            rule: rounding
        )

        // Bounds check: result must fit in Int64 and must not equal the NaN sentinel.
        precondition(
            minorUnits128 >= Int128(Int64.min) && minorUnits128 <= Int128(Int64.max),
            "Money fractional multiplication result overflows Int64"
        )
        let minorUnits = Int64(minorUnits128)
        precondition(
            minorUnits != .min,
            "Money fractional multiplication produced NaN sentinel"
        )

        let resultMoney = Money(_unchecked: minorUnits)

        // Build the actual rate = result / input (in lowest terms).
        // Normalise so that the denominator is positive (FractionalRate contract).
        // Inputs are validated above: minorUnits != .min, _storage != 0 and != .min.
        let actualRate: FractionalRate
        if _storage > 0 {
            actualRate = FractionalRate(_unchecked: minorUnits, denominator: _storage)
        } else {
            // _storage < 0 (non-zero, non-NaN): flip both signs so denominator > 0.
            actualRate = FractionalRate(_unchecked: -minorUnits, denominator: -_storage)
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
    /// - Returns: `nil` if `rhs` cannot be converted to a `FractionalRate`
    ///   (e.g. it is NaN, has an exponent ≥ 19, or its significand overflows `Int64`).
    /// - Precondition: `lhs` must not be NaN.
    public static func * (
        lhs: Money,
        rhs: Decimal
    ) -> FractionalMultiplicationResult<Currency>? {
        guard let rate = FractionalRate(rhs) else { return nil }
        return lhs.multiplied(by: rate)
    }
}

// MARK: - Internal helpers

/// Applies a `FloatingPointRoundingRule` to an integer division result expressed
/// as `truncated + remainder/denominator`.
///
/// `truncated` is the result of truncating division (toward zero). `remainder`
/// carries the same sign as the dividend (Swift's `%` contract). `denominator`
/// is always positive (enforced by `FractionalRate`).
///
/// Proof that the tie comparison `abs(r)*2` never overflows `Int128`:
/// - `abs(remainder) < denominator ≤ Int64.max`
/// - Therefore `abs(remainder)*2 < 2×Int64.max ≪ Int128.max`
internal func _roundInt128(
    truncated: Int128,
    remainder: Int128,
    denominator: Int128,
    rule: FloatingPointRoundingRule
) -> Int128 {
    guard remainder != 0 else { return truncated }

    switch rule {
    case .towardZero:
        // Truncating division already rounds toward zero.
        return truncated

    case .down:
        // Floor: subtract 1 if there is a negative fractional part.
        return remainder < 0 ? truncated - 1 : truncated

    case .up:
        // Ceiling: add 1 if there is a positive fractional part.
        return remainder > 0 ? truncated + 1 : truncated

    case .awayFromZero:
        // Away from zero: add 1 for positive remainder, subtract 1 for negative.
        return remainder > 0 ? truncated + 1 : truncated - 1

    case .toNearestOrAwayFromZero:
        // Round half away from zero (HALF_UP / commercial rounding).
        let absR = remainder < 0 ? -remainder : remainder
        let halfway = absR * 2 >= denominator
        if !halfway { return truncated }
        return remainder > 0 ? truncated + 1 : truncated - 1

    case .toNearestOrEven:
        // Banker's rounding (IEEE 754 default): round half to even.
        let absR = remainder < 0 ? -remainder : remainder
        let doubleR = absR * 2
        if doubleR < denominator { return truncated }          // below half: truncate
        if doubleR > denominator {                              // above half: round away
            return remainder > 0 ? truncated + 1 : truncated - 1
        }
        // Exact half: round to even — adjust only if truncated is odd.
        if truncated % 2 != 0 {
            return remainder > 0 ? truncated + 1 : truncated - 1
        }
        return truncated

    @unknown default:
        // Safe fallback: HALF_UP.
        let absR = remainder < 0 ? -remainder : remainder
        let halfway = absR * 2 >= denominator
        if !halfway { return truncated }
        return remainder > 0 ? truncated + 1 : truncated - 1
    }
}
#endif
