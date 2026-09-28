// A magnitude too large for a single 128-bit word, as produced by multiplying two 128-bit magnitudes.
//
// A sibling of `WideMagnitude` one word wider: two `UInt128` limbs hold the 256-bit product. Kept
// deliberately separate rather than made generic — only two widths are ever used, and the money path's
// `WideMagnitude` stays untouched.
struct Wide256Magnitude {
    private let high: UInt128
    private let low: UInt128

    init(
        _ magnitude: UInt128,
        times factor: UInt128
    ) {
        (high, low) = magnitude.multipliedFullWidth(by: factor)
    }

    // Divides by a positive divisor, giving a whole part and what is left over.
    //
    // `nil` when the whole part needs more than one word. That check is not defensive:
    // `dividingFullWidth` traps rather than reporting a quotient it cannot return, and the quotient
    // fits exactly when the high word is below the divisor.
    func quotientAndRemainder(
        dividingBy divisor: UInt128
    ) -> (quotient: UInt128, remainder: UInt128)? {
        guard high < divisor else {
            return nil
        }

        return divisor.dividingFullWidth((high: high, low: low))
    }

    // The same, for a divisor that fits one 64-bit word: long division, one 64-bit limb at a time.
    // `high < divisor` keeps both steps' quotients within a word, so neither `dividingFullWidth` traps.
    func quotientAndRemainder(
        dividingBy divisor: UInt64
    ) -> (quotient: UInt128, remainder: UInt64)? {
        guard high < UInt128(divisor) else {
            return nil
        }

        // Below the divisor, `high` is its own low limb, the running remainder of the first step.
        let (upper, carried) = divisor.dividingFullWidth(
            (high: UInt64(truncatingIfNeeded: high), low: UInt64(truncatingIfNeeded: low >> 64))
        )
        let (lower, remainder) = divisor.dividingFullWidth(
            (high: carried, low: UInt64(truncatingIfNeeded: low))
        )

        return (UInt128(upper) << 64 | UInt128(lower), remainder)
    }
}
