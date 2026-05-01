/// The result of multiplying a `Money` value by a ``Rate``.
///
/// Because money is stored as a discrete integer number of minor units,
/// multiplying by a non-integer rate almost always produces a theoretically
/// fractional result that must be rounded. `RateCalculation`
/// carries both the rounded amount **and the rate that was actually applied**,
/// so callers can account for the rounding in downstream calculations.
///
/// The actual rate is defined as:
///
/// ```
/// effectiveRate = result / input
/// ```
///
/// This means `input × effectiveRate` reproduces `result` exactly — the
/// round-trip invariant holds with no residual error.
///
/// ### Example
///
/// ```swift
/// // 101 minor units × 1/100 = 1.01, rounded down to 1
/// let r = Money<GBP>(minorUnits: 101).multiplied(by: Rate(numerator: 1, denominator: 100))
/// r.amount      // Money<GBP>(minorUnits: 1)
/// r.effectiveRate  // Rate(numerator: 1, denominator: 101)
/// // 101 × (1/101) == 1 ✓
/// ```
///
/// ### Zero input
///
/// When the input amount is zero, `0 × rate == 0` regardless of the rate,
/// so the actual rate is undefined. In this case `effectiveRate` equals the
/// **input rate** unchanged.
///
/// ```swift
/// let r = Money<GBP>.zero.multiplied(by: Rate(numerator: 11, denominator: 100))
/// r.amount      // Money<GBP>.zero
/// r.effectiveRate  // Rate(numerator: 11, denominator: 100)  ← input rate returned
/// ```
public struct RateCalculation<C: Currency>: Sendable {

    // MARK: - Stored properties

    /// The rounded result of the multiplication.
    public let amount: Money<C>

    /// The rate that was actually applied to produce ``result``.
    ///
    /// For non-zero input, this equals `result.minorUnits / input.minorUnits`
    /// in reduced form, which may differ from the requested rate when rounding
    /// occurred.
    ///
    /// For zero input, this equals the requested rate.
    public let effectiveRate: Rate

    // MARK: - Initialiser

    /// Creates a `RateCalculation` with the given result and actual rate.
    public init(amount: Money<C>, effectiveRate: Rate) {
        self.amount = amount
        self.effectiveRate = effectiveRate
    }
}

// MARK: - Equatable

extension RateCalculation: Equatable {
    public static func == (
        lhs: RateCalculation<C>,
        rhs: RateCalculation<C>
    ) -> Bool {
        lhs.amount == rhs.amount && lhs.effectiveRate == rhs.effectiveRate
    }
}

