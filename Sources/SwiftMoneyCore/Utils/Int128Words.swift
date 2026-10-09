/// A 128-bit signed integer held as two 64-bit words, in two's complement.
///
/// Its arithmetic matches the standard library's `Int128`: the `…ReportingOverflow` members wrap
/// and report the overflow, and the operators trap where `Int128`'s do.
///
/// ```swift
/// let smallest: Int128Words = -170_141_183_460_469_231_731_687_303_715_884_105_728
/// smallest == .min      // true
/// smallest.magnitude    // 2^127
/// ```
@usableFromInline
package struct Int128Words: Hashable, Sendable, BitwiseCopyable {
    /// The value's two's-complement bits.
    @usableFromInline let _storage: UInt128Words

    /// Creates a value with the same bits as an unsigned one.
    ///
    /// ```swift
    /// Int128Words(bitPattern: .max)   // -1
    /// ```
    ///
    /// - Parameter bitPattern: The two's-complement bits of the value.
    @inlinable
    package init(bitPattern: UInt128Words) {
        _storage = bitPattern
    }

    /// Creates a value from a 64-bit one.
    ///
    /// ```swift
    /// Int128Words(Int64.min)   // -9_223_372_036_854_775_808
    /// ```
    ///
    /// - Parameter value: The value to widen.
    @inlinable
    package init(_ value: Int64) {
        self.init(bitPattern: UInt128Words(high: UInt64(bitPattern: value >> 63), low: UInt64(bitPattern: value)))
    }

    /// Creates a value from any integer, or `nil` if it is outside `-2^127...2^127 - 1`.
    ///
    /// ```swift
    /// Int128Words(exactly: UInt64.max)   // 18_446_744_073_709_551_615
    /// Int128Words(exactly: UInt128.max)  // nil
    /// ```
    ///
    /// - Parameter source: The integer to convert.
    /// - Returns: The same value, or `nil` if it doesn't fit.
    @inlinable
    package init?(exactly source: some BinaryInteger) {
        // The bits above the lower word fit the upper word exactly when the whole value fits.
        guard let high = Int64(exactly: source >> 64) else {
            return nil
        }

        self.init(bitPattern: UInt128Words(high: UInt64(bitPattern: high), low: UInt64(truncatingIfNeeded: source)))
    }

    /// The largest value, `2^127 - 1`.
    package static var max: Int128Words {
        Int128Words(bitPattern: UInt128Words(high: UInt64(Int64.max), low: .max))
    }

    /// The smallest value, `-2^127`.
    package static var min: Int128Words {
        Int128Words(bitPattern: UInt128Words(high: 1 << 63, low: 0))
    }
}

extension Int128Words: ExpressibleByIntegerLiteral {
    /// Creates a value from an integer literal.
    ///
    /// ```swift
    /// let minusOne: Int128Words = -1
    /// ```
    ///
    /// - Parameter value: The literal.
    /// - Precondition: `value` must be in `-2^127...2^127 - 1`.
    @inlinable
    package init(integerLiteral value: StaticBigInt) {
        precondition(value.bitWidth <= 128, "Integer literal overflows Int128Words")

        self.init(bitPattern: UInt128Words(wordsOf: value))
    }
}

extension UInt128Words {
    /// Creates a value with the same bits as a signed one.
    ///
    /// ```swift
    /// UInt128Words(bitPattern: -1)   // UInt128Words.max
    /// ```
    ///
    /// - Parameter bitPattern: The signed value whose two's-complement bits to take.
    @inlinable
    package init(bitPattern: Int128Words) {
        self = bitPattern._storage
    }
}

extension Int128Words: Comparable {
    /// Returns whether the first value is less than the second.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: `true` if `lhs` is less than `rhs`; otherwise, `false`.
    @usableFromInline
    package static func < (lhs: Int128Words, rhs: Int128Words) -> Bool {
        (Int64(bitPattern: lhs._storage.high), lhs._storage.low) < (Int64(bitPattern: rhs._storage.high), rhs._storage.low)
    }
}

