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

    // Parses a decimal string such as "0.175", "-0.05" or "100". Exact when the value fits 18 fractional
    // digits; otherwise the excess is rounded by `rounding`. `nil` on any non-decimal input (a fraction
    // like "1/3", exponent notation, a second point, letters) or a significand too large to represent.
    package init?(
        decimal string: some StringProtocol,
        rounding: RoundingRule = .toNearestOrEven
    ) {
        var sign = Sign.positive
        var magnitude: UInt128 = 0
        var fractionDigits = 0
        var sawPoint = false
        var sawDigit = false
        var isFirst = true

        for byte in string.utf8 {
            if isFirst {
                isFirst = false
                if byte == UInt8(ascii: "-") {
                    sign = .negative
                    continue
                }
                if byte == UInt8(ascii: "+") {
                    continue
                }
            }

            if byte == UInt8(ascii: ".") {
                guard !sawPoint else {
                    return nil
                }
                sawPoint = true
                continue
            }

            guard let digit = byte.decimalDigitValue else {
                return nil
            }
            sawDigit = true
            guard let next = magnitude.multipliedByTenAdding(digit) else {
                return nil
            }
            magnitude = next
            if sawPoint {
                fractionDigits += 1
            }
        }

        guard sawDigit, let significand = Int128(magnitude: magnitude, sign: sign) else {
            return nil
        }

        self.init(significand: significand, exponent: -fractionDigits, rounding: rounding)
    }

    // Approximates a Double, whose ~15–16 significant digits are the precision ceiling. `nil` when the
    // value is not finite or is out of range. Named to signal the Double, not the Fixed, is the limit.
    package init?(
        approximating value: Double,
        rounding: RoundingRule = .toNearestOrEven
    ) {
        guard value.isFinite else {
            return nil
        }

        self.init(decimal: value.plainDecimalText, rounding: rounding)
    }

    // The value as a Double, for feeding solvers. Lossy at the edge, by design.
    package var double: Double {
        Double(raw) / Double(Fixed.scale)
    }
}

private extension UInt8 {
    // The value 0...9 of an ASCII decimal digit, or nil for any other byte. Byte-level on purpose:
    // `Character.isNumber` would accept non-decimal and non-ASCII digits.
    var decimalDigitValue: UInt8? {
        let zero = UInt8(ascii: "0")
        let nine = UInt8(ascii: "9")
        guard (zero ... nine).contains(self) else {
            return nil
        }

        return self - zero
    }
}

private extension UInt128 {
    // Shifts one decimal place and adds a digit, or nil on overflow.
    func multipliedByTenAdding(_ digit: UInt8) -> UInt128? {
        let (shifted, mulOverflow) = multipliedReportingOverflow(by: 10)
        guard !mulOverflow else {
            return nil
        }
        let (sum, addOverflow) = shifted.addingReportingOverflow(UInt128(digit))
        guard !addOverflow else {
            return nil
        }

        return sum
    }
}

private extension Double {
    // The shortest decimal that reads back as this value, written out in full. `description` switches to
    // exponent notation for very small and very large values, and the decimal parser reads digits only.
    var plainDecimalText: String {
        let text = description

        guard let marker = text.firstIndex(where: { $0 == "e" || $0 == "E" }),
              let exponent = Int(text[text.index(after: marker)...]) else {
            return text
        }

        return String(text[text.startIndex ..< marker]).shiftingPoint(by: exponent)
    }
}

private extension String {
    // The decimal point moved, by carrying digits across it and padding with zeros. No floating point is
    // involved, so nothing here can round.
    func shiftingPoint(by places: Int) -> String {
        var digits = Substring(self)
        let sign = digits.hasPrefix("-") ? "-" : ""

        if digits.hasPrefix("-") || digits.hasPrefix("+") {
            digits.removeFirst()
        }

        let point = digits.firstIndex(of: ".") ?? digits.endIndex
        var whole = String(digits[digits.startIndex ..< point])
        var fraction = point == digits.endIndex ? "" : String(digits[digits.index(after: point)...])

        if places >= 0 {
            let carried = min(places, fraction.count)
            whole += String(fraction.prefix(carried)) + String(repeating: "0", count: places - carried)
            fraction = String(fraction.dropFirst(carried))
        } else {
            let carried = min(-places, whole.count)
            fraction = String(repeating: "0", count: -places - carried)
                + String(whole.suffix(carried))
                + fraction
            whole = String(whole.dropLast(carried))
        }

        return sign + (whole.isEmpty ? "0" : whole) + (fraction.isEmpty ? "" : "." + fraction)
    }
}
