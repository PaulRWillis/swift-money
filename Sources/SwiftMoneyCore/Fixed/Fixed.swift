/// A base-10 fixed-point number with up to 18 fractional digits.
///
/// The internal precision engine for fractional money — interest and FX rates, and amounts held before
/// they are rounded to whole minor units. A finite decimal within range is exact; a value needing more
/// than 18 fractional digits is rounded, half to even, at the eighteenth.
///
/// A `Fixed` is always finite — there is no NaN or infinity. Arithmetic traps on a result outside the
/// representable range (about ±1.7 × 10²⁰); the `…ReportingOverflow` and `…IfRepresentable` members
/// report the overflow instead of trapping.
package struct Fixed: Equatable, Hashable, Sendable, BitwiseCopyable {
    // `fileprivate`, not `private`, so the same-file `Int128(exactly:)` / `Int128(_:rounding:)` can read it.
    fileprivate var _storage: Int128

    // The number of fractional digits a value is held to, and ten raised to that power.
    private static let fractionalDigits = 18
    fileprivate static let scale: Int128 = 1_000_000_000_000_000_000

    private init(_storage: Int128) {
        self._storage = _storage
    }

    /// The value zero.
    package static let zero = Fixed(_storage: 0)
}

extension Fixed: Comparable {
    package static func < (lhs: Fixed, rhs: Fixed) -> Bool {
        lhs._storage < rhs._storage
    }
}

extension Fixed {
    /// Returns the sum of the two values, and whether it overflowed the representable range.
    package func addingReportingOverflow(_ other: Fixed) -> (value: Fixed, overflow: Bool) {
        let (sum, overflow) = _storage.addingReportingOverflow(other._storage)
        return (Fixed(_storage: sum), overflow)
    }

    /// Returns the difference of the two values, and whether it overflowed the representable range.
    package func subtractingReportingOverflow(_ other: Fixed) -> (value: Fixed, overflow: Bool) {
        let (difference, overflow) = _storage.subtractingReportingOverflow(other._storage)
        return (Fixed(_storage: difference), overflow)
    }

    /// Returns the product of the two values, and whether it overflowed. The value is meaningless when
    /// `overflow` is `true`.
    package func multipliedReportingOverflow(by other: Fixed) -> (value: Fixed, overflow: Bool) {
        let sign = Sign(of: _storage) * Sign(of: other._storage)
        let product = Wide256Magnitude(_storage.magnitude, times: other._storage.magnitude)

        guard let result = bankersDivide256(product, by: UInt128(Fixed.scale), sign: sign) else {
            return (.zero, true)
        }

        return (Fixed(_storage: result), false)
    }

    /// Returns this value scaled by a whole number, and whether it overflowed the representable range.
    package func multipliedReportingOverflow(by n: some BinaryInteger) -> (value: Fixed, overflow: Bool) {
        guard let factor = Int128(exactly: n) else {
            return (.zero, true)
        }
        let (product, overflow) = _storage.multipliedReportingOverflow(by: factor)
        return (Fixed(_storage: product), overflow)
    }
}

extension Fixed {
    /// Returns the sum of the two values.
    ///
    /// - Precondition: the result is representable. Use ``addingReportingOverflow(_:)`` or
    ///   ``addingIfRepresentable(_:)`` for values that may overflow.
    package static func + (lhs: Fixed, rhs: Fixed) -> Fixed {
        let (value, overflow) = lhs.addingReportingOverflow(rhs)
        precondition(!overflow, "Fixed addition overflowed")

        return value
    }

    /// Returns the difference of the two values.
    ///
    /// - Precondition: the result is representable. Use ``subtractingIfRepresentable(_:)`` otherwise.
    package static func - (lhs: Fixed, rhs: Fixed) -> Fixed {
        let (value, overflow) = lhs.subtractingReportingOverflow(rhs)
        precondition(!overflow, "Fixed subtraction overflowed")

        return value
    }

    /// Returns the product of the two values.
    ///
    /// - Precondition: the result is representable. Use ``multipliedIfRepresentable(by:)`` otherwise.
    package static func * (lhs: Fixed, rhs: Fixed) -> Fixed {
        let (value, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow, "Fixed multiplication overflowed")

        return value
    }

    /// Returns the quotient of the two values, rounded half to even.
    ///
    /// - Precondition: `rhs` is not zero and the result is representable.
    package static func / (lhs: Fixed, rhs: Fixed) -> Fixed {
        precondition(rhs._storage != 0, "Fixed divided by zero")

        let sign = Sign(of: lhs._storage) * Sign(of: rhs._storage)
        let numerator = Wide256Magnitude(lhs._storage.magnitude, times: UInt128(Fixed.scale))

        guard let storage = bankersDivide256(numerator, by: rhs._storage.magnitude, sign: sign) else {
            preconditionFailure("Fixed division overflowed")  // coverage:ignore — exit-test trap
        }

        return Fixed(_storage: storage)
    }

    /// Returns this value scaled by a whole number.
    ///
    /// - Precondition: the result is representable. Use ``multipliedIfRepresentable(by:)`` otherwise.
    package func multiplied(by n: some BinaryInteger) -> Fixed {
        let (value, overflow) = multipliedReportingOverflow(by: n)
        precondition(!overflow, "Fixed integer multiplication overflowed")

        return value
    }

    /// Returns this value divided by a whole number, rounded half to even.
    ///
    /// - Precondition: `n` is not zero and the result is representable.
    package func divided(by n: some BinaryInteger) -> Fixed {
        divided(by: n, rounding: .toNearestOrEven)
    }

