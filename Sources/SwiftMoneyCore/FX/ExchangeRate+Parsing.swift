public extension FX.ExchangeRate {
    /// Creates an exchange rate from a market quote's text: `To` major units per one `From` major
    /// unit, as a plain decimal.
    ///
    /// The quote is never rounded. A rate holds 18 decimal places of `To`'s smallest unit per
    /// `From`'s smallest unit, so how many places a quote may have depends on the two currencies.
    ///
    /// ```swift
    /// let eurGbp = try FX.ExchangeRate<Currencies.EUR, Currencies.GBP>(string: "0.87")
    /// let usdJpy = try FX.ExchangeRate<Currencies.USD, Currencies.JPY>(string: "149.5")
    /// let tooFine = try FX.ExchangeRate<Currencies.USD, Currencies.JPY>(string: "149.12345678901234567")   // throws
    /// ```
    ///
    /// - Parameter quote: The market quote, such as `"0.87"`.
    /// - Throws: ``FX/ExchangeRateParsingError/unrecognizedText`` if `quote` is not a plain decimal;
    ///   ``FX/ExchangeRateParsingError/notPositive`` if it is zero or negative;
    ///   ``FX/ExchangeRateParsingError/inexactRate(maximumFractionDigits:)`` if it has more places
    ///   than the rate holds; ``FX/ExchangeRateParsingError/overflow`` if it is too large to hold.
    init(string quote: String) throws(FX.ExchangeRateParsingError) {
        guard let (significand, fractionDigits) = Rate.scanDecimal(quote[...]) else {
            throw .unrecognizedText
        }

        let rate = try FX.minorPerMinorRate(
            significand: significand,
            exponent: -fractionDigits,
            placesGained: Self.placesGained
        )

        guard let result = Self(minorPerMinor: rate) else {
            throw .notPositive
        }

        self = result
    }
}

extension FX.ExchangeRate: CustomStringConvertible {
    /// The market quote, with every digit the rate holds and no trailing zeros.
    ///
    /// ```swift
    /// let eurGbp = try FX.ExchangeRate<Currencies.EUR, Currencies.GBP>(string: "0.870")
    /// eurGbp.description   // "0.87"
    /// ```
    public var description: String {
        withUnsafeTemporaryAllocation(of: UInt8.self, capacity: UInt128Words.maximumDecimalDigits) { buffer in
            // The stored rate is a positive whole number of 10⁻¹⁸ smallest-unit parts, so its digits
            // are the quote's with the point moved `18 + placesGained` places in: from 0 to 36.
            let start = minorPerMinorRate.value.storageBits.magnitude.writeDecimalDigits(endingAt: buffer)
            var end = buffer.count
            var places = Fixed.fractionalDigits + Self.placesGained

            while places > 0, buffer[end - 1] == UInt8(ascii: "0") {
                end -= 1
                places -= 1
            }

            return Self.quoteText(digits: UnsafeMutableBufferPointer(rebasing: buffer[start ..< end]), places: places)
        }
    }

    /// Returns digits written as a decimal, with the point the given number of places from the end.
    ///
    /// - Parameters:
    ///   - digits: ASCII digits, most significant first, with no leading or trailing zeros to drop.
    ///   - places: How many of the digits fall after the point. May exceed the number of digits.
    /// - Returns: The decimal, with a leading `0` before a point that would otherwise start it.
    private static func quoteText(digits: UnsafeMutableBufferPointer<UInt8>, places: Int) -> String {
        let count = digits.count
        let length = places == 0 ? count : count > places ? count + 1 : places + 2

        return String(unsafeUninitializedCapacity: length) { output in
            var offset = 0

            func write(_ byte: UInt8) {
                output[offset] = byte
                offset += 1
            }

            if places == 0 {
                digits.forEach(write)
            } else if count > places {
                digits[..<(count - places)].forEach(write)
                write(UInt8(ascii: "."))
                digits[(count - places)...].forEach(write)
            } else {
                write(UInt8(ascii: "0"))
                write(UInt8(ascii: "."))
                (0 ..< (places - count)).forEach { _ in write(UInt8(ascii: "0")) }
                digits.forEach(write)
            }

            return offset
        }
    }
}

