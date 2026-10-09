/// A 128-bit unsigned integer held as two 64-bit words.
///
/// Its arithmetic matches the standard library's `UInt128`: the `…ReportingOverflow` members wrap
/// and report the overflow, and the operators trap where `UInt128`'s do.
///
/// ```swift
/// let twoToThe64 = UInt128Words(high: 1, low: 0)
/// twoToThe64.quotientAndRemainder(dividingBy: 10)   // (1_844_674_407_370_955_161, 6)
/// ```
@usableFromInline
package struct UInt128Words: Hashable, Sendable, BitwiseCopyable {
    /// The upper 64 bits.
    @usableFromInline package let high: UInt64

    /// The lower 64 bits.
    @usableFromInline package let low: UInt64

    /// Creates a value from its two words.
    ///
    /// ```swift
    /// UInt128Words(high: 1, low: 5)   // 2^64 + 5
    /// ```
    ///
    /// - Parameters:
    ///   - high: The upper 64 bits.
    ///   - low: The lower 64 bits.
    @inlinable
    package init(high: UInt64, low: UInt64) {
        self.high = high
        self.low = low
    }

    /// Creates a value from a 64-bit one.
    ///
    /// ```swift
    /// UInt128Words(UInt64.max)   // 18_446_744_073_709_551_615
    /// ```
    ///
    /// - Parameter value: The value, which becomes the lower word.
    @inlinable
    package init(_ value: UInt64) {
        self.init(high: 0, low: value)
    }

    /// Creates a value from a full-width product's two words.
    ///
    /// - Parameter product: The product's upper and lower words.
    private init(_ product: (high: UInt64, low: UInt64)) {
        self.init(high: product.high, low: product.low)
    }

    /// The largest value, `2^128 - 1`.
    package static var max: UInt128Words {
        UInt128Words(high: .max, low: .max)
    }

    /// The smallest value, zero.
    package static var min: UInt128Words {
        UInt128Words(high: 0, low: 0)
    }
}

extension UInt128Words: ExpressibleByIntegerLiteral {
    /// Creates a value from an integer literal.
    ///
    /// ```swift
    /// let twoToThe64: UInt128Words = 18_446_744_073_709_551_616
    /// ```
    ///
    /// - Parameter value: The literal.
    /// - Precondition: `value` must be in `0...2^128 - 1`.
    @inlinable
    package init(integerLiteral value: StaticBigInt) {
        precondition(value.signum() >= 0 && value.bitWidth <= 129, "Integer literal overflows UInt128Words")

        self.init(wordsOf: value)
    }

    /// Creates a value from the lower 128 bits of a literal's two's-complement form.
    ///
    /// - Parameter literal: The literal to take the bits of.
    @inlinable
    init(wordsOf literal: StaticBigInt) {
        #if _pointerBitWidth(_64)
        self.init(high: UInt64(literal[1]), low: UInt64(literal[0]))
        #elseif _pointerBitWidth(_32)
        self.init(
            high: UInt64(literal[3]) << 32 | UInt64(literal[2]),
            low: UInt64(literal[1]) << 32 | UInt64(literal[0])
        )
        #else
        #error("UInt128Words reads a literal one machine word at a time; this word width isn't handled")
        #endif
    }
}

extension UInt128Words: Comparable {
    /// Returns whether the first value is less than the second.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: `true` if `lhs` is less than `rhs`; otherwise, `false`.
    @usableFromInline
    package static func < (lhs: UInt128Words, rhs: UInt128Words) -> Bool {
        (lhs.high, lhs.low) < (rhs.high, rhs.low)
    }
}

extension UInt128Words {
    /// Returns the sum of this value and another, and whether it overflowed.
    ///
    /// ```swift
    /// UInt128Words.max.addingReportingOverflow(1)   // (0, true)
    /// ```
    ///
    /// - Parameter other: The value to add.
    /// - Returns: The sum, wrapped to 128 bits, and `true` if it overflowed.
    @inlinable
    package func addingReportingOverflow(_ other: UInt128Words) -> (partialValue: UInt128Words, overflow: Bool) {
        let (sumLow, carry) = low.addingReportingOverflow(other.low)
        let (highWords, highOverflow) = high.addingReportingOverflow(other.high)
        let (sumHigh, carryOverflow) = highWords.addingReportingOverflow(carry ? 1 : 0)

        return (UInt128Words(high: sumHigh, low: sumLow), highOverflow || carryOverflow)
    }

