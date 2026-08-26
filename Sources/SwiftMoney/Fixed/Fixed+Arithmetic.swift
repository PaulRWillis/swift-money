extension Fixed {
    // Adds two same-scale values, reporting overflow instead of trapping.
    package func addingReportingOverflow(_ other: Fixed) -> (value: Fixed, overflow: Bool) {
        let (sum, overflow) = raw.addingReportingOverflow(other.raw)
        return (Fixed(raw: sum), overflow)
    }

    package func subtractingReportingOverflow(_ other: Fixed) -> (value: Fixed, overflow: Bool) {
        let (difference, overflow) = raw.subtractingReportingOverflow(other.raw)
        return (Fixed(raw: difference), overflow)
    }

    // Both operands carry the 10^18 scale, so the raw product carries 10^36 and needs 256 bits before
    // the scale is divided back out. On overflow the value is unspecified and `overflow` is true.
    package func multipliedReportingOverflow(by other: Fixed) -> (value: Fixed, overflow: Bool) {
        let sign = Sign(of: raw) * Sign(of: other.raw)
        let product = Wide256Magnitude(raw.magnitude, times: other.raw.magnitude)

        guard let result = bankersDivide256(product, by: UInt128(Fixed.scale), sign: sign) else {
            return (.zero, true)
        }

        return (Fixed(raw: result), false)
    }

    // Scales by a plain integer: the raw value multiplies directly, with no scale to divide out.
    package func multipliedReportingOverflow(by n: some BinaryInteger) -> (value: Fixed, overflow: Bool) {
        guard let factor = Int128(exactly: n) else {
            return (.zero, true)
        }
        let (product, overflow) = raw.multipliedReportingOverflow(by: factor)
        return (Fixed(raw: product), overflow)
    }
}

extension Fixed {
    // The trapping operators wrap the reporting forms: fail fast on a genuine out-of-range result.
    package static func + (lhs: Fixed, rhs: Fixed) -> Fixed {
        let (value, overflow) = lhs.addingReportingOverflow(rhs)
        precondition(!overflow, "Fixed addition overflowed")

        return value
    }

    package static func - (lhs: Fixed, rhs: Fixed) -> Fixed {
        let (value, overflow) = lhs.subtractingReportingOverflow(rhs)
        precondition(!overflow, "Fixed subtraction overflowed")

        return value
    }

    package static func * (lhs: Fixed, rhs: Fixed) -> Fixed {
        let (value, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow, "Fixed multiplication overflowed")

        return value
    }

    // Scales the numerator by 10^18 first so the quotient keeps 18 fractional digits; that widening also
    // needs 256 bits. Traps on a zero divisor or an out-of-range result.
    package static func / (lhs: Fixed, rhs: Fixed) -> Fixed {
        precondition(rhs.raw != 0, "Fixed divided by zero")

        let sign = Sign(of: lhs.raw) * Sign(of: rhs.raw)
        let numerator = Wide256Magnitude(lhs.raw.magnitude, times: UInt128(Fixed.scale))

        guard let raw = bankersDivide256(numerator, by: rhs.raw.magnitude, sign: sign) else {
            preconditionFailure("Fixed division overflowed")
        }

        return Fixed(raw: raw)
    }

    package func multiplied(by n: some BinaryInteger) -> Fixed {
        let (value, overflow) = multipliedReportingOverflow(by: n)
        precondition(!overflow, "Fixed integer multiplication overflowed")

        return value
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

extension Fixed {
    // Fallible siblings for values derived from external data: `nil` instead of a trap on overflow.
    package func addingIfRepresentable(_ other: Fixed) -> Fixed? {
        let (value, overflow) = addingReportingOverflow(other)
        return overflow ? nil : value
    }

    package func subtractingIfRepresentable(_ other: Fixed) -> Fixed? {
        let (value, overflow) = subtractingReportingOverflow(other)
        return overflow ? nil : value
    }

    package func multipliedIfRepresentable(by other: Fixed) -> Fixed? {
        let (value, overflow) = multipliedReportingOverflow(by: other)
        return overflow ? nil : value
    }

    package func multipliedIfRepresentable(by n: some BinaryInteger) -> Fixed? {
        let (value, overflow) = multipliedReportingOverflow(by: n)
        return overflow ? nil : value
    }
}
