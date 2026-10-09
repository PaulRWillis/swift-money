// What a division left over, measured against half the divisor: the input to a rounding rule.
enum DroppedFraction {
    case zero
    case lessThanHalf
    case half
    case moreThanHalf

    // Compares against `divisor - remainder` rather than doubling the remainder, which could overflow.
    init(remainder: UInt64, divisor: UInt64) {
        guard remainder != 0 else {
            self = .zero
            return
        }
        let toNextWhole = divisor - remainder
        if remainder < toNextWhole {
            self = .lessThanHalf
        } else if remainder > toNextWhole {
            self = .moreThanHalf
        } else {
            self = .half
        }
    }

    @inline(__always)
    init(remainder: UInt128Words, divisor: UInt128Words) {
        guard remainder != 0 else {
            self = .zero
            return
        }
        let toNextWhole = divisor - remainder
        if remainder < toNextWhole {
            self = .lessThanHalf
        } else if remainder > toNextWhole {
            self = .moreThanHalf
        } else {
            self = .half
        }
    }
}