    /// Returns the difference of this value and another, and whether it overflowed.
    ///
    /// ```swift
    /// UInt128Words.min.subtractingReportingOverflow(1)   // (UInt128Words.max, true)
    /// ```
    ///
    /// - Parameter other: The value to subtract.
    /// - Returns: The difference, wrapped to 128 bits, and `true` if it overflowed.
    @inlinable
    package func subtractingReportingOverflow(_ other: UInt128Words) -> (partialValue: UInt128Words, overflow: Bool) {
        let (differenceLow, borrow) = low.subtractingReportingOverflow(other.low)
        let (highWords, highOverflow) = high.subtractingReportingOverflow(other.high)
        let (differenceHigh, borrowOverflow) = highWords.subtractingReportingOverflow(borrow ? 1 : 0)

        return (UInt128Words(high: differenceHigh, low: differenceLow), highOverflow || borrowOverflow)
    }

    /// Returns the difference of two values.
    ///
    /// ```swift
    /// UInt128Words(high: 1, low: 0) - 1   // 18_446_744_073_709_551_615
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The minuend.
    ///   - rhs: The subtrahend.
    /// - Returns: The difference of `lhs` and `rhs`.
    /// - Precondition: `rhs` must not be greater than `lhs`.
    package static func - (lhs: UInt128Words, rhs: UInt128Words) -> UInt128Words {
        let (difference, overflow) = lhs.subtractingReportingOverflow(rhs)
        precondition(!overflow, "UInt128Words subtraction overflowed")

        return difference
    }

    /// Returns the product of this value and another, and whether it overflowed.
    ///
    /// ```swift
    /// UInt128Words(high: 1, low: 0).multipliedReportingOverflow(by: 3)   // (3 × 2^64, false)
    /// ```
    ///
    /// - Parameter other: The value to multiply by.
    /// - Returns: The product, wrapped to 128 bits, and `true` if it overflowed.
    package func multipliedReportingOverflow(by other: UInt128Words) -> (partialValue: UInt128Words, overflow: Bool) {
        let (lowCarry, productLow) = low.multipliedFullWidth(by: other.low)
        let (crossHigh, crossLow) = low.multipliedFullWidth(by: other.high)
        let (otherCrossHigh, otherCrossLow) = high.multipliedFullWidth(by: other.low)
        let (partialHigh, firstCarry) = lowCarry.addingReportingOverflow(crossLow)
        let (productHigh, secondCarry) = partialHigh.addingReportingOverflow(otherCrossLow)

        let overflow = (high != 0 && other.high != 0) || crossHigh != 0 || otherCrossHigh != 0
            || firstCarry || secondCarry
        return (UInt128Words(high: productHigh, low: productLow), overflow)
    }

    /// Returns the full 256-bit product of this value and another.
    ///
    /// ```swift
    /// UInt128Words.max.multipliedFullWidth(by: 2)   // (high: 1, low: 2^128 - 2)
    /// ```
    ///
    /// - Parameter other: The value to multiply by.
    /// - Returns: The product's upper and lower 128 bits.
    package func multipliedFullWidth(by other: UInt128Words) -> (high: UInt128Words, low: UInt128Words) {
        let lowProduct = UInt128Words(low.multipliedFullWidth(by: other.low))
        let highProduct = UInt128Words(high.multipliedFullWidth(by: other.high))
        let (cross, crossCarry) = UInt128Words(low.multipliedFullWidth(by: other.high))
            .addingReportingOverflow(UInt128Words(high.multipliedFullWidth(by: other.low)))
        let (productLow, lowCarry) = lowProduct.addingReportingOverflow(UInt128Words(high: cross.low, low: 0))

        // These sums build the product's upper half, which is below 2^128, so neither wraps.
        let productHigh = highProduct
            .addingReportingOverflow(UInt128Words(high: crossCarry ? 1 : 0, low: cross.high)).partialValue
            .addingReportingOverflow(UInt128Words(lowCarry ? 1 : 0)).partialValue
        return (productHigh, productLow)
    }
}

