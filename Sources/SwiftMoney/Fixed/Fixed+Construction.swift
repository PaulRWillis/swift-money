extension Fixed {
    // Creates a value equal to `significand × 10^exponent`.
    //
    // Exact when the value has at most 18 fractional digits; otherwise the excess digits are rounded by
    // `rounding`. `nil` when the value is out of range.
    package init?(
        significand: Int128,
        exponent: Int,
        rounding: RoundingRule = .toNearestOrEven
    ) {
        // raw = significand × 10^(exponent + fractionalDigits)
        let shift = exponent + Fixed.fractionalDigits

        if shift >= 0 {
            guard let multiplier = Int128.powerOfTen(shift) else {
                return nil
            }
            let (raw, overflow) = significand.multipliedReportingOverflow(by: multiplier)
            guard !overflow else {
                return nil
            }
            self.init(raw: raw)
        } else {
            guard let divisor = Int128.powerOfTen(-shift) else {
                return nil
            }
            let sign = Sign(of: significand)
            let quotient = significand.magnitude / divisor.magnitude
            let remainder = significand.magnitude % divisor.magnitude

            let magnitude: UInt128
            if remainder == 0 {
                magnitude = quotient
            } else {
                let roundsAway = roundsAwayFromZero(
                    rule: rounding,
                    sign: sign,
                    quotientIsEven: quotient.isMultiple(of: 2),
                    comparedToHalf: comparedToHalf(remainder: remainder, divisor: divisor.magnitude)
                )
                magnitude = roundsAway ? quotient + 1 : quotient
            }

            guard let raw = Int128(magnitude: magnitude, sign: sign) else {
                return nil
            }
            self.init(raw: raw)
        }
    }

    // Creates a whole value. Traps if it is out of range.
    package init(_ value: some BinaryInteger) {
        guard let fixed = Fixed(significand: Int128(value), exponent: 0) else {
            preconditionFailure("Value is out of range for Fixed")
        }

        self = fixed
    }

    // Creates a whole value, or `nil` if it is out of range.
    package init?(exactly value: some BinaryInteger) {
        guard let significand = Int128(exactly: value),
              let fixed = Fixed(significand: significand, exponent: 0) else {
            return nil
        }

        self = fixed
    }
}
