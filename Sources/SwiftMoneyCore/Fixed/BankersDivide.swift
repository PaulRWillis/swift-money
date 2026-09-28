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

    return bankersRounded(quotient: quotient, remainder: remainder, divisor: divisor, sign: sign)
}

// The same, for a divisor that fits one 64-bit word, which divides in two cheaper steps.
func bankersDivide256(
    _ dividend: Wide256Magnitude,
    by divisor: UInt64,
    sign: Sign
) -> Int128? {
    guard let (quotient, remainder) = dividend.quotientAndRemainder(dividingBy: divisor) else {
        return nil
    }

    return bankersRounded(quotient: quotient, remainder: UInt128(remainder), divisor: UInt128(divisor), sign: sign)
}

private func bankersRounded(
    quotient: UInt128,
    remainder: UInt128,
    divisor: UInt128,
    sign: Sign
) -> Int128? {
    let roundsAway = switch comparedToHalf(remainder: remainder, divisor: divisor) {
    case .lessThanHalf: false
    case .moreThanHalf: true
    case .equalToHalf: !quotient.isMultiple(of: 2)   // ties to even
    }

    return signedRounded(quotient: quotient, roundsAway: roundsAway, sign: sign)
}
