// A magnitude too large for a single word, as produced by multiplying two magnitudes.
//
// Multiplying can always be done, because a product of two words fits in two. Dividing is what can
// fail, since the result has to fit back into one.
struct WideMagnitude {
    private let high: UInt64
    private let low: UInt64

    init(
        _ magnitude: UInt64,
        times factor: UInt64
    ) {
        (high, low) = magnitude.multipliedFullWidth(by: factor)
    }

    // Divides by a positive divisor, giving a whole part and what is left over.
    //
    // `nil` when the whole part needs more than one word. That check is not defensive:
    // `dividingFullWidth` traps rather than reporting a quotient it cannot return, and the quotient
    // fits exactly when the high word is below the divisor.
    func quotientAndRemainder(
        dividingBy divisor: UInt64
    ) -> (quotient: UInt64, remainder: UInt64)? {
        guard high < divisor else {
            return nil
        }

        return divisor.dividingFullWidth((high: high, low: low))
    }
}
