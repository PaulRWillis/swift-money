/// A multiplier applied to a money amount — an interest rate, a fee rate, or an exchange rate.
public struct Rate: Equatable, Hashable, Sendable {
    // Internal, not private: `MoneyOf.Unrounded` and conversions read it to scale by the rate.
    @usableFromInline let value: Fixed

    // Internal, not private: `MoneyOf.proportion(of:)` builds a rate from a computed value.
    init(_ value: Fixed) {
        self.value = value
    }
}

public extension Rate {
    /// A rate equal to `p` percent, so `Rate.percent(50)` is one half.
    ///
    /// - Precondition: `p` is within the representable range; any realistic percentage is.
    @inlinable static func percent(_ p: some BinaryInteger) -> Rate {
        guard let significand = Int128(exactly: p), let rate = Rate(percentSignificand: significand) else {
            preconditionFailure("Rate.percent(\(p)) is out of range")  // coverage:ignore — exit-test trap
        }
        return rate
    }

    /// A rate equal to `bp` basis points — one basis point is a hundredth of one percent, so
    /// `Rate.basisPoints(5000)` is one half.
    ///
    /// - Precondition: `bp` is within the representable range; any realistic rate is.
    @inlinable static func basisPoints(_ bp: some BinaryInteger) -> Rate {
        guard let significand = Int128(exactly: bp), let rate = Rate(basisPointSignificand: significand) else {
            preconditionFailure("Rate.basisPoints(\(bp)) is out of range")  // coverage:ignore — exit-test trap
        }
        return rate
    }
}

extension Rate {
    // `significand` percent, or `nil` if out of range.
    @usableFromInline init?(percentSignificand significand: Int128) {
        guard let fixed = Fixed(significand: significand, exponent: -Rate.percentFractionDigits) else {
            return nil
        }
        self.init(fixed)
    }

    // `significand` basis points, or `nil` if out of range.
    @usableFromInline init?(basisPointSignificand significand: Int128) {
        guard let fixed = Fixed(significand: significand, exponent: -Rate.basisPointFractionDigits) else {
            return nil
        }
        self.init(fixed)
    }
}

public extension Rate {
    /// The rate written as `text`: a decimal (`"0.175"`), a percentage (`"17.5%"`), or a fraction
    /// (`"1/3"`). A value finer than the type can hold is rounded by `rounding`.
    ///
    /// - Returns: `nil` if `text` is none of those forms, or names a value too large to represent.
    init?(string text: String, rounding: RoundingRule = .toNearestOrEven) {
        guard let parsed = Rate.parse(text, rounding: rounding) else {
            return nil
        }
        self.init(parsed.value)
    }

    /// The rate closest to `value`.
    ///
    /// A `Double` carries only about fifteen significant digits, so that is the ceiling — the result
    /// is exact to the `Double`, not to the number it approximates. Digits finer than the type keeps
    /// are rounded by `rounding`.
    ///
    /// - Returns: `nil` if `value` is not finite, or is too large to represent.
    init?(approximating value: Double, rounding: RoundingRule = .toNearestOrEven) {
        guard let fixed = Fixed(approximating: value, rounding: rounding) else {
            return nil
        }
        self.init(fixed)
    }
}

extension Rate: ExpressibleByStringLiteral {
    /// Builds the rate from a string literal.
    ///
    /// A literal is written by the programmer, so silent rounding would hide a mistake: the literal
    /// accepts only an exactly-representable value. `"0.175"`, `"1/4"`, and `"5%"` are fine.
    ///
    /// - Precondition: `value` is a valid rate the type can hold exactly. `"1/3"`, or anything finer
    ///   than the grid, traps — use ``init(string:rounding:)`` to round instead.
    public init(stringLiteral value: String) {
        switch Rate.parse(value, rounding: .toNearestOrEven) {
        case let .exact(fixed):
            self.init(fixed)
        case .rounded:
            preconditionFailure("Rate literal \"\(value)\" is not exactly representable; use Rate(string:rounding:)")  // coverage:ignore — exit-test trap
        case nil:
            preconditionFailure("Not a valid rate literal: \"\(value)\"")  // coverage:ignore — exit-test trap
        }
    }
}

public extension Rate {
    /// The rate as a whole number of basis points, or `nil` if it is not a whole number of them.
    ///
    /// One basis point is a hundredth of one percent. `nil` when the rate falls between two basis
    /// points — half a basis point, say — so a lossy read is never silent.
    var wholeBasisPoints: Int? {
        guard let scaled = value.multipliedIfRepresentable(by: Self.basisPointsPerWhole),
              let whole = Int64(exactly: scaled) else {
            return nil
        }
        return Int(exactly: whole)
    }

