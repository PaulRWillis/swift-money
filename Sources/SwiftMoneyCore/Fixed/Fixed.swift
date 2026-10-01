/// A base-10 fixed-point number with up to 18 fractional digits.
///
/// The internal precision engine for fractional money — interest and FX rates, and amounts held before
/// they are rounded to whole minor units. A finite decimal within range is exact; a value needing more
/// than 18 fractional digits is rounded, half to even, at the eighteenth.
///
/// A `Fixed` is always finite — there is no NaN or infinity. Arithmetic traps on a result outside the
/// representable range (about ±1.7 × 10²⁰); the `…ReportingOverflow` and `…IfRepresentable` members
/// report the overflow instead of trapping.
// `@usableFromInline` (not `@inlinable`): the thin `MoneyOf.Unrounded` wrappers inline across the module
// boundary and call into this engine, but the heavy 256-bit bodies below stay out of line — inlining a
// full-width multiply into a caller's loop bloats it rather than helping (measured). So the type and the
// entry points the wrappers call are visible for calling, while their bodies are not emitted for inlining.
@usableFromInline
package struct Fixed: Equatable, Hashable, Sendable, BitwiseCopyable {
    // `fileprivate`, not `private`, so the same-file `Int64(exactly:)` / `Int64(_:rounding:)` can read it.
    fileprivate var _storage: Int128

    // The number of fractional digits a value is held to; `Scale` holds ten raised to that power.
    private static let fractionalDigits = 18
    private static var scale: Int128 { Scale.value }

    private init(_storage: Int128) {
        self._storage = _storage
    }

    /// The value zero.
    @usableFromInline package static let zero = Fixed(_storage: 0)
}

extension Fixed {
    /// The raw stored integer: the value times 10¹⁸.
    @usableFromInline
    package var storageBits: Int128 {
        _storage
    }

    /// Creates a value from its raw stored integer.
    ///
    /// ```swift
    /// Fixed(storageBits: 1_500_000_000_000_000_000)  // 1.5
    /// ```
    ///
    /// - Parameter storageBits: The value times 10¹⁸.
    @usableFromInline
    package init(storageBits: Int128) {
        self.init(_storage: storageBits)
    }
}

extension Fixed: Comparable {
    @usableFromInline package static func < (lhs: Fixed, rhs: Fixed) -> Bool {
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

        guard let result = bankersDivideByScale(product, sign: sign) else {
            return (.zero, true)
        }

        return (Fixed(_storage: result), false)
    }

