extension Fixed {
    // Same scale, so the raw values add directly. Traps if the true result is out of range.
    package static func + (lhs: Fixed, rhs: Fixed) -> Fixed {
        let (sum, overflow) = lhs.raw.addingReportingOverflow(rhs.raw)
        precondition(!overflow, "Fixed addition overflowed")

        return Fixed(raw: sum)
    }

    package static func - (lhs: Fixed, rhs: Fixed) -> Fixed {
        let (difference, overflow) = lhs.raw.subtractingReportingOverflow(rhs.raw)
        precondition(!overflow, "Fixed subtraction overflowed")

        return Fixed(raw: difference)
    }

    // Both operands carry the 10^18 scale, so the raw product carries 10^36 and needs 256 bits before
    // the scale is divided back out. Traps if the true result is out of range.
    package static func * (lhs: Fixed, rhs: Fixed) -> Fixed {
        let sign = Sign(of: lhs.raw) * Sign(of: rhs.raw)
        let product = Wide256Magnitude(lhs.raw.magnitude, times: rhs.raw.magnitude)

        guard let raw = bankersDivide256(product, by: UInt128(Fixed.scale), sign: sign) else {
            preconditionFailure("Fixed multiplication overflowed")
        }

        return Fixed(raw: raw)
    }

    // Scales the numerator by 10^18 first so the quotient keeps 18 fractional digits; that widening also
    // needs 256 bits. Traps if the true result is out of range.
    package static func / (lhs: Fixed, rhs: Fixed) -> Fixed {
        precondition(rhs.raw != 0, "Fixed divided by zero")

        let sign = Sign(of: lhs.raw) * Sign(of: rhs.raw)
        let numerator = Wide256Magnitude(lhs.raw.magnitude, times: UInt128(Fixed.scale))

        guard let raw = bankersDivide256(numerator, by: rhs.raw.magnitude, sign: sign) else {
            preconditionFailure("Fixed division overflowed")
        }

        return Fixed(raw: raw)
    }

    // Scales by a plain integer: the raw value multiplies directly, with no scale to divide out. Traps
    // if the true result is out of range.
    package func multiplied(by n: some BinaryInteger) -> Fixed {
        let (product, overflow) = raw.multipliedReportingOverflow(by: Int128(n))
        precondition(!overflow, "Fixed integer multiplication overflowed")

        return Fixed(raw: product)
    }

    // Divides by a plain integer, rounding half to even on the remainder. Traps on a zero divisor or an
    // out-of-range result.
    package func divided(by n: some BinaryInteger) -> Fixed {
        let divisor = Int128(n)
        precondition(divisor != 0, "Fixed divided by zero")

        let sign = Sign(of: raw) * Sign(of: divisor)
        let quotient = raw.magnitude / divisor.magnitude
        let remainder = raw.magnitude % divisor.magnitude

        let roundsUp = switch comparedToHalf(remainder: remainder, divisor: divisor.magnitude) {
        case .lessThanHalf: false
        case .moreThanHalf: true
        case .equalToHalf: !quotient.isMultiple(of: 2)   // ties to even
        }

        guard let result = Int128(magnitude: roundsUp ? quotient + 1 : quotient, sign: sign) else {
            preconditionFailure("Fixed integer division overflowed")
        }

        return Fixed(raw: result)
    }
}
