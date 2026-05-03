#if canImport(Foundation)
import Foundation

extension Money {

    // MARK: - Rate Multiplication

    /// Returns the result of multiplying this value by the given fractional rate.
    ///
    /// Because money is stored as a discrete integer number of minor units,
    /// fractional multiplication almost always produces a theoretically
    /// fractional intermediate result that must be rounded. The returned
    /// ``RateCalculation`` carries both the rounded amount
    /// and the **actual rate that was applied**, so callers can account for
    /// the rounding in downstream calculations.
    ///
    /// The round-trip invariant holds: `input × effectiveRate == result`.
    ///
    /// ```swift
    /// // £1.01 × 1% — rounds down to £0.01; actual rate is 1/101 not 1/100
    /// let r = Money<GBP>(minorUnits: 101).multiplied(
    ///     by: Rate(numerator: 1, denominator: 100)
    /// )
    /// r.amount      // Money<GBP>(minorUnits: 1)
    /// r.effectiveRate  // Rate(numerator: 1, denominator: 101)
    /// ```
    ///
    /// - Parameters:
    ///   - rate: The fractional rate to multiply by.
    ///   - rounding: The rounding rule to apply when the result is not a whole
    ///     number of minor units. Defaults to `.toNearestOrAwayFromZero`.
    /// - Returns: A `RateCalculation` containing the rounded
    ///   result and the actual rate applied.
    /// - Precondition: `self` must not be NaN.
    public func multiplied(
        by rate: Rate,
        rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> RateCalculation<Currency> {
        precondition(!isNaN, "Cannot multiply NaN")

        // Zero input: 0 × anything == 0; rate is undefined so return input rate.
        if _storage == 0 {
            return RateCalculation(amount: .zero, effectiveRate: rate)
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
        // Normalise so that the denominator is positive (Rate contract).
        // Inputs are validated above: minorUnits != .min, _storage != 0 and != .min.
        let effectiveRate: Rate
        if _storage > 0 {
            effectiveRate = Rate(_unchecked: minorUnits, denominator: _storage)
        } else {
            // _storage < 0 (non-zero, non-NaN): flip both signs so denominator > 0.
            effectiveRate = Rate(_unchecked: -minorUnits, denominator: -_storage)
        }

        return RateCalculation(amount: resultMoney, effectiveRate: effectiveRate)
    }
}

// MARK: - Operators

extension Money {

    /// Returns the result of multiplying this `Money` value by a `Rate`.
    ///
    /// Uses `.toNearestOrAwayFromZero` rounding. To specify a different rounding
    /// rule, call ``multiplied(by:rounding:)`` directly.
    ///
    /// ```swift
    /// let r = Money<GBP>(minorUnits: 101) * Rate(numerator: 1, denominator: 100)
    /// r.amount      // Money<GBP>(minorUnits: 1)
    /// r.effectiveRate  // Rate(numerator: 1, denominator: 101)
    /// ```
    ///
    /// - Precondition: `lhs` must not be NaN.
    public static func * (
        lhs: Money,
        rhs: Rate
    ) -> RateCalculation<Currency> {
        lhs.multiplied(by: rhs)
    }

    /// Returns the result of multiplying this `Money` value by a `Decimal` rate.
    ///
    /// Converts `rhs` to a ``Rate`` via ``Rate/init(_:)``
    /// and then calls ``multiplied(by:rounding:)`` with
    /// `.toNearestOrAwayFromZero` rounding.
    ///
    /// > Warning: `Decimal` floating-point literals (e.g. `* 0.01`) are
    /// > initialised via `Double` and lose precision. Always prefer
    /// > `Decimal(string: "0.01")!` or an explicit
    /// > `Rate(numerator: 1, denominator: 100)`.
    ///
    /// ```swift
    /// // Precise:
    /// let r = Money<GBP>(minorUnits: 101) * Decimal(string: "0.01")!
    ///
    /// // Imprecise (Decimal literal goes through Double):
    /// // let r = Money<GBP>(minorUnits: 101) * 0.01  ← avoid
    /// ```
    ///
    /// - Returns: `nil` if `rhs` cannot be converted to a `Rate`
    ///   (e.g. it is NaN, has an exponent ≥ 19, or its significand overflows `Int64`).
    /// - Precondition: `lhs` must not be NaN.
    public static func * (
        lhs: Money,
        rhs: Decimal
    ) -> RateCalculation<Currency>? {
        guard let rate = Rate(rhs) else { return nil }
        return lhs.multiplied(by: rate)
    }
}

// MARK: - Internal helpers

/// Applies a `FloatingPointRoundingRule` to an integer division result expressed
/// as `truncated + remainder/denominator`.
///
/// `truncated` is the result of truncating division (toward zero). `remainder`
/// carries the same sign as the dividend (Swift's `%` contract). `denominator`
/// is always positive (enforced by `Rate`).
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
        let absoluteRemainder = remainder < 0 ? -remainder : remainder
        let halfway = absoluteRemainder * 2 >= denominator
        if !halfway { return truncated }
        return remainder > 0 ? truncated + 1 : truncated - 1

    case .toNearestOrEven:
        // Banker's rounding (IEEE 754 default): round half to even.
        let absoluteRemainder = remainder < 0 ? -remainder : remainder
        let doubledRemainder = absoluteRemainder * 2
        if doubledRemainder < denominator { return truncated }          // below half: truncate
        if doubledRemainder > denominator {                              // above half: round away
            return remainder > 0 ? truncated + 1 : truncated - 1
        }
        // Exact half: round to even — adjust only if truncated is odd.
        let isTruncatedOdd = truncated % 2 != 0
        if isTruncatedOdd {
            return remainder > 0 ? truncated + 1 : truncated - 1
        }
        return truncated

    @unknown default:
        // Safe fallback: HALF_UP.
        let absoluteRemainder = remainder < 0 ? -remainder : remainder
        let halfway = absoluteRemainder * 2 >= denominator
        if !halfway { return truncated }
        return remainder > 0 ? truncated + 1 : truncated - 1
    }
}
#endif