    /// Returns this value scaled by a whole number, and whether it overflowed the representable range.
    package func multipliedReportingOverflow(by n: Int128) -> (value: Fixed, overflow: Bool) {
        let (product, overflow) = _storage.multipliedReportingOverflow(by: n)
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
    @usableFromInline package func multiplied(by n: Int128) -> Fixed {
        let (value, overflow) = multipliedReportingOverflow(by: n)
        precondition(!overflow, "Fixed integer multiplication overflowed")

        return value
    }

    /// Returns this value divided by a whole number, rounded half to even.
    @usableFromInline package func divided(by divisor: Divisor) -> Fixed {
        divided(by: divisor, rounding: .toNearestOrEven)
    }

    /// Returns this value divided by a whole number, rounded by `rounding`.
    package func divided(by divisor: Divisor, rounding: RoundingRule) -> Fixed {
        let sign = Sign(of: _storage)
        let (quotient, remainder) = _storage.magnitude.quotientAndRemainder(dividingBy: divisor.magnitude)
        let dropped = DroppedFraction(remainder: remainder, divisor: divisor.magnitude)
        let step = rounding.step(dropping: dropped, sign: sign, truncated: Parity(of: quotient))

        guard let storage = signedRounded(quotient: quotient, step: step, sign: sign) else {
            preconditionFailure("Fixed integer division overflowed")  // coverage:ignore — unreachable: a divisor of at least one can't grow the quotient
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
    @usableFromInline package func multipliedIfRepresentable(by other: Fixed) -> Fixed? {
        let (value, overflow) = multipliedReportingOverflow(by: other)
        return overflow ? nil : value
    }

    /// Returns this value scaled by a whole number, or `nil` if it overflows the representable range.
    @usableFromInline package func multipliedIfRepresentable(by n: Int128) -> Fixed? {
        let (value, overflow) = multipliedReportingOverflow(by: n)
        return overflow ? nil : value
    }
}

extension Fixed {
    // A whole number of minor units scaled by `rate`, as the unrounded product — the value
    // `Fixed(minorUnits) * rate` computes, reached without widening to `Fixed` first.
    //
    // `Fixed(minorUnits) * rate` is `(minorUnits · 10^18 · rateStorage) / 10^18 = minorUnits · rateStorage`,
    // a plain integer product. Since `minorUnits` is an `Int64`, that product fits `Int128` for every rate
    // up to about eighteen, which is every realistic one — so the common case skips the 256-bit
    // multiply-and-divide the general `Fixed * Fixed` pays. `nil` for an extreme rate, whose caller falls
    // back to the wide path.
    @usableFromInline
    static func scalingIfRepresentable(_ minorUnits: Int64, by rate: Fixed) -> Fixed? {
        let (product, overflow) = Int128(minorUnits).multipliedReportingOverflow(by: rate._storage)
        return overflow ? nil : Fixed(_storage: product)
    }
}

extension Fixed {
    /// Creates the value `significand × 10^exponent`.
    ///
    /// Exact with at most 18 fractional digits; digits beyond the eighteenth are rounded by `rounding`.
    ///
    /// - Returns: `nil` if the value is outside the representable range.
    package init?(significand: Int128, exponent: Int, rounding: RoundingRule = .toNearestOrEven) {
        guard let built = Fixed.exactness(significand: significand, exponent: exponent, rounding: rounding) else {
            return nil
        }

        self = built.value
    }

    // A value built from a significand and exponent, and whether building it rounded.
    enum Exactness: Equatable, Hashable, Sendable {
        case exact(Fixed)

        // Non-zero digits past the eighteenth were dropped.
        case rounded(Fixed)

        var value: Fixed {
            switch self {
            case let .exact(value), let .rounded(value): value
            }
        }
    }

    // `significand × 10^exponent`, and whether digits past the eighteenth had to be rounded; nil if out
    // of range.
    static func exactness(significand: Int128, exponent: Int, rounding: RoundingRule) -> Exactness? {
        let shift = exponent + Fixed.fractionalDigits   // _storage = significand × 10^shift
        guard shift < 0 else {
            return Fixed.scaledUp(significand, byPowerOfTen: shift).map { .exact(Fixed(_storage: $0)) }
        }

        return Fixed.scaledDown(significand, byPowerOfTen: -shift, rounding: rounding)
    }

    // `significand × 10^power` as raw storage, or nil if it overflows.
    private static func scaledUp(_ significand: Int128, byPowerOfTen power: Int) -> Int128? {
        // Widening a whole number shifts by exactly `fractionalDigits`, so its multiplier is the `scale`
        // constant. Reusing it skips the table read, which measured cheaper on every string parse.
        let multiplier = power == Fixed.fractionalDigits
            ? Fixed.scale
            : Int128.DecimalExponent(exactly: power).map(Int128.powerOfTen)

        guard let multiplier else {
            return nil
        }

        let (storage, overflow) = significand.multipliedReportingOverflow(by: multiplier)
        return overflow ? nil : storage
    }

    // `significand ÷ 10^power`, rounding the dropped digits by `rounding`; nil on overflow.
    private static func scaledDown(
        _ significand: Int128,
        byPowerOfTen power: Int,
        rounding: RoundingRule
    ) -> Exactness? {
        guard let exponent = Int128.DecimalExponent(exactly: power) else {
            return nil
        }

        let divisor = Int128.powerOfTen(exponent)

        let sign = Sign(of: significand)
        let (quotient, remainder) = significand.magnitude.quotientAndRemainder(dividingBy: divisor.magnitude)

        guard remainder != 0 else {
            return Int128(magnitude: quotient, sign: sign).map { .exact(Fixed(_storage: $0)) }
        }

        let dropped = DroppedFraction(remainder: remainder, divisor: divisor.magnitude)
        let step = rounding.step(dropping: dropped, sign: sign, truncated: Parity(of: quotient))
        return signedRounded(quotient: quotient, step: step, sign: sign)
            .map { .rounded(Fixed(_storage: $0)) }
    }

    /// Creates a whole value. Every `Int64` is representable.
    @usableFromInline package init(_ value: Int64) {
        // An `Int64` times 10^18 stays below `Int128.max`, so the product cannot overflow.
        self.init(_storage: Int128(value) &* Fixed.scale)
    }

    /// Creates a whole value.
    ///
    /// - Returns: `nil` if `value` is outside the representable range.
    package init?(exactly value: Int128) {
        guard let fixed = Fixed(significand: value, exponent: 0) else {
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

extension Fixed {
    // The magnitude's whole part and dropped fraction; nil when the whole part needs more than one word.
    fileprivate var wholeAndFraction: (whole: UInt64, fraction: UInt64)? {
        let magnitude = _storage.magnitude
        let high = UInt64(truncatingIfNeeded: magnitude >> 64)
        guard high < Scale.divisor else {
            return nil
        }
        let (whole, fraction) = Scale.divide(high: high, low: UInt64(truncatingIfNeeded: magnitude))
        return (whole, fraction)
    }
}

extension Int64 {
    /// The whole-number value of `fixed`, or `nil` if it has a fractional part or is outside `Int64`.
    package init?(exactly fixed: Fixed) {
        guard let (whole, fraction) = fixed.wholeAndFraction, fraction == 0 else {
            return nil
        }
        self.init(magnitude: whole, sign: Sign(of: fixed._storage))
    }

    /// `fixed` rounded to a whole number by `rounding`, or `nil` if that is outside `Int64`.
    @usableFromInline package init?(_ fixed: Fixed, rounding: RoundingRule) {
        guard let (whole, fraction) = fixed.wholeAndFraction else {
            return nil
        }
        let sign = Sign(of: fixed._storage)
        let dropped = DroppedFraction(remainder: fraction, divisor: Fixed.Scale.divisor)
        guard rounding.step(dropping: dropped, sign: sign, truncated: Parity(of: whole)) == .awayFromZero else {
            self.init(magnitude: whole, sign: sign)
            return
        }
        let (stepped, overflow) = whole.addingReportingOverflow(1)
        guard !overflow else {
            return nil
        }
        self.init(magnitude: stepped, sign: sign)
    }
}
