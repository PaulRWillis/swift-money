#if canImport(Foundation)
import Foundation

// MARK: - Decimal initialiser

extension FractionalRate {

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
}

// MARK: - Internal helpers

/// Precomputed powers of 10 for exponents 0...18.
///
/// Used by `FractionalRate.init?(_ decimal:)` to reconstruct a fraction from
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