extension Int128Words {
    /// The absolute value, unsigned so that the smallest value's, `2^127`, is representable.
    ///
    /// ```swift
    /// Int128Words(-5).magnitude   // 5
    /// ```
    package var magnitude: UInt128Words {
        Sign(of: self) == .negative ? _storage.negatedWrapping : _storage
    }

    /// Creates a value from its magnitude and sign, or `nil` if it is outside `-2^127...2^127 - 1`.
    ///
    /// ```swift
    /// Int128Words(magnitude: 5, sign: .negative)              // -5
    /// Int128Words(magnitude: Int128Words.min.magnitude, sign: .positive)   // nil
    /// ```
    ///
    /// - Parameters:
    ///   - magnitude: The absolute value.
    ///   - sign: Which side of zero the value falls on.
    /// - Returns: The signed value, or `nil` if it doesn't fit.
    package init?(magnitude: UInt128Words, sign: Sign) {
        let (value, overflow) = Int128Words.signed(magnitude, sign: sign)
        guard !overflow else {
            return nil
        }

        self = value
    }

    /// Returns the lower 128 bits of a magnitude with a sign applied, and whether the signed value
    /// falls outside the range.
    ///
    /// - Parameters:
    ///   - magnitude: The absolute value, wrapped to 128 bits.
    ///   - sign: Which side of zero the value falls on.
    /// - Returns: The signed bits, and `true` if the signed value doesn't fit.
    private static func signed(_ magnitude: UInt128Words, sign: Sign) -> (partialValue: Int128Words, overflow: Bool) {
        switch sign {
        case .positive:
            return (Int128Words(bitPattern: magnitude), magnitude > Int128Words.max.magnitude)
        case .negative:
            return (Int128Words(bitPattern: magnitude.negatedWrapping), magnitude > Int128Words.min.magnitude)
        }
    }
}

private extension UInt128Words {
    /// The two's-complement negation, wrapped to 128 bits.
    var negatedWrapping: UInt128Words {
        UInt128Words.min.subtractingReportingOverflow(self).partialValue
    }
}

extension Int128Words {
    /// Returns the sum of this value and another, and whether it overflowed.
    ///
    /// ```swift
    /// Int128Words.max.addingReportingOverflow(1)   // (Int128Words.min, true)
    /// ```
    ///
    /// - Parameter other: The value to add.
    /// - Returns: The sum, wrapped to 128 bits, and `true` if it overflowed.
    @inlinable @inline(__always)
    package func addingReportingOverflow(_ other: Int128Words) -> (partialValue: Int128Words, overflow: Bool) {
        // The two's-complement sum is the unsigned one modulo 2^128, so the upper words wrap freely.
        let (low, carry) = _storage.low.addingReportingOverflow(other._storage.low)
        let high = _storage.high &+ other._storage.high &+ (carry ? 1 : 0)

        let sum = Int128Words(bitPattern: UInt128Words(high: high, low: low))

        // A sum overflows exactly when both operands share a sign the wrapped sum doesn't.
        let sign = Sign(of: self)
        return (sum, sign == Sign(of: other) && Sign(of: sum) != sign)
    }

    /// Returns the difference of this value and another, and whether it overflowed.
    ///
    /// ```swift
    /// Int128Words.min.subtractingReportingOverflow(1)   // (Int128Words.max, true)
    /// ```
    ///
    /// - Parameter other: The value to subtract.
    /// - Returns: The difference, wrapped to 128 bits, and `true` if it overflowed.
    @inlinable @inline(__always)
    package func subtractingReportingOverflow(_ other: Int128Words) -> (partialValue: Int128Words, overflow: Bool) {
        // The two's-complement difference is the unsigned one modulo 2^128, so the upper words wrap
        // freely.
        let (low, borrow) = _storage.low.subtractingReportingOverflow(other._storage.low)
        let high = _storage.high &- other._storage.high &- (borrow ? 1 : 0)

        let difference = Int128Words(bitPattern: UInt128Words(high: high, low: low))

        // A difference overflows exactly when the operands' signs differ and the wrapped difference
        // takes the subtrahend's.
        let sign = Sign(of: self)
        return (difference, sign != Sign(of: other) && Sign(of: difference) != sign)
    }

