// A base-10 fixed-point number with 18 fractional digits, backed by `Int128`.
//
// The value is `_storage / 10^18`, so 0.05 is held as `_storage == 50_000_000_000_000_000`. This is the
// internal precision engine for fractional money; it knows nothing of currency or minor units. Callers
// construct it and send it commands and queries — the storage is private and never reached into, which
// is why every operation that touches it lives in this file.
package struct Fixed: Equatable, Hashable, Sendable, BitwiseCopyable {
    private var _storage: Int128

    // The number of fractional digits a value is held to, and ten raised to that power.
    private static let fractionalDigits = 18
    private static let scale: Int128 = 1_000_000_000_000_000_000

    private init(_storage: Int128) {
        self._storage = _storage
    }

    package static let zero = Fixed(_storage: 0)
}

extension Fixed: Comparable {
    package static func < (lhs: Fixed, rhs: Fixed) -> Bool {
        lhs._storage < rhs._storage
    }
}

extension Fixed {
    // Adds two same-scale values, reporting overflow instead of trapping.
    package func addingReportingOverflow(_ other: Fixed) -> (value: Fixed, overflow: Bool) {
        let (sum, overflow) = _storage.addingReportingOverflow(other._storage)
        return (Fixed(_storage: sum), overflow)
    }

    package func subtractingReportingOverflow(_ other: Fixed) -> (value: Fixed, overflow: Bool) {
        let (difference, overflow) = _storage.subtractingReportingOverflow(other._storage)
        return (Fixed(_storage: difference), overflow)
    }

    // Both operands carry the 10^18 scale, so the raw product carries 10^36 and needs 256 bits before
    // the scale is divided back out. On overflow the value is unspecified and `overflow` is true.
    package func multipliedReportingOverflow(by other: Fixed) -> (value: Fixed, overflow: Bool) {
        let sign = Sign(of: _storage) * Sign(of: other._storage)
        let product = Wide256Magnitude(_storage.magnitude, times: other._storage.magnitude)

        guard let result = bankersDivide256(product, by: UInt128(Fixed.scale), sign: sign) else {
            return (.zero, true)
        }

        return (Fixed(_storage: result), false)
    }

    // Scales by a plain integer: the raw value multiplies directly, with no scale to divide out.
    package func multipliedReportingOverflow(by n: some BinaryInteger) -> (value: Fixed, overflow: Bool) {
        guard let factor = Int128(exactly: n) else {
            return (.zero, true)
        }
        let (product, overflow) = _storage.multipliedReportingOverflow(by: factor)
        return (Fixed(_storage: product), overflow)
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
        precondition(rhs._storage != 0, "Fixed divided by zero")

        let sign = Sign(of: lhs._storage) * Sign(of: rhs._storage)
        let numerator = Wide256Magnitude(lhs._storage.magnitude, times: UInt128(Fixed.scale))

        guard let storage = bankersDivide256(numerator, by: rhs._storage.magnitude, sign: sign) else {
            preconditionFailure("Fixed division overflowed")
        }

        return Fixed(_storage: storage)
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

        let sign = Sign(of: _storage) * Sign(of: divisor)
        let (quotient, remainder) = _storage.magnitude.quotientAndRemainder(dividingBy: divisor.magnitude)
        let roundsAway = switch comparedToHalf(remainder: remainder, divisor: divisor.magnitude) {
        case .lessThanHalf: false
        case .moreThanHalf: true
        case .equalToHalf: !quotient.isMultiple(of: 2)   // ties to even
        }

        guard let storage = signedRounded(quotient: quotient, roundsAway: roundsAway, sign: sign) else {
            preconditionFailure("Fixed integer division overflowed")
        }

        return Fixed(_storage: storage)
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

extension Fixed {
    // Creates a value equal to `significand × 10^exponent`. Exact when the value has at most 18 fractional
    // digits; otherwise the excess is rounded by `rounding`. `nil` when the value is out of range.
    package init?(significand: Int128, exponent: Int, rounding: RoundingRule = .toNearestOrEven) {
        let shift = exponent + Fixed.fractionalDigits   // _storage = significand × 10^shift
        let storage = shift >= 0
            ? Fixed.scaledUp(significand, byPowerOfTen: shift)
            : Fixed.scaledDown(significand, byPowerOfTen: -shift, rounding: rounding)

        guard let storage else {
            return nil
        }

        self.init(_storage: storage)
    }

    // `significand × 10^power` as raw storage, or nil if it overflows.
    private static func scaledUp(_ significand: Int128, byPowerOfTen power: Int) -> Int128? {
        guard let multiplier = Int128.powerOfTen(power) else {
            return nil
        }

        let (storage, overflow) = significand.multipliedReportingOverflow(by: multiplier)
        return overflow ? nil : storage
    }

    // `significand ÷ 10^power` as raw storage, rounding the dropped digits by `rounding`; nil on overflow.
    private static func scaledDown(
        _ significand: Int128,
        byPowerOfTen power: Int,
        rounding: RoundingRule
    ) -> Int128? {
        guard let divisor = Int128.powerOfTen(power) else {
            return nil
        }

        let sign = Sign(of: significand)
        let (quotient, remainder) = significand.magnitude.quotientAndRemainder(dividingBy: divisor.magnitude)

        guard remainder != 0 else {
            return Int128(magnitude: quotient, sign: sign)
        }

        let roundsAway = roundsAwayFromZero(
            rule: rounding,
            sign: sign,
            quotientIsEven: quotient.isMultiple(of: 2),
            comparedToHalf: comparedToHalf(remainder: remainder, divisor: divisor.magnitude)
        )
        return signedRounded(quotient: quotient, roundsAway: roundsAway, sign: sign)
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
    package init?(decimal string: some StringProtocol, rounding: RoundingRule = .toNearestOrEven) {
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
    package init?(approximating value: Double, rounding: RoundingRule = .toNearestOrEven) {
        guard value.isFinite else {
            return nil
        }

        self.init(decimal: value.plainDecimalText, rounding: rounding)
    }

    // The value as a Double, for feeding solvers. Lossy at the edge, by design.
    package var double: Double {
        Double(_storage) / Double(Fixed.scale)
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