    /// Returns this value divided by a whole number, rounded by `rounding`.
    ///
    /// - Precondition: `n` is not zero and the result is representable.
    package func divided(by n: some BinaryInteger, rounding: RoundingRule) -> Fixed {
        let divisor = Int128(n)
        precondition(divisor != 0, "Fixed divided by zero")

        let sign = Sign(of: _storage) * Sign(of: divisor)
        let (quotient, remainder) = _storage.magnitude.quotientAndRemainder(dividingBy: divisor.magnitude)
        let roundsAway = remainder != 0 && roundsAwayFromZero(
            rule: rounding,
            sign: sign,
            quotientIsEven: quotient.isMultiple(of: 2),
            comparedToHalf: comparedToHalf(remainder: remainder, divisor: divisor.magnitude)
        )

        guard let storage = signedRounded(quotient: quotient, roundsAway: roundsAway, sign: sign) else {
            preconditionFailure("Fixed integer division overflowed")  // coverage:ignore — exit-test trap
        }

        return Fixed(_storage: storage)
    }
}

extension Fixed {
    /// Returns the sum of the two values, or `nil` if it overflows the representable range.
    package func addingIfRepresentable(_ other: Fixed) -> Fixed? {
        let (value, overflow) = addingReportingOverflow(other)
        return overflow ? nil : value
    }

    /// Returns the difference of the two values, or `nil` if it overflows the representable range.
    package func subtractingIfRepresentable(_ other: Fixed) -> Fixed? {
        let (value, overflow) = subtractingReportingOverflow(other)
        return overflow ? nil : value
    }

    /// Returns the product of the two values, or `nil` if it overflows the representable range.
    package func multipliedIfRepresentable(by other: Fixed) -> Fixed? {
        let (value, overflow) = multipliedReportingOverflow(by: other)
        return overflow ? nil : value
    }

    /// Returns this value scaled by a whole number, or `nil` if it overflows the representable range.
    package func multipliedIfRepresentable(by n: some BinaryInteger) -> Fixed? {
        let (value, overflow) = multipliedReportingOverflow(by: n)
        return overflow ? nil : value
    }
}

extension Fixed {
    /// Creates the value `significand × 10^exponent`.
    ///
    /// Exact with at most 18 fractional digits; digits beyond the eighteenth are rounded by `rounding`.
    ///
    /// - Returns: `nil` if the value is outside the representable range.
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
        // Widening a whole number shifts by exactly `fractionalDigits`, so its multiplier is the `scale`
        // constant. Reusing it keeps the common `Fixed(someInteger)` off the `powerOfTen` loop, which
        // every `.unrounded` would otherwise pay eighteen iterations for.
        let multiplier = power == Fixed.fractionalDigits ? Fixed.scale : Int128.powerOfTen(power)

        guard let multiplier else {
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

    /// Creates a whole value.
    ///
    /// - Precondition: `value` is within the representable range. Use ``init(exactly:)`` otherwise.
    package init(_ value: some BinaryInteger) {
        guard let fixed = Fixed(significand: Int128(value), exponent: 0) else {
            preconditionFailure("Value is out of range for Fixed")  // coverage:ignore — exit-test trap
        }

        self = fixed
    }

    /// Creates a whole value.
    ///
    /// - Returns: `nil` if `value` is outside the representable range.
    package init?(exactly value: some BinaryInteger) {
        guard let significand = Int128(exactly: value),
              let fixed = Fixed(significand: significand, exponent: 0) else {
            return nil
        }

        self = fixed
    }

    /// Creates a value from a decimal string such as `"0.175"`, `"-0.05"` or `"100"`.
    ///
    /// Exact with at most 18 fractional digits; digits beyond the eighteenth are rounded by `rounding`.
    ///
    /// - Returns: `nil` if the string is not a plain decimal number — a fraction such as `"1/3"`,
    ///   exponent notation, more than one point, or any non-digit — or if the value is out of range.
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

    /// Creates the value closest to `value`.
    ///
    /// A `Double` carries only about 15–16 significant digits, so that precision is the ceiling — the
    /// result is exact to the `Double`, not to the number the `Double` approximates.
    ///
    /// - Returns: `nil` if `value` is not finite, or is outside the representable range.
    package init?(approximating value: Double, rounding: RoundingRule = .toNearestOrEven) {
        guard value.isFinite else {
            return nil
        }

        self.init(decimal: value.plainDecimalText, rounding: rounding)
    }

    /// The value as the nearest `Double`. Lossy for large or fine values.
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
            return nil   // coverage:ignore — unreachable: the ×10 above overflows first on any input that reaches this
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

extension Int128 {
    /// The whole-number value of `fixed`, or `nil` if it has a fractional part.
    package init?(exactly fixed: Fixed) {
        let (quotient, remainder) = fixed._storage.quotientAndRemainder(dividingBy: Fixed.scale)
        guard remainder == 0 else {
            return nil
        }
        self = quotient
    }

    /// `fixed` rounded to a whole number by `rounding`.
    package init(_ fixed: Fixed, rounding: RoundingRule) {
        let (quotient, remainder) = fixed._storage.quotientAndRemainder(dividingBy: Fixed.scale)
        let sign = Sign(of: fixed._storage)
        let roundsAway = remainder != 0 && roundsAwayFromZero(
            rule: rounding,
            sign: sign,
            quotientIsEven: quotient.isMultiple(of: 2),
            comparedToHalf: comparedToHalf(remainder: remainder.magnitude, divisor: Fixed.scale.magnitude)
        )
        self = roundsAway ? quotient + (sign == .negative ? -1 : 1) : quotient
    }
}
