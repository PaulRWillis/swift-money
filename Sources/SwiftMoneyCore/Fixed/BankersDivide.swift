// Divides a 256-bit magnitude by a 128-bit divisor, rounding half to even, then applies the sign.
//
// Half-to-even is the sub-unit rounding floor the engine relies on: it is fixed here, not a caller
// choice. Returns `nil` when the true result does not fit `Int128` — the whole part needs more than one
// word, rounding carries it past the range, or the signed magnitude has no counterpart. Callers that
// treat that as a bug trap on `nil`; callers handling external data report it.
func bankersDivide256(
    _ dividend: Wide256Magnitude,
    by divisor: UInt128,
    sign: Sign
) -> Int128? {
    guard let (quotient, remainder) = dividend.quotientAndRemainder(dividingBy: divisor) else {
        return nil
    }

    return bankersRounded(quotient: quotient, dropped: DroppedFraction(remainder: remainder, divisor: divisor), sign: sign)
}

// The same, dividing by `Fixed`'s scale.
@inline(__always)
func bankersDivideByScale(
    _ dividend: Wide256Magnitude,
    sign: Sign
) -> Int128? {
    guard let (quotient, remainder) = dividend.quotientAndRemainderDividingByScale() else {
        return nil
    }

    let dropped = DroppedFraction(remainder: remainder, divisor: Fixed.Scale.divisor)
    return bankersRounded(quotient: quotient, dropped: dropped, sign: sign)
}

private func bankersRounded(
    quotient: UInt128,
    dropped: DroppedFraction,
    sign: Sign
) -> Int128? {
    let roundsAway = RoundingRule.toNearestOrEven.stepsAwayFromZero(
        dropping: dropped, sign: sign, truncatedIsEven: quotient.isMultiple(of: 2)
    )
    return signedRounded(quotient: quotient, roundsAway: roundsAway, sign: sign)
}
