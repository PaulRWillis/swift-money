// Where a division remainder sits relative to half of the divisor — the tie test for rounding.
enum ComparedToHalf {
    case lessThanHalf
    case equalToHalf
    case moreThanHalf
}

// Compares a remainder against half of its divisor without overflowing.
//
// A remainder is always smaller than its divisor, so `divisor - remainder` cannot underflow, and
// comparing against it avoids doubling the remainder (which could overflow a full-width word). This is
// the same comparison `Ratio` makes.
func comparedToHalf(
    remainder: UInt128,
    divisor: UInt128
) -> ComparedToHalf {
    let toNextWhole = divisor - remainder

    if remainder < toNextWhole {
        return .lessThanHalf
    }
    if remainder > toNextWhole {
        return .moreThanHalf
    }
    return .equalToHalf
}

// Whether a truncated magnitude should step away from zero, under the caller's rounding rule.
//
// Re-expresses `Ratio`'s rule table for a `Fixed` remainder: `sign` gives the direction for the directed
// rules, and `quotientIsEven` breaks ties for half-to-even. Only called when there is a real remainder
// to resolve.
func roundsAwayFromZero(
    rule: RoundingRule,
    sign: Sign,
    quotientIsEven: Bool,
    comparedToHalf position: ComparedToHalf
) -> Bool {
    switch rule {
    case .towardZero:
        false
    case .awayFromZero:
        true
    case .down:
        sign == .negative
    case .up:
        sign == .positive
    case .toNearestOrAwayFromZero:
        switch position {
        case .lessThanHalf: false
        case .equalToHalf: true
        case .moreThanHalf: true
        }
    case .toNearestOrEven:
        switch position {
        case .lessThanHalf: false
        case .equalToHalf: !quotientIsEven
        case .moreThanHalf: true
        }
    @unknown default:
        preconditionFailure("Unknown rounding rule: \(rule)")   // coverage:ignore — only a future RoundingRule case
    }
}

// Applies the rounding step and the sign, or `nil` when the true value doesn't fit `Int128`.
//
// `roundsAway` is the caller's decision to step the magnitude away from zero. Centralised so the
// increment-overflow check and the `Int128.min` handling live in one place, shared by the divides and
// by construction.
func signedRounded(quotient: UInt128, roundsAway: Bool, sign: Sign) -> Int128? {
    guard roundsAway else {
        return Int128(magnitude: quotient, sign: sign)
    }

    let (stepped, overflow) = quotient.addingReportingOverflow(1)
    guard !overflow else {
        return nil   // coverage:ignore — unreachable: a real quotient is far below UInt128.max
    }

    return Int128(magnitude: stepped, sign: sign)
}