extension UInt128Words {
    /// Returns the quotient and remainder of dividing a 256-bit value by this one.
    ///
    /// Matches `UInt128.dividingFullWidth(_:)`.
    ///
    /// ```swift
    /// let ten: UInt128Words = 10
    /// ten.dividingFullWidth((high: 1, low: 0))   // (2^128 / 10, 6)
    /// ```
    ///
    /// - Parameter dividend: The 256-bit value to divide, as its upper and lower 128 bits.
    /// - Returns: The quotient and the remainder.
    /// - Precondition: This value must be greater than `dividend.high`, so the quotient fits 128 bits.
    package func dividingFullWidth(
        _ dividend: (high: UInt128Words, low: UInt128Words)
    ) -> (quotient: UInt128Words, remainder: UInt128Words) {
        precondition(dividend.high < self, "UInt128Words.dividingFullWidth quotient overflowed")

        guard high != 0 else {
            // `dividend.high` is below this one-word divisor, so it is its own lower word.
            let (upper, carried) = UInt128Words.divide(dividend.high.low, dividend.low.high, by: low)
            let (lower, remainder) = UInt128Words.divide(carried, dividend.low.low, by: low)
            return (UInt128Words(high: upper, low: lower), UInt128Words(remainder))
        }

        // `dividend.high` is below this divisor, so shifting both by the divisor's leading zeros
        // loses no bits of it.
        let shift = high.leadingZeroBitCount
        let divisor = self << shift
        let top = dividend.high << shift | dividend.low >> (128 - shift)
        let bottom = dividend.low << shift

        let (upper, carried) = UInt128Words.divide(top.high, top.low, bottom.high, by: divisor)
        let (lower, remainder) = UInt128Words.divide(carried.high, carried.low, bottom.low, by: divisor)
        return (UInt128Words(high: upper, low: lower), remainder >> shift)
    }

    /// Returns the quotient and remainder of dividing this value by another.
    ///
    /// ```swift
    /// UInt128Words.max.quotientAndRemainder(dividingBy: 10)
    /// // (34_028_236_692_093_846_346_337_460_743_176_821_145, 5)
    /// ```
    ///
    /// - Parameter divisor: The value to divide by.
    /// - Returns: The quotient and the remainder.
    /// - Precondition: `divisor` must not be zero.
    package func quotientAndRemainder(
        dividingBy divisor: UInt128Words
    ) -> (quotient: UInt128Words, remainder: UInt128Words) {
        precondition(divisor != 0, "UInt128Words division by zero")

        guard divisor.high != 0 else {
            let (upper, carried) = high.quotientAndRemainder(dividingBy: divisor.low)
            let (lower, remainder) = UInt128Words.divide(carried, low, by: divisor.low)
            return (UInt128Words(high: upper, low: lower), UInt128Words(remainder))
        }

        // A two-word divisor leaves a one-word quotient. Shifted by at most 63 bits, this value's top
        // two words stay below the shifted divisor, whose top bit is set.
        let shift = divisor.high.leadingZeroBitCount
        let shifted = self << shift
        let (quotient, remainder) = UInt128Words.divide(
            high >> (64 - shift), shifted.high, shifted.low, by: divisor << shift
        )
        return (UInt128Words(quotient), remainder >> shift)
    }

    /// Returns the quotient and remainder of dividing a two-word value by a one-word divisor.
    ///
    /// The same result as `divisor.dividingFullWidth((high, low))`.
    ///
    /// - Parameters:
    ///   - high: The dividend's upper word.
    ///   - low: The dividend's lower word.
    ///   - divisor: The divisor.
    /// - Returns: The one-word quotient and the remainder.
    /// - Precondition: `high` must be below `divisor`, so the quotient fits one word.
    @inline(__always)
    private static func divide(
        _ high: UInt64,
        _ low: UInt64,
        by divisor: UInt64
    ) -> (quotient: UInt64, remainder: UInt64) {
        // `dividingFullWidth` is a library call on arm64; each divide below is one instruction.
        guard high != 0 else {
            return low.quotientAndRemainder(dividingBy: divisor)
        }

        guard divisor >> halfWordWidth != 0 else {
            // `high` and every remainder are below this half-word divisor, so each step's dividend
            // fits one word and each step's quotient fits half a word.
            let (upper, carried) = (high << halfWordWidth | low >> halfWordWidth)
                .quotientAndRemainder(dividingBy: divisor)
            let (lower, remainder) = (carried << halfWordWidth | low & lowerHalfMask)
                .quotientAndRemainder(dividingBy: divisor)
            return (upper << halfWordWidth | lower, remainder)
        }

        return divisor.dividingFullWidth((high, low))
    }

