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
