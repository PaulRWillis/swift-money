import Foundation

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
///
/// ## Initialising from `Decimal`
///
/// When initialising from a `Decimal`, the exact integer significand and
/// decimal exponent are extracted losslessly. The method works without any
/// rounding for any `Decimal` constructed from `Decimal(string:)` whose
/// significand fits within `Int64` (up to 18 significant decimal digits).
/// Returns `nil` for NaN values or when the magnitude would overflow `Int64`.
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

    // MARK: - Decimal initialiser

    /// Creates a `FractionalRate` from a `Foundation.Decimal` value.
    ///
    /// Extracts the exact integer significand and decimal exponent from the
    /// `Decimal`'s internal representation and constructs the fraction without
    /// any loss of precision. The method is lossless for any `Decimal` constructed
    /// from `Decimal(string:)` whose significand fits within `Int64` (up to 18
    /// significant decimal digits).
    ///
    /// ```swift
    /// FractionalRate(Decimal(string: "0.11")!)            // 11/100
    /// FractionalRate(Decimal(string: "1.5")!)             // 3/2
    /// FractionalRate(Decimal(string: "0.12345678901234")!) // 6172839450617/50000000000000
    /// ```
    ///
    /// - Parameter decimal: The rate as a `Decimal`.
    /// - Returns: `nil` if `decimal` is NaN, if the exponent's absolute value is ≥ 19
    ///   (10¹⁹ exceeds `Int64`), or if the significand does not fit within `Int64`.
    public init?(_ decimal: Decimal) {
        guard !decimal.isNaN else { return nil }

        let exp = decimal.exponent   // Int; Foundation stores as Int8 internally (-128...127)

        // Extract the exact integer significand by multiplying by 10^(-exp).
        // NSDecimalMultiplyByPowerOf10 only adjusts the internal exponent field;
        // it does not perform any lossy arithmetic, so this is zero-precision-loss.
        var input = decimal
        var significandDecimal = Decimal()
        NSDecimalMultiplyByPowerOf10(&significandDecimal, &input, Int16(-exp), .plain)

        let significand = NSDecimalNumber(decimal: significandDecimal).int64Value
        // Round-trip check: the significand as a Decimal must reproduce the
        // scaled value exactly. Fails if the significand exceeds Int64 range.
        guard Decimal(significand) == significandDecimal, significand != .min else { return nil }

        if exp >= 0 {
            // value = significand × 10^exp  →  fraction = (significand × 10^exp) / 1
            guard exp < _pow10Table.count else { return nil }
            let (numerator, overflow) = significand.multipliedReportingOverflow(by: _pow10Table[exp])
            guard !overflow, numerator != .min else { return nil }
            self.init(_unchecked: numerator, denominator: 1)
        } else {
            // value = significand / 10^(-exp)  →  fraction = significand / 10^(-exp)
            let negExp = -exp
            guard negExp < _pow10Table.count else { return nil }
            let denominator = _pow10Table[negExp]
            self.init(_unchecked: significand, denominator: denominator)
        }
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

/// Precomputed powers of 10 for exponents 0...18.
///
/// `Int64.max ≈ 9.22 × 10¹⁸`, so `10¹⁹` does not fit; the table stops at index 18.
private let _pow10Table: [Int64] = [
    1,                          // 10^0
    10,                         // 10^1
    100,                        // 10^2
    1_000,                      // 10^3
    10_000,                     // 10^4
    100_000,                    // 10^5
    1_000_000,                  // 10^6
    10_000_000,                 // 10^7
    100_000_000,                // 10^8
    1_000_000_000,              // 10^9
    10_000_000_000,             // 10^10
    100_000_000_000,            // 10^11
    1_000_000_000_000,          // 10^12
    10_000_000_000_000,         // 10^13
    100_000_000_000_000,        // 10^14
    1_000_000_000_000_000,      // 10^15
    10_000_000_000_000_000,     // 10^16
    100_000_000_000_000_000,    // 10^17
    1_000_000_000_000_000_000,  // 10^18
]

/// Euclidean GCD. `a` must be ≥ 0; `b` must be > 0.
/// Returns 1 when `a` is 0 so callers can always divide safely.
private func _gcd(_ a: Int64, _ b: Int64) -> Int64 {
    var a = a
    var b = b
    while b != 0 {
        let t = b
        b = a % b
        a = t
    }
    return a == 0 ? 1 : a
}
