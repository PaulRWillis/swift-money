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
}
