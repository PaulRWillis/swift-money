extension RoundingRule {
    // The step settling takes from the truncated magnitude. `sign` gives the direction for the directed
    // rules; the truncated magnitude's parity breaks a tie for half-to-even.
    // Returning an enum left this out of line in its callers, costing every settle about 30 instructions.
    @inline(__always)
    func step(dropping dropped: DroppedFraction, sign: Sign, truncated parity: Parity) -> RoundingStep {
        if dropped == .zero {
            return .keep
        }

        switch self {
        case .towardZero:
            return .keep
        case .awayFromZero:
            return .awayFromZero
        case .down:
            return sign == .negative ? .awayFromZero : .keep
        case .up:
            return sign == .positive ? .awayFromZero : .keep
        case .toNearestOrAwayFromZero:
            return dropped == .lessThanHalf ? .keep : .awayFromZero
        case .toNearestOrEven:
            switch dropped {
            case .zero, .lessThanHalf: return .keep
            case .half: return parity == .even ? .keep : .awayFromZero
            case .moreThanHalf: return .awayFromZero
            }
        }
    }
}

// Applies the rounding step and the sign, or `nil` when the true value doesn't fit `Int128`.
// One function for the divides and construction, so the overflow and `Int128.min` handling live once.
func signedRounded(quotient: UInt128, step: RoundingStep, sign: Sign) -> Int128? {
    guard step == .awayFromZero else {
        return Int128(magnitude: quotient, sign: sign)
    }

    let (stepped, overflow) = quotient.addingReportingOverflow(1)
    guard !overflow else {
        return nil   // coverage:ignore — unreachable: a real quotient is far below UInt128.max
    }

    return Int128(magnitude: stepped, sign: sign)
}