    /// Returns the product of this value and another, and whether it overflowed.
    ///
    /// ```swift
    /// Int128Words.min.multipliedReportingOverflow(by: -1)   // (Int128Words.min, true)
    /// ```
    ///
    /// - Parameter other: The value to multiply by.
    /// - Returns: The product, wrapped to 128 bits, and `true` if it overflowed.
    @inline(__always)
    package func multipliedReportingOverflow(by other: Int128Words) -> (partialValue: Int128Words, overflow: Bool) {
        guard let factor = Int64(exactly: other) else {
            return multipliedWideReportingOverflow(by: other)
        }
        guard let narrow = Int64(exactly: self) else {
            return multipliedReportingOverflow(byInt64: factor)
        }

        // Both factors are within `-2^63...2^63 - 1`, so the product's magnitude is at most 2^126
        // and fits.
        let (high, low) = narrow.multipliedFullWidth(by: factor)
        return (Int128Words(bitPattern: UInt128Words(high: UInt64(bitPattern: high), low: low)), false)
    }

    /// Returns the product of this value and another outside `Int64`, and whether it overflowed.
    ///
    /// - Parameter other: The value to multiply by, outside `Int64`.
    /// - Returns: The product, wrapped to 128 bits, and `true` if it overflowed.
    private func multipliedWideReportingOverflow(by other: Int128Words) -> (partialValue: Int128Words, overflow: Bool) {
        if let factor = Int64(exactly: self) {
            return other.multipliedReportingOverflow(byInt64: factor)
        }

        let (product, overflow) = magnitude.multipliedReportingOverflow(by: other.magnitude)
        let (value, outOfRange) = Int128Words.signed(product, sign: Sign(of: self) * Sign(of: other))

        return (value, overflow || outOfRange)
    }

    /// Returns the product of this value and a 64-bit factor, and whether it overflowed.
    ///
    /// The same result as widening `factor` first, with half the word products.
    ///
    /// ```swift
    /// let twoToThe64 = Int128Words(bitPattern: UInt128Words(high: 1, low: 0))
    /// twoToThe64.multipliedReportingOverflow(byInt64: .min)   // (Int128Words.min, false)
    /// ```
    ///
    /// - Parameter factor: The value to multiply by.
    /// - Returns: The product, wrapped to 128 bits, and `true` if it overflowed.
    @usableFromInline
    package func multipliedReportingOverflow(byInt64 factor: Int64) -> (partialValue: Int128Words, overflow: Bool) {
        // With `self = high · 2^64 + low`, the product is `high · factor · 2^64 + low · factor`. The
        // unsigned `low` times a negative `factor` is its product with the factor's bits, less
        // `low · 2^64`.
        let (lowCarry, productLow) = _storage.low.multipliedFullWidth(by: UInt64(bitPattern: factor))
        let (crossHigh, crossLow) = Int64(bitPattern: _storage.high).multipliedFullWidth(by: factor)
        let correction = factor < 0 ? _storage.low : 0

        // The product is `(top · 2^64 + middle) · 2^64 + productLow`, which fits exactly when
        // `top · 2^64 + middle` fits one signed word. `crossHigh` is within `±2^62`, so adding the
        // carry and taking the borrow can't wrap.
        let (sum, carry) = crossLow.addingReportingOverflow(lowCarry)
        let (middle, borrow) = sum.subtractingReportingOverflow(correction)
        let top = crossHigh &+ (carry ? 1 : 0) &- (borrow ? 1 : 0)

        let product = Int128Words(bitPattern: UInt128Words(high: middle, low: productLow))
        return (product, top != Int64(bitPattern: middle) >> 63)
    }
}