    /// The rate in basis points, rounded to a whole number by `rounding`.
    ///
    /// - Precondition: the rate is small enough to count in `Int` basis points; any real rate is.
    func basisPoints(rounding: RoundingRule) -> Int {
        let scaled = value.multiplied(by: Self.basisPointsPerWhole)
        guard let whole = Int64(scaled, rounding: rounding), let result = Int(exactly: whole) else {
            preconditionFailure("Rate is too large to express as Int basis points")  // coverage:ignore — exit-test trap
        }
        return result
    }
}

private extension Rate {
    // Parses the three written forms, reporting whether `text` named the value exactly (no rounding).
    // Returns nil for anything that is not a decimal, a percentage, or a fraction.
    static func parse(_ text: String, rounding: RoundingRule) -> Fixed.Exactness? {
        let slash = UInt8(ascii: "/")

        if text.utf8.last == UInt8(ascii: "%") {
            guard !text.utf8.contains(slash) else { return nil }
            return parsePercent(text.dropLast(), rounding: rounding)
        }

        // Count slashes by scanning, rather than building a filtered array to count: none is a decimal,
        // one a fraction, more is neither.
        var slashes = 0
        for byte in text.utf8 where byte == slash {
            slashes += 1
            guard slashes <= 1 else { return nil }
        }

        switch slashes {
        case 0: return parseDecimal(text[...], rounding: rounding)
        default: return parseFraction(text[...], rounding: rounding)
        }
    }

    // "0.175" → the decimal itself.
    static func parseDecimal(_ text: Substring, rounding: RoundingRule) -> Fixed.Exactness? {
        guard let (significand, fractionDigits) = scanDecimal(text) else { return nil }
        return Fixed.exactness(significand: significand, exponent: -fractionDigits, rounding: rounding)
    }

    // "17.5%" → the decimal divided by a hundred: two more places past the point.
    static func parsePercent(_ text: Substring, rounding: RoundingRule) -> Fixed.Exactness? {
        guard let (significand, fractionDigits) = scanDecimal(text) else { return nil }
        return Fixed.exactness(significand: significand, exponent: -(fractionDigits + percentFractionDigits), rounding: rounding)
    }

    // "1/3" → numerator over denominator, exact only when the division leaves nothing over.
    static func parseFraction(_ text: Substring, rounding: RoundingRule) -> Fixed.Exactness? {
        // Slice at the single slash rather than `split`, which would allocate an array for two parts.
        guard let slash = text.firstIndex(of: "/") else { return nil }
        let numeratorText = text[text.startIndex ..< slash]
        let denominatorText = text[text.index(after: slash)...]

        guard let numerator = Int128(numeratorText),
              let denominator = Int128(denominatorText), denominator > 0,
              let whole = Fixed(exactly: numerator) else {
            return nil
        }
        let value = whole.divided(by: denominator, rounding: rounding)
        guard value.multipliedIfRepresentable(by: denominator) == whole else {
            return .rounded(value)
        }

        return .exact(value)
    }

    // Scans a signed decimal ("-0.175", ".5", "100") into a significand and its fraction-digit count.
    static func scanDecimal(_ text: Substring) -> (significand: Int128, fractionDigits: Int)? {
        let zero = UInt8(ascii: "0"), nine = UInt8(ascii: "9")
        var sign = Sign.positive
        var magnitude: UInt128 = 0
        var fractionDigits = 0
        var sawPoint = false
        var sawDigit = false
        var isFirst = true

        for byte in text.utf8 {
            if isFirst {
                isFirst = false
                if byte == UInt8(ascii: "-") { sign = .negative; continue }
                if byte == UInt8(ascii: "+") { continue }
            }
            if byte == UInt8(ascii: ".") {
                guard !sawPoint else { return nil }
                sawPoint = true
                continue
            }
            guard (zero ... nine).contains(byte) else { return nil }
            let (shifted, tooBig) = magnitude.multipliedReportingOverflow(by: 10)
            let (grown, carry) = shifted.addingReportingOverflow(UInt128(byte - zero))
            guard !tooBig, !carry else { return nil }
            magnitude = grown
            sawDigit = true
            if sawPoint { fractionDigits += 1 }
        }

        guard sawDigit, let significand = Int128(magnitude: magnitude, sign: sign) else { return nil }
        return (significand, fractionDigits)
    }
}

private extension Rate {
    static let percentFractionDigits = 2       // percent = value / 10²
    static let basisPointFractionDigits = 4    // basis points = value / 10⁴
    static let basisPointsPerWhole: Int128 = 10_000    // basis points in 1 = 10⁴
}
