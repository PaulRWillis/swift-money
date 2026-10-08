extension Fixed {
    // Ten to the eighteenth: a `Fixed` holds its value as a whole number of these parts. The only copy
    // of the constant, and the only divisor the reciprocal below is correct for.
    enum Scale {
        // Computed, not `static let`: a stored struct is lazily initialized, a check on every read.
        static var divisor: UInt64 { 1_000_000_000_000_000_000 }
        static var value: Int128Words { Int128Words(bitPattern: UInt128Words(divisor)) }

        // `(high, low) ÷ 10^18`, for `high < 10^18`.
        //
        // Möller and Granlund, "Improved division by invariant integers" (IEEE Trans. Computers, 2011),
        // Algorithm 4, is exact under three conditions, each checked here:
        // 1. The divisor is normalized: `d = 10^18 << 4 = 1.6 × 10^19`, and `2^63 ≤ d < 2^64`.
        // 2. The dividend's top word is below it: `high < 10^18` gives
        //    `u1 = 16·high + (low >> 60) ≤ 16·(10^18 − 1) + 15 < d`. This is what the callers' guard
        //    proves, not only that the quotient fits a word.
        // 3. `reciprocal = ⌊(2^128 − 1) / d⌋ − 2^64`.
        // Every shift is by the literal 4 (10^18's leading zero bits), so no other divisor can reach it.
        static func divide(high: UInt64, low: UInt64) -> (quotient: UInt64, remainder: UInt64) {
            let normalized = divisor << 4
            let reciprocal: UInt64 = 0x2725_DD1D_243A_BA0E
            let u1 = high << 4 | low >> 60
            let u0 = low << 4

            let (productHigh, productLow) = reciprocal.multipliedFullWidth(by: u1)
            let (q0, carry) = productLow.addingReportingOverflow(u0)
            var q1 = productHigh &+ u1 &+ (carry ? 1 : 0) &+ 1
            var r = u0 &- q1 &* normalized
            if r > q0 {
                q1 &-= 1
                r &+= normalized
            }
            if r >= normalized {
                q1 &+= 1
                r &-= normalized
            }

            return (q1, r >> 4)
        }
    }
}
