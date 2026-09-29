extension RoundingRule {
    // Whether settling steps the truncated magnitude one away from zero. `sign` gives the direction for
    // the directed rules; `truncatedIsEven` breaks a tie for half-to-even.
    func stepsAwayFromZero(dropping dropped: DroppedFraction, sign: Sign, truncatedIsEven: Bool) -> Bool {
        if dropped == .zero {
            return false
        }

        switch self {
        case .towardZero:
            return false
        case .awayFromZero:
            return true
        case .down:
            return sign == .negative
        case .up:
            return sign == .positive
        case .toNearestOrAwayFromZero:
            return dropped != .lessThanHalf
        case .toNearestOrEven:
            switch dropped {
            case .zero, .lessThanHalf: return false
            case .half: return !truncatedIsEven
            case .moreThanHalf: return true
            }
        }
    }
}

// Applies the rounding step and the sign, or `nil` when the true value doesn't fit `Int128`.
//
// Centralised so the increment-overflow check and the `Int128.min` handling live in one place, shared by
// the divides and by construction.
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
