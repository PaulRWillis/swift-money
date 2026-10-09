public extension FX.ExchangeRateOf where From: CurrencyType, To: CurrencyType {
    /// Creates an exchange rate from a market quote's text: `To` major units per one `From` major
    /// unit, as a plain decimal.
    ///
    /// The quote is never rounded. A rate holds 18 decimal places of `To`'s smallest unit per
    /// `From`'s smallest unit, so how many places a quote may have depends on the two currencies.
    ///
    /// ```swift
    /// let eurGbp = try FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(string: "0.87")
    /// let usdJpy = try FX.ExchangeRateOf<Currencies.USD, Currencies.JPY>(string: "149.5")
    /// let tooFine = try FX.ExchangeRateOf<Currencies.USD, Currencies.JPY>(string: "149.12345678901234567")   // throws
    /// ```
    ///
    /// - Parameter quote: The market quote, such as `"0.87"`.
    /// - Throws: ``FX/ExchangeRateParsingError/unrecognizedText`` if `quote` is not a plain decimal;
    ///   ``FX/ExchangeRateParsingError/notPositive`` if it is zero or negative;
    ///   ``FX/ExchangeRateParsingError/inexactRate(maximumFractionDigits:)`` if it has more places
    ///   than the rate holds; ``FX/ExchangeRateParsingError/overflow`` if it is too large to hold.
    @inlinable
    init(string quote: String) throws(FX.ExchangeRateParsingError) {
        try self.init(quote: quote, fromStorage: .implied, toStorage: .implied)
    }
}

extension FX.ExchangeRateOf {
    /// Creates a rate from a market quote's text, between the currencies two storages name.
    ///
    /// The quote is scaled for the same two currencies the rate stores, so it can't be scaled for
    /// one pair and kept under another.
    ///
    /// - Parameters:
    ///   - quote: The market quote, such as `"0.87"`.
    ///   - fromStorage: What names the currency the rate converts from.
    ///   - toStorage: What names the currency the rate converts to.
    /// - Throws: ``FX/ExchangeRateParsingError/unrecognizedText`` if `quote` is not a plain decimal;
    ///   ``FX/ExchangeRateParsingError/notPositive`` if it is zero or negative;
    ///   ``FX/ExchangeRateParsingError/inexactRate(maximumFractionDigits:)`` if it has more places
    ///   than the rate holds; ``FX/ExchangeRateParsingError/overflow`` if it is too large to hold.
    @inlinable
    init(quote: String, fromStorage: From.Storage, toStorage: To.Storage) throws(FX.ExchangeRateParsingError) {
        let rate = try FX.minorPerMinorRate(
            quote: quote,
            placesGained: Self.placesGained(fromStorage: fromStorage, toStorage: toStorage)
        )

        self.init(unchecked: rate, fromStorage: fromStorage, toStorage: toStorage)
    }

    /// Creates a rate from a market quote, between the currencies two storages name.
    ///
    /// The quote is scaled for the same two currencies the rate stores, so it can't be scaled for
    /// one pair and kept under another.
    ///
    /// - Parameters:
    ///   - marketRate: The market quote: `To` major units per one `From` major unit.
    ///   - fromStorage: What names the currency the rate converts from.
    ///   - toStorage: What names the currency the rate converts to.
    /// - Throws: ``FX/ExchangeRateParsingError/notPositive`` if the quote is zero or negative;
    ///   ``FX/ExchangeRateParsingError/inexactRate(maximumFractionDigits:)`` if it has more places
    ///   than the rate holds; ``FX/ExchangeRateParsingError/overflow`` if it is too large to hold.
    @inlinable
    init(marketRate: Rate, fromStorage: From.Storage, toStorage: To.Storage) throws(FX.ExchangeRateParsingError) {
        let rate = try FX.minorPerMinorRate(
            marketRate: marketRate,
            placesGained: Self.placesGained(fromStorage: fromStorage, toStorage: toStorage)
        )

        self.init(unchecked: rate, fromStorage: fromStorage, toStorage: toStorage)
    }