extension Int128Words {
    /// Returns the sum of two values.
    ///
    /// ```swift
    /// Int128Words(-1) + 1   // 0
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    /// - Returns: The sum of `lhs` and `rhs`.
    /// - Precondition: The sum must be in `-2^127...2^127 - 1`.
    package static func + (lhs: Int128Words, rhs: Int128Words) -> Int128Words {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        precondition(!overflow, "Int128Words addition overflowed")

        return sum
    }

    /// Returns the difference of two values.
    ///
    /// ```swift
    /// Int128Words(-1) - 1   // -2
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The minuend.
    ///   - rhs: The subtrahend.
    /// - Returns: The difference of `lhs` and `rhs`.
    /// - Precondition: The difference must be in `-2^127...2^127 - 1`.
    package static func - (lhs: Int128Words, rhs: Int128Words) -> Int128Words {
        let (difference, overflow) = lhs.subtractingReportingOverflow(rhs)
        precondition(!overflow, "Int128Words subtraction overflowed")

        return difference
    }

    /// Returns the product of two values.
    ///
    /// ```swift
    /// Int128Words(-3) * 4   // -12
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The multiplicand.
    ///   - rhs: The multiplier.
    /// - Returns: The product of `lhs` and `rhs`.
    /// - Precondition: The product must be in `-2^127...2^127 - 1`.
    package static func * (lhs: Int128Words, rhs: Int128Words) -> Int128Words {
        let (product, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow, "Int128Words multiplication overflowed")

        return product
    }

    /// Multiplies two values and stores the product in the first.
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to multiply by.
    /// - Precondition: The product must be in `-2^127...2^127 - 1`.
    package static func *= (lhs: inout Int128Words, rhs: Int128Words) {
        lhs = lhs * rhs
    }

    /// Returns the quotient of two values, truncated toward zero.
    ///
    /// ```swift
    /// Int128Words(-7) / 2   // -3
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The dividend.
    ///   - rhs: The divisor.
    /// - Returns: The quotient of `lhs` and `rhs`.
    /// - Precondition: `rhs` must not be zero.
    /// - Precondition: The quotient must be in `-2^127...2^127 - 1`, which rules out `min / -1`.
    package static func / (lhs: Int128Words, rhs: Int128Words) -> Int128Words {
        precondition(rhs != 0, "Int128Words division by zero")

        let quotient = lhs.magnitude.quotientAndRemainder(dividingBy: rhs.magnitude).quotient
        guard let signed = Int128Words(magnitude: quotient, sign: Sign(of: lhs) * Sign(of: rhs)) else {
            preconditionFailure("Int128Words division overflowed")  // coverage:ignore — exit-test trap
        }

        return signed
    }

    /// Returns the negation of a value.
    ///
    /// ```swift
    /// -Int128Words(5)   // -5
    /// ```
    ///
    /// - Parameter operand: The value to negate.
    /// - Returns: The value with its sign flipped.
    /// - Precondition: `operand` must not be ``min``, whose negation is out of range.
    package static prefix func - (operand: Int128Words) -> Int128Words {
        let (negation, overflow) = Int128Words(0).subtractingReportingOverflow(operand)
        precondition(!overflow, "Int128Words negation overflowed")

        return negation
    }
}

extension Int128Words {
    /// Creates a value from decimal text, or `nil` if the text isn't a decimal integer that fits.
    ///
    /// Takes an optional leading `+` or `-` and at least one ASCII digit, as `Int128(_:)` does.
    ///
    /// ```swift
    /// Int128Words("-42")   // -42
    /// Int128Words("1.5")   // nil
    /// ```
    ///
    /// - Parameter text: The text to parse.
    /// - Returns: The value, or `nil` if `text` isn't a decimal integer in `-2^127...2^127 - 1`.
    /// - Complexity: O(*n*), where *n* is the length of `text`.
    package init?(_ text: some StringProtocol) {
        // Reading the bytes in place, where the text's storage allows, skips the string index
        // arithmetic each step through a `Substring` costs.
        let value = text.utf8.withContiguousStorageIfAvailable(Int128Words.parsing) ?? Int128Words.parsing(text.utf8)
        guard let value else {
            return nil
        }

        self = value
    }

