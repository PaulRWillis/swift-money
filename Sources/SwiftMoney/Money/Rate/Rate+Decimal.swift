#if canImport(Foundation)
import Foundation

// MARK: - Decimal initialiser

extension Rate {

    /// Creates a `Rate` from a `Foundation.Decimal` value.
    ///
    /// Extracts the exact integer significand and decimal exponent from the
    /// `Decimal`'s internal representation and constructs the fraction without
    /// any loss of precision. The method is lossless for any `Decimal` constructed
    /// from `Decimal(string:)` whose significand fits within `Int64` (up to 18
    /// significant decimal digits).
    ///
    /// ```swift
    /// Rate(Decimal(string: "0.11")!)            // 11/100
    /// Rate(Decimal(string: "1.5")!)             // 3/2
    /// Rate(Decimal(string: "0.12345678901234")!) // 6172839450617/50000000000000
    /// ```
    ///
    /// - Parameter decimal: The rate as a `Decimal`.
    /// - Returns: `nil` if `decimal` is NaN, if the exponent's absolute value is ≥ 19
    ///   (10¹⁹ exceeds `Int64`), or if the significand does not fit within `Int64`.
    public init?(_ decimal: Decimal) {
        guard !decimal.isNaN else { return nil }

        let decimalExponent = decimal.exponent

        let significand = Self._extractSignificand(from: decimal, exponent: decimalExponent)
        let isExactInt64Significand = significand != nil
        guard isExactInt64Significand, let significand else { return nil }

        if decimalExponent >= 0 {
            self.init(_positiveExponent: decimalExponent, significand: significand)
        } else {
            self.init(_negativeExponent: -decimalExponent, significand: significand)
        }
    }

    // MARK: - Private decomposition helpers

    private static func _extractSignificand(from decimal: Decimal, exponent: Int) -> Int64? {
        var input = decimal
        var significandDecimal = Decimal()
        NSDecimalMultiplyByPowerOf10(&significandDecimal, &input, Int16(-exponent), .plain)

        let significand = NSDecimalNumber(decimal: significandDecimal).int64Value
        let isRoundTripExact = Decimal(significand) == significandDecimal
        let isValidNumerator = significand != .min
        guard isRoundTripExact, isValidNumerator else { return nil }
        return significand
    }

    private init?(_positiveExponent exponent: Int, significand: Int64) {
        guard exponent < _pow10Table.count else { return nil }
        let (numerator, didOverflow) = significand.multipliedReportingOverflow(by: _pow10Table[exponent])
        guard !didOverflow, numerator != .min else { return nil }
        self.init(_unchecked: numerator, denominator: 1)
    }

    private init?(_negativeExponent exponent: Int, significand: Int64) {
        guard exponent < _pow10Table.count else { return nil }
        let denominator = _pow10Table[exponent]
        self.init(_unchecked: significand, denominator: denominator)
    }
}

// MARK: - Internal helpers

/// Precomputed powers of 10 for exponents 0...18.
///
/// Used by `Rate.init?(_ decimal:)` to reconstruct a fraction from
/// Foundation's `Decimal` representation. `Int64.max ≈ 9.22 × 10¹⁸`, so
/// `10¹⁹` does not fit; the table stops at index 18.
internal let _pow10Table: [Int64] = [
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
#endif
