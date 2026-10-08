// A magnitude too large for a single 128-bit word, as produced by multiplying two 128-bit magnitudes.
//
// A sibling of `WideMagnitude` one word wider: two `UInt128Words` limbs hold the 256-bit product. Kept
// separate rather than made generic: only two widths are ever used, and the money path's
// `WideMagnitude` stays untouched.
struct Wide256Magnitude {
    private let high: UInt128Words
    private let low: UInt128Words

    init(
        _ magnitude: UInt128Words,
        times factor: UInt128Words
    ) {
        (high, low) = magnitude.multipliedFullWidth(by: factor)
    }

    // Divides by a positive divisor, giving a whole part and what is left over.
    //
    // `nil` when the whole part needs more than one word. That check is not defensive:
    // `dividingFullWidth` traps rather than reporting a quotient it cannot return, and the quotient
    // fits exactly when the high word is below the divisor.
    func quotientAndRemainder(
        dividingBy divisor: UInt128Words
    ) -> (quotient: UInt128Words, remainder: UInt128Words)? {
        guard high < divisor else {
            return nil
        }

        return divisor.dividingFullWidth((high: high, low: low))
    }

    // The same for `Fixed`'s scale, 10^18: long division one 64-bit limb at a time. `high < 10^18`
    // keeps each step's top word below the divisor, which is what `Fixed.Scale.divide` requires.
    @inline(__always)
    func quotientAndRemainderDividingByScale() -> (quotient: UInt128Words, remainder: UInt64)? {
        guard high < UInt128Words(Fixed.Scale.divisor) else {
            return nil
        }

        // Below the divisor, `high` is its own low word, the running remainder of the first step.
        let (upper, carried) = Fixed.Scale.divide(high: high.low, low: low.high)
        let (lower, remainder) = Fixed.Scale.divide(high: carried, low: low.low)

        return (UInt128Words(high: upper, low: lower), remainder)
    }
}