    /// The decimal places a quote gains when rescaled from major units to smallest units: `To`'s
    /// places less `From`'s, from `-18` to `18`.
    @inlinable
    var placesGained: Int {
        Self.placesGained(fromStorage: fromStorage, toStorage: toStorage)
    }

    /// Returns the decimal places a quote gains when rescaled from major units to smallest units,
    /// between the currencies two storages name.
    ///
    /// - Parameters:
    ///   - fromStorage: What names the currency converted from.
    ///   - toStorage: What names the currency converted to.
    /// - Returns: The places of the currency converted to, less those of the one converted from,
    ///   from `-18` to `18`.
    @inlinable
    static func placesGained(fromStorage: From.Storage, toStorage: To.Storage) -> Int {
        FX.placesGained(from: From.currency(for: fromStorage), to: To.currency(for: toStorage))
    }
}

extension FX {
    /// Returns the decimal places a quote gains when rescaled from major units to smallest units.
    ///
    /// - Parameters:
    ///   - from: The currency converted from.
    ///   - to: The currency converted to.
    /// - Returns: The places of `to` less those of `from`, from `-18` to `18`.
    @inlinable
    static func placesGained(from: Currency, to: Currency) -> Int {
        to.unitScale.decimalPlaces - from.unitScale.decimalPlaces
    }
}

extension FX.ExchangeRateOf: CustomStringConvertible {
    /// The market quote, with every digit the rate holds and no trailing zeros.
    ///
    /// ```swift
    /// let eurGbp = try FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(string: "0.870")
    /// eurGbp.description   // "0.87"
    /// ```
    @inlinable
    public var description: String {
        FX.quoteText(of: minorPerMinorRate, placesGained: placesGained)
    }
}

extension FX {
    /// Returns a rate's market quote, with every digit the rate holds and no trailing zeros.
    ///
    /// - Parameters:
    ///   - minorPerMinorRate: A positive rate in smallest units of one currency per smallest unit of
    ///     another.
    ///   - placesGained: The decimal places of the currency converted to, less those of the currency
    ///     converted from.
    /// - Returns: The quote in major units of the one currency per major unit of the other.
    @usableFromInline
    static func quoteText(of minorPerMinorRate: Rate, placesGained: Int) -> String {
        withUnsafeTemporaryAllocation(of: UInt8.self, capacity: UInt128.maximumDecimalDigits) { buffer in
            // The stored rate is a positive whole number of 10⁻¹⁸ smallest-unit parts, so its digits
            // are the quote's with the point moved `18 + placesGained` places in: from 0 to 36.
            let start = minorPerMinorRate.value.storageBits.magnitude.writeDecimalDigits(endingAt: buffer)
            var end = buffer.count
            var places = Fixed.fractionalDigits + placesGained

            while places > 0, buffer[end - 1] == UInt8(ascii: "0") {
                end -= 1
                places -= 1
            }

            return decimalText(digits: UnsafeMutableBufferPointer(rebasing: buffer[start ..< end]), places: places)
        }
    }

