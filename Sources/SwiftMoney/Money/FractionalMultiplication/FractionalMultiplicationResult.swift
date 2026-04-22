/// The result of multiplying a `Money` value by a ``FractionalRate``.
///
/// Because money is stored as a discrete integer number of minor units,
/// multiplying by a non-integer rate almost always produces a theoretically
/// fractional result that must be rounded. `FractionalMultiplicationResult`
/// carries both the rounded amount **and the rate that was actually applied**,
/// so callers can account for the rounding in downstream calculations.
///
/// The actual rate is defined as:
///
/// ```
/// actualRate = result / input
/// ```
///
/// This means `input × actualRate` reproduces `result` exactly — the
/// round-trip invariant holds with no residual error.
///
/// ### Example
///
/// ```swift
/// // 101 minor units × 1/100 = 1.01, rounded down to 1
/// let r = Money<GBP>(minorUnits: 101).multiplied(by: FractionalRate(numerator: 1, denominator: 100))
/// r.result      // Money<GBP>(minorUnits: 1)
/// r.actualRate  // FractionalRate(numerator: 1, denominator: 101)
/// // 101 × (1/101) == 1 ✓
/// ```
///
/// ### Zero input
///
/// When the input amount is zero, `0 × rate == 0` regardless of the rate,
/// so the actual rate is undefined. In this case `actualRate` equals the
/// **input rate** unchanged.
///
/// ```swift
/// let r = Money<GBP>.zero.multiplied(by: FractionalRate(numerator: 11, denominator: 100))
/// r.result      // Money<GBP>.zero
/// r.actualRate  // FractionalRate(numerator: 11, denominator: 100)  ← input rate returned
/// ```
public struct FractionalMultiplicationResult<C: Currency>: Sendable {

    // MARK: - Stored properties

    /// The rounded result of the multiplication.
    public let result: Money<C>

    /// The rate that was actually applied to produce ``result``.
    ///
    /// For non-zero input, this equals `result.minorUnits / input.minorUnits`
    /// in reduced form, which may differ from the requested rate when rounding
    /// occurred.
    ///
    /// For zero input, this equals the requested rate.
    public let actualRate: FractionalRate

    // MARK: - Initialiser

    /// Creates a `FractionalMultiplicationResult` with the given result and actual rate.
    public init(result: Money<C>, actualRate: FractionalRate) {
        self.result = result
        self.actualRate = actualRate
    }
}

// MARK: - Equatable

extension FractionalMultiplicationResult: Equatable {
    public static func == (
        lhs: FractionalMultiplicationResult<C>,
        rhs: FractionalMultiplicationResult<C>
    ) -> Bool {
        lhs.result == rhs.result && lhs.actualRate == rhs.actualRate
    }
}

// MARK: - CustomStringConvertible

extension FractionalMultiplicationResult: CustomStringConvertible {
    /// A human-readable description showing the result and the rate applied.
    ///
    /// ```swift
    /// // "1 (at rate: 1/101)"
    /// ```
    public var description: String {
        "\(result) (at rate: \(actualRate))"
    }
}