    /// The width of half a word, in bits.
    private static var halfWordWidth: Int {
        UInt64.bitWidth / 2
    }

    /// The mask that keeps a word's lower half.
    private static var lowerHalfMask: UInt64 {
        UInt64(UInt32.max)
    }

    /// Returns the quotient and remainder of dividing a three-word value by a two-word divisor whose
    /// top bit is set.
    ///
    /// Knuth, *The Art of Computer Programming*, vol. 2, §4.3.1, Algorithm D, steps D3 and D4, for
    /// one quotient word.
    ///
    /// - Parameters:
    ///   - top: The dividend's upper word.
    ///   - middle: The dividend's middle word.
    ///   - bottom: The dividend's lower word.
    ///   - divisor: The divisor, with its top bit set.
    /// - Returns: The one-word quotient and the remainder.
    /// - Precondition: `(top, middle)` must be below `divisor`, so the quotient fits one word.
    private static func divide(
        _ top: UInt64,
        _ middle: UInt64,
        _ bottom: UInt64,
        by divisor: UInt128Words
    ) -> (quotient: UInt64, remainder: UInt128Words) {
        var (quotient, partialRemainder) = estimate(top, middle, by: divisor.high)

        // D3's test weighs the estimate against the whole two-word divisor, so it is exact: once it
        // fails the estimate is the quotient, and D6's add-back is never needed.
        while let remainderWord = partialRemainder,
              UInt128Words(quotient.multipliedFullWidth(by: divisor.low)) > UInt128Words(high: remainderWord, low: bottom) {
            // The test passed, so the estimate is above the true quotient and at least one.
            quotient -= 1
            let (next, overflow) = remainderWord.addingReportingOverflow(divisor.high)
            partialRemainder = overflow ? nil : next
        }

        // The true remainder is below the divisor, so the lower 128 bits of the dividend minus the
        // product are all of it, and wrapping arithmetic modulo 2^128 gives it exactly.
        let (productCarry, productLow) = quotient.multipliedFullWidth(by: divisor.low)
        let product = UInt128Words(high: productCarry &+ quotient &* divisor.high, low: productLow)
        let remainder = UInt128Words(high: middle, low: bottom).subtractingReportingOverflow(product).partialValue
        return (quotient, remainder)
    }

    /// Returns D3's first estimate of a quotient word, from the dividend's top two words and the
    /// divisor's top word.
    ///
    /// The estimate is at most two above the true quotient word.
    ///
    /// - Parameters:
    ///   - top: The dividend's upper word.
    ///   - middle: The dividend's middle word.
    ///   - divisorHigh: The divisor's upper word, with its top bit set.
    /// - Returns: The estimate, and the remainder of `(top, middle)` less the estimate times
    ///   `divisorHigh`, or `nil` when that remainder needs a second word.
    /// - Precondition: `top` must not be greater than `divisorHigh`.
    private static func estimate(
        _ top: UInt64,
        _ middle: UInt64,
        by divisorHigh: UInt64
    ) -> (quotient: UInt64, remainder: UInt64?) {
        guard top < divisorHigh else {
            // `dividingFullWidth` traps here, the quotient needing a second word; Knuth caps the
            // estimate at the largest word, whose remainder is `middle + divisorHigh`.
            let (remainder, overflow) = middle.addingReportingOverflow(divisorHigh)
            return (.max, overflow ? nil : remainder)
        }

        let (quotient, remainder) = divide(top, middle, by: divisorHigh)
        return (quotient, remainder)
    }
}

