import SwiftMoneyCore

extension Gen where Value == Rate {
    /// A generator of non-negative rates on a decimal grid: `significand / denominator`, where the
    /// denominator is a power of ten so the value has that many fractional digits.
    ///
    /// The rate is built from a string, so the value is exact — no `Double` and no `Rate(approximating:)`.
    /// A significand over a positive power of ten is always a valid fraction, so `Rate(string:)` never
    /// returns `nil`; `?? "1"` names that unreachable fallback without a force unwrap.
    static func rate(
        significandIn significands: ClosedRange<Int64>,
        denominators: [Int64]
    ) -> Gen<Rate> {
        zip(Gen<Int64>.int(in: significands), Gen<Int64>.element(of: denominators)).map { significand, denominator in
            Rate(string: "\(significand)/\(denominator)") ?? "1"
        }
    }

    /// The powers of ten `10^0 … 10^6`, the fractional grid a generated rate lands on: a denominator of
    /// `10^n` gives the rate `n` fractional digits.
    static let decimalDenominators: [Int64] = [1, 10, 100, 1_000, 10_000, 100_000, 1_000_000]
}