    /// Returns digits written as a decimal, with the point the given number of places from the end.
    ///
    /// - Parameters:
    ///   - digits: ASCII digits, most significant first, with no leading or trailing zeros to drop.
    ///   - places: How many of the digits fall after the point. May exceed the number of digits.
    /// - Returns: The decimal, with a leading `0` before a point that would otherwise start it.
    private static func decimalText(digits: UnsafeMutableBufferPointer<UInt8>, places: Int) -> String {
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

private extension UInt128 {
    /// The most decimal digits a value can have: `UInt128.max` is about 3.4 × 10³⁸.
    static let maximumDecimalDigits = 39

    /// Writes the value's decimal digits as ASCII at the end of a buffer, and returns where they start.
    ///
    /// - Parameter buffer: Space for at least ``maximumDecimalDigits`` bytes.
    /// - Returns: The index of the most significant digit; the digits run to the buffer's end.
    func writeDecimalDigits(endingAt buffer: UnsafeMutableBufferPointer<UInt8>) -> Int {
        // Ten to the nineteenth is the largest power of ten a `UInt64` holds, so each chunk of 19
        // digits is written with cheap 64-bit division, and the 128-bit division runs at most twice.
        let chunk: UInt64 = 10_000_000_000_000_000_000
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

        while remaining > UInt128(UInt64.max) {
            let (quotient, low) = remaining.quotientAndRemainder(dividingBy: UInt128(chunk))
            write(UInt64(low), padTo: 19)
            remaining = quotient
        }
        write(UInt64(remaining), padTo: 1)

        return index
    }
}

extension FX {
    /// Returns a market quote's text rescaled from major units to smallest units, exactly.
    ///
    /// - Parameters:
    ///   - quote: The market quote, such as `"0.87"`.
    ///   - placesGained: The decimal places of the currency converted to, less those of the currency
    ///     converted from.
    /// - Returns: The quote in smallest units of the currency converted to, per smallest unit of the
    ///   currency converted from.
    /// - Throws: ``ExchangeRateParsingError/unrecognizedText`` if `quote` is not a plain decimal;
    ///   otherwise as ``minorPerMinorRate(significand:exponent:placesGained:)`` does.
    @usableFromInline
    static func minorPerMinorRate(quote: String, placesGained: Int) throws(ExchangeRateParsingError) -> Rate {
        guard let (significand, fractionDigits) = Rate.scanDecimal(quote[...]) else {
            throw .unrecognizedText
        }

        return try minorPerMinorRate(significand: significand, exponent: -fractionDigits, placesGained: placesGained)
    }

    /// Returns a market quote rescaled from major units to smallest units, exactly.
    ///
    /// - Parameters:
    ///   - marketRate: The market quote: major units of one currency per major unit of another.
    ///   - placesGained: The decimal places of the currency converted to, less those of the currency
    ///     converted from.
    /// - Returns: The quote in smallest units of the currency converted to, per smallest unit of the
    ///   currency converted from.
    /// - Throws: As ``minorPerMinorRate(significand:exponent:placesGained:)`` does.
    @usableFromInline
    static func minorPerMinorRate(marketRate: Rate, placesGained: Int) throws(ExchangeRateParsingError) -> Rate {
        try minorPerMinorRate(
            significand: marketRate.value.storageBits,
            exponent: -Fixed.fractionalDigits,
            placesGained: placesGained
        )
    }

    /// Returns a market quote rescaled from major units to smallest units, exactly.
    ///
    /// Takes the scales as a number rather than as currency types, so a rate between currencies known
    /// only at runtime can use it too.
    ///
    /// - Parameters:
    ///   - significand: The quote's digits as a whole number: `87` for `0.87`.
    ///   - exponent: The power of ten that scales `significand` to the quote: `-2` for `0.87`.
    ///   - placesGained: The decimal places of the currency converted to, less those of the currency
    ///     converted from.
    /// - Returns: The quote in smallest units of the currency converted to, per smallest unit of the
    ///   currency converted from: always greater than zero.
    /// - Throws: ``ExchangeRateParsingError/inexactRate(maximumFractionDigits:)`` if a non-zero digit
    ///   falls past the 18th place; ``ExchangeRateParsingError/overflow`` if the result is too large
    ///   to hold; ``ExchangeRateParsingError/notPositive`` if it is zero or negative.
    static func minorPerMinorRate(
        significand: Int128,
        exponent: Int,
        placesGained: Int
    ) throws(ExchangeRateParsingError) -> Rate {
        let shifted = exponent + placesGained

        switch Fixed.exactness(significand: significand, exponent: shifted, rounding: .toNearestOrEven) {
        case let .exact(value)?:
            let rate = Rate(value)

            guard rate.isPositive else {
                throw .notPositive
            }

            return rate

        case .rounded?:
            throw .inexactRate(maximumFractionDigits: Fixed.fractionalDigits + placesGained)

        case nil:
            // Building it overflows when scaling up. Scaling down fails only past the largest power of
            // ten `Int128` holds, which leaves non-zero digits beyond the 18th place.
            guard shifted + Fixed.fractionalDigits < 0 else {
                throw .overflow
            }
            throw .inexactRate(maximumFractionDigits: Fixed.fractionalDigits + placesGained)
        }
    }
}
