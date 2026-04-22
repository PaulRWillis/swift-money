/// A rational fraction used as a multiplication rate for monetary amounts.
///
/// `FractionalRate` represents a rate as an irreducible integer fraction
/// `numeratorValue / denominatorValue`. The denominator is always strictly
/// positive; negative rates are expressed through a negative numerator.
///
/// ```swift
/// let tax      = FractionalRate(numerator: 11, denominator: 100)   // 11%
/// let discount = FractionalRate(numerator: -1, denominator: 10)    // -10%
/// let quarter  = FractionalRate(Decimal(string: "0.25")!)          // 1/4
/// let doubling: FractionalRate = 2                                 // 2/1
/// ```
///
/// Fractions are automatically reduced at initialisation time using the
/// Euclidean GCD, so `FractionalRate(numerator: 22, denominator: 200)` stores
/// as `11/100` and compares equal to `FractionalRate(numerator: 11, denominator: 100)`.
public struct FractionalRate: Sendable {

    // MARK: - Storage (internal — not part of the public API)

    /// The numerator of the reduced fraction. May be negative.
    internal let _numerator: Int64

    /// The denominator of the reduced fraction. Always greater than zero.
    internal let _denominator: Int64

    // MARK: - Designated initialiser (internal)

    /// Creates a `FractionalRate` from a pre-validated numerator/denominator pair.
    ///
    /// Callers **must** guarantee:
    /// - `denominator > 0`
    /// - `numerator != .min`
    ///
    /// No preconditions are checked. Used internally after explicit guard checks.
    internal init(_unchecked numerator: Int64, denominator: Int64) {
        let absNumerator = numerator < 0 ? -numerator : numerator
        let g = _gcd(absNumerator, denominator)
        _numerator = numerator / g
        _denominator = denominator / g
    }

    // MARK: - Integer pair initialiser

    /// Creates a `FractionalRate` from an explicit integer numerator and denominator.
    ///
    /// The fraction is stored in reduced (lowest-terms) form. For example,
    /// `FractionalRate(numerator: 22, denominator: 200)` stores as `11/100`.
    ///
    /// Returns `nil` if `denominator <= 0` or `numerator == Int64.min` (whose
    /// absolute value overflows `Int64` and cannot be GCD-reduced).
    ///
    /// - Parameters:
    ///   - numerator: The numerator of the fraction. May be any `Int64` value
    ///     except `Int64.min`.
    ///   - denominator: The denominator of the fraction. Must be greater than zero.
    public init?(numerator: Int64, denominator: Int64) {
        guard denominator > 0, numerator != .min else { return nil }
        self.init(_unchecked: numerator, denominator: denominator)
    }

    // MARK: - Accessors

    /// The numerator of the reduced fraction.
    ///
    /// May be negative; the sign of the rate is carried entirely in the
    /// numerator.
    public var numeratorValue: Int64 { _numerator }

    /// The denominator of the reduced fraction. Always greater than zero.
    public var denominatorValue: Int64 { _denominator }
}

// MARK: - Private helpers

/// Euclidean GCD. `a` must be ≥ 0; `b` must be > 0.
/// Returns 1 when `a` is 0 so callers can always divide safely.
internal func _gcd(_ a: Int64, _ b: Int64) -> Int64 {
    var a = a
    var b = b
    while b != 0 {
        let t = b
        b = a % b
        a = t
    }
    return a == 0 ? 1 : a
}

/// Euclidean GCD for `Int128`. `a` must be ≥ 0; `b` must be > 0.
/// Returns 1 when `a` is 0 so callers can always divide safely.
internal func _gcd(_ a: Int128, _ b: Int128) -> Int128 {
    var a = a
    var b = b
    while b != 0 {
        let t = b
        b = a % b
        a = t
    }
    return a == 0 ? 1 : a
}