extension UInt128Words {
    /// Returns the result of shifting a value's bits to the left.
    ///
    /// Matches `UInt128`'s smart shift: a negative amount shifts right, and an amount of 128 or more
    /// gives zero.
    ///
    /// ```swift
    /// UInt128Words(1) << 64   // 2^64
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to shift.
    ///   - rhs: The number of bits to shift by.
    /// - Returns: The shifted value.
    @inlinable
    package static func << (lhs: UInt128Words, rhs: Int) -> UInt128Words {
        guard rhs >= 0 else {
            return rhs < -127 ? 0 : lhs >> -rhs
        }
        guard rhs < 128 else {
            return 0
        }
        // Each amount below is in `0..<64`, so the masking shifts never mask it.
        guard rhs < 64 else {
            return UInt128Words(high: lhs.low &<< (rhs - 64), low: 0)
        }
        guard rhs > 0 else {
            return lhs
        }

        return UInt128Words(high: lhs.high &<< rhs | lhs.low &>> (64 - rhs), low: lhs.low &<< rhs)
    }

    /// Returns the result of shifting a value's bits to the right.
    ///
    /// Matches `UInt128`'s smart shift: a negative amount shifts left, and an amount of 128 or more
    /// gives zero.
    ///
    /// ```swift
    /// UInt128Words(high: 1, low: 0) >> 64   // 1
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to shift.
    ///   - rhs: The number of bits to shift by.
    /// - Returns: The shifted value.
    @inlinable
    package static func >> (lhs: UInt128Words, rhs: Int) -> UInt128Words {
        guard rhs >= 0 else {
            return rhs < -127 ? 0 : lhs << -rhs
        }
        guard rhs < 128 else {
            return 0
        }
        // Each amount below is in `0..<64`, so the masking shifts never mask it.
        guard rhs < 64 else {
            return UInt128Words(high: 0, low: lhs.high &>> (rhs - 64))
        }
        guard rhs > 0 else {
            return lhs
        }

        return UInt128Words(high: lhs.high &>> rhs, low: lhs.low &>> rhs | lhs.high &<< (64 - rhs))
    }

    /// Returns the bitwise OR of two values.
    ///
    /// ```swift
    /// UInt128Words(high: 1, low: 0) | 2   // 2^64 + 2
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: A value.
    ///   - rhs: Another value.
    /// - Returns: The bits set in either value.
    @inlinable
    package static func | (lhs: UInt128Words, rhs: UInt128Words) -> UInt128Words {
        UInt128Words(high: lhs.high | rhs.high, low: lhs.low | rhs.low)
    }

    /// Whether this value is even or odd.
    package var parity: Parity {
        Parity(of: low)
    }
}

extension UInt128Words {
    /// Returns this value times ten plus a digit, or `nil` if that overflows: one step of reading a
    /// decimal number.
    ///
    /// ```swift
    /// UInt128Words(12).multipliedByTenAdding(3)    // 123
    /// UInt128Words.max.multipliedByTenAdding(0)    // nil
    /// ```
    ///
    /// - Parameter digit: The value to add after multiplying by ten, a decimal digit's `0...9`.
    /// - Returns: `self × 10 + digit`, or `nil` if it doesn't fit 128 bits.
    package func multipliedByTenAdding(_ digit: UInt8) -> UInt128Words? {
        let (lowCarry, shiftedLow) = low.multipliedFullWidth(by: 10)
        let (sumLow, digitCarry) = shiftedLow.addingReportingOverflow(UInt64(digit))
        guard high != 0 else {
            // `lowCarry` is at most 9, so with no upper word the carries fit one without wrapping.
            return UInt128Words(high: lowCarry &+ (digitCarry ? 1 : 0), low: sumLow)
        }

        let (highProduct, highOverflow) = high.multipliedReportingOverflow(by: 10)
        let (shiftedHigh, carryOverflow) = highProduct.addingReportingOverflow(lowCarry)
        let (sumHigh, digitOverflow) = shiftedHigh.addingReportingOverflow(digitCarry ? 1 : 0)

        guard !highOverflow, !carryOverflow, !digitOverflow else {
            return nil
        }

        return UInt128Words(high: sumHigh, low: sumLow)
    }
}
