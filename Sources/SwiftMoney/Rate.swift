/// A multiplier applied to a money amount — an interest rate, a fee rate, or an exchange rate.
public struct Rate: Equatable, Hashable, Sendable {
    // Internal, not private: `MoneyOf.Unrounded` and conversions read it to scale by the rate.
    let value: Fixed

    // Internal, not private: `MoneyOf.proportion(of:)` builds a rate from a computed value.
    init(_ value: Fixed) {
        self.value = value
    }
}

public extension Rate {
    /// A rate equal to `p` percent, so `Rate.percent(50)` is one half.
    ///
    /// - Precondition: `p` is within the representable range; any realistic percentage is.
    static func percent(_ p: some BinaryInteger) -> Rate {
        guard let significand = Int128(exactly: p),
              let fixed = Fixed(significand: significand, exponent: -percentFractionDigits) else {
            preconditionFailure("Rate.percent(\(p)) is out of range")  // coverage:ignore — exit-test trap
        }
        return Rate(fixed)
    }

    /// A rate equal to `bp` basis points — one basis point is a hundredth of one percent, so
    /// `Rate.basisPoints(5000)` is one half.
    ///
    /// - Precondition: `bp` is within the representable range; any realistic rate is.
    static func basisPoints(_ bp: some BinaryInteger) -> Rate {
        guard let significand = Int128(exactly: bp),
              let fixed = Fixed(significand: significand, exponent: -basisPointFractionDigits) else {
            preconditionFailure("Rate.basisPoints(\(bp)) is out of range")  // coverage:ignore — exit-test trap
        }
        return Rate(fixed)
    }
}

public extension Rate {
    /// The rate written as `text`: a decimal (`"0.175"`), a percentage (`"17.5%"`), or a fraction
    /// (`"1/3"`). A value finer than the type can hold is rounded by `rounding`.
    ///
    /// - Returns: `nil` if `text` is none of those forms, or names a value too large to represent.
    init?(string text: String, rounding: RoundingRule = .toNearestOrEven) {
        guard let (value, _) = Rate.parse(text, rounding: rounding) else {
            return nil
        }
        self.init(value)
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
        guard let (fixed, exact) = Rate.parse(value, rounding: .toNearestOrEven) else {
            preconditionFailure("Not a valid rate literal: \"\(value)\"")  // coverage:ignore — exit-test trap
        }
        guard exact else {
            preconditionFailure("Rate literal \"\(value)\" is not exactly representable; use Rate(string:rounding:)")  // coverage:ignore — exit-test trap
        }
        self.init(fixed)
    }
}

public extension Rate {
    /// The rate as a whole number of basis points, or `nil` if it is not a whole number of them.
    ///
    /// One basis point is a hundredth of one percent. `nil` when the rate falls between two basis
    /// points — half a basis point, say — so a lossy read is never silent.
    var wholeBasisPoints: Int? {
        guard let scaled = value.multipliedIfRepresentable(by: Self.basisPointsPerWhole),
              let whole = Int128(exactly: scaled) else {
            return nil
        }
        return Int(exactly: whole)
    }

    /// The rate in basis points, rounded to a whole number by `rounding`.
    ///
    /// - Precondition: the rate is small enough to count in `Int` basis points; any real rate is.
    func basisPoints(rounding: RoundingRule) -> Int {
        let scaled = value.multiplied(by: Self.basisPointsPerWhole)
        guard let result = Int(exactly: Int128(scaled, rounding: rounding)) else {
            preconditionFailure("Rate is too large to express as Int basis points")  // coverage:ignore — exit-test trap
        }
        return result
    }
}

private extension Rate {
    // Parses the three written forms, reporting whether `text` named the value exactly (no rounding).
    // Returns nil for anything that is not a decimal, a percentage, or a fraction.
    static func parse(_ text: String, rounding: RoundingRule) -> (value: Fixed, exact: Bool)? {
        let slash = UInt8(ascii: "/")

        if text.utf8.last == UInt8(ascii: "%") {
            guard !text.utf8.contains(slash) else { return nil }
            return parsePercent(text.dropLast(), rounding: rounding)
        }

        switch text.utf8.filter({ $0 == slash }).count {
        case 0: return parseDecimal(text[...], rounding: rounding)
        case 1: return parseFraction(text[...], rounding: rounding)
        default: return nil
        }
    }

    // "0.175" → the decimal itself.
    static func parseDecimal(_ text: Substring, rounding: RoundingRule) -> (value: Fixed, exact: Bool)? {
        guard let (significand, fractionDigits) = scanDecimal(text) else { return nil }
        return representable(significand: significand, exponent: -fractionDigits, rounding: rounding)
    }

    // "17.5%" → the decimal divided by a hundred: two more places past the point.
    static func parsePercent(_ text: Substring, rounding: RoundingRule) -> (value: Fixed, exact: Bool)? {
        guard let (significand, fractionDigits) = scanDecimal(text) else { return nil }
        return representable(significand: significand, exponent: -(fractionDigits + percentFractionDigits), rounding: rounding)
    }

    // "1/3" → numerator over denominator, exact only when the division leaves nothing over.
    static func parseFraction(_ text: Substring, rounding: RoundingRule) -> (value: Fixed, exact: Bool)? {
        let parts = text.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let numerator = Int128(parts[0]),
              let denominator = Int128(parts[1]), denominator > 0,
              let whole = Fixed(exactly: numerator) else {
            return nil
        }
        let value = whole.divided(by: denominator, rounding: rounding)
        return (value, exact: value.multipliedIfRepresentable(by: denominator) == whole)
    }

    // Builds `significand × 10^exponent`, reporting whether it lands on the grid without rounding.
    static func representable(significand: Int128, exponent: Int, rounding: RoundingRule) -> (value: Fixed, exact: Bool)? {
        guard let value = Fixed(significand: significand, exponent: exponent, rounding: rounding) else { return nil }
        let truncated = Fixed(significand: significand, exponent: exponent, rounding: .towardZero)
        let raised = Fixed(significand: significand, exponent: exponent, rounding: .awayFromZero)
        return (value, exact: truncated == raised)
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
    static let basisPointsPerWhole = 10_000    // basis points in 1 = 10⁴
}