    /// Returns the value of decimal text's bytes, or `nil` if they aren't a decimal integer that fits.
    ///
    /// - Parameter utf8: The text's UTF-8 bytes.
    /// - Returns: The value, or `nil` if the bytes aren't a decimal integer in `-2^127...2^127 - 1`.
    /// - Complexity: O(*n*), where *n* is the number of bytes.
    private static func parsing(_ utf8: some Collection<UInt8>) -> Int128Words? {
        let (sign, digits) = switch utf8.first {
        case UInt8(ascii: "-"): (Sign.negative, utf8.dropFirst())
        case UInt8(ascii: "+"): (Sign.positive, utf8.dropFirst())
        default: (Sign.positive, utf8[...])
        }

        guard let magnitude = Int128Words.magnitude(ofDigits: digits) else {
            return nil
        }

        return Int128Words(magnitude: magnitude, sign: sign)
    }

    /// Returns the value of a run of ASCII decimal digits, or `nil` if it is empty, holds any other
    /// byte, or doesn't fit 128 bits.
    ///
    /// - Parameter digits: The digits' bytes, most significant first.
    /// - Returns: The value the digits spell.
    /// - Complexity: O(*n*), where *n* is the number of digits.
    private static func magnitude(ofDigits digits: some Collection<UInt8>) -> UInt128Words? {
        guard !digits.isEmpty else {
            return nil
        }

        var magnitude: UInt128Words = 0
        for byte in digits {
            guard (UInt8(ascii: "0") ... UInt8(ascii: "9")).contains(byte),
                  let next = magnitude.multipliedByTenAdding(byte - UInt8(ascii: "0")) else {
                return nil
            }
            magnitude = next
        }

        return magnitude
    }
}

extension Int64 {
    /// Creates a value from a 128-bit one, or `nil` if it is outside `Int64`.
    ///
    /// ```swift
    /// Int64(exactly: Int128Words(-5))          // -5
    /// Int64(exactly: Int128Words.max)          // nil
    /// ```
    ///
    /// - Parameter value: The value to narrow.
    /// - Returns: The same value, or `nil` if it doesn't fit.
    package init?(exactly value: Int128Words) {
        let low = Int64(bitPattern: value._storage.low)
        guard value._storage.high == UInt64(bitPattern: low >> 63) else {
            return nil
        }

        self = low
    }
}

extension Double {
    /// Creates the `Double` nearest a 128-bit value, rounding a tie to even.
    ///
    /// Gives the same bits as `Double(Int128)`.
    ///
    /// ```swift
    /// Double(Int128Words.max)   // 0x1p127
    /// ```
    ///
    /// - Parameter value: The value to convert.
    package init(_ value: Int128Words) {
        let magnitude = Double(magnitude: value.magnitude)
        self = Sign(of: value) == .negative ? -magnitude : magnitude
    }

    /// Creates the `Double` nearest an unsigned 128-bit value, rounding a tie to even.
    ///
    /// - Parameter magnitude: The value to convert.
    private init(magnitude: UInt128Words) {
        guard magnitude.high != 0 else {
            self.init(magnitude.low)
            return
        }

        // `top` keeps the 64 leading bits, and its lowest bit is set when any dropped bit was. A
        // `Double` keeps 53, so that bit only breaks a tie, the way the dropped bits would.
        let shift = UInt64.bitWidth - magnitude.high.leadingZeroBitCount
        let top = (magnitude >> shift).low
        let sticky: UInt64 = magnitude << (128 - shift) == 0 ? 0 : 1

        self = Double(top | sticky) * Double(sign: .plus, exponent: shift, significand: 1)
    }
}