private extension UInt128Words {
    /// The most decimal digits a value can have: ``max`` is about 3.4 × 10³⁸.
    static var maximumDecimalDigits: Int { 39 }

    /// Writes the value's decimal digits as ASCII at the end of a buffer, and returns where they start.
    ///
    /// - Parameter buffer: Space for at least ``maximumDecimalDigits`` bytes.
    /// - Returns: The index of the most significant digit; the digits run to the buffer's end.
    func writeDecimalDigits(endingAt buffer: UnsafeMutableBufferPointer<UInt8>) -> Int {
        var remaining = self
        var index = buffer.count

        func write(_ value: UInt64, padTo width: Int) {
            var value = value
            var written = 0

            repeat {
                index -= 1
                buffer[index] = UInt8(ascii: "0") + UInt8(value % 10)
                value /= 10
                written += 1
            } while value > 0 || written < width
        }

        // Each pass splits off 18 digits in one-word steps: a hardware divide of the top word, then
        // 10¹⁸'s reciprocal on the remainder and the low word. A value below 2¹²⁸ takes at most two.
        while remaining.high != 0 {
            let (upper, carried) = remaining.high.quotientAndRemainder(dividingBy: Fixed.Scale.divisor)
            let (lower, chunk) = Fixed.Scale.divide(high: carried, low: remaining.low)
            write(chunk, padTo: Fixed.fractionalDigits)
            remaining = UInt128Words(high: upper, low: lower)
        }
        write(remaining.low, padTo: 1)

        return index
    }
}

extension FX.ExchangeRate {
    /// The decimal places a quote gains when rescaled from major units to smallest units: `To`'s
    /// places less `From`'s, from `-18` to `18`.
    static var placesGained: Int {
        To.currency.unitScale.decimalPlaces - From.currency.unitScale.decimalPlaces
    }
}

extension FX {
    /// Returns a market quote rescaled from major units to smallest units, exactly.
    ///
    /// Takes the scales as a number rather than as currency types, so a rate between currencies known
    /// only at runtime can use it too. Leaves the sign alone: a rate's own initializer refuses one that
    /// isn't positive.
    ///
    /// - Parameters:
    ///   - significand: The quote's digits as a whole number: `87` for `0.87`.
    ///   - exponent: The power of ten that scales `significand` to the quote: `-2` for `0.87`.
    ///   - placesGained: The decimal places of the currency converted to, less those of the currency
    ///     converted from.
    /// - Returns: The quote in smallest units of the currency converted to, per smallest unit of the
    ///   currency converted from.
    /// - Throws: ``ExchangeRateParsingError/inexactRate(maximumFractionDigits:)`` if a non-zero digit
    ///   falls past the 18th place; ``ExchangeRateParsingError/overflow`` if the result is too large
    ///   to hold.
    static func minorPerMinorRate(
        significand: Int128Words,
        exponent: Int,
        placesGained: Int
    ) throws(ExchangeRateParsingError) -> Rate {
        let shifted = exponent + placesGained

        switch Fixed.exactness(significand: significand, exponent: shifted, rounding: .toNearestOrEven) {
        case let .exact(value)?:
            return Rate(value)

        case .rounded?:
            throw .inexactRate(maximumFractionDigits: Fixed.fractionalDigits + placesGained)

        case nil:
            // Building it overflows when scaling up. Scaling down fails only past the largest power of
            // ten a 128-bit integer holds, which leaves non-zero digits beyond the 18th place.
            guard shifted + Fixed.fractionalDigits < 0 else {
                throw .overflow
            }
            throw .inexactRate(maximumFractionDigits: Fixed.fractionalDigits + placesGained)
        }
    }
}
