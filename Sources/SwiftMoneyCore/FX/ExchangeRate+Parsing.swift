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
        // The stored rate is a positive whole number of 10⁻¹⁸ smallest-unit parts, so its digits are
        // the quote's with the point moved `18 + placesGained` places in: from 0 to 36.
        var digits = String(minorPerMinorRate.value.storageBits)
        var places = Fixed.fractionalDigits + Self.placesGained

        while places > 0, digits.last == "0" {
            digits.removeLast()
            places -= 1
        }

        guard places > 0 else {
            return digits
        }

        let padded = String(repeating: "0", count: max(0, places + 1 - digits.count)) + digits
        let point = padded.index(padded.endIndex, offsetBy: -places)

        return String(padded[..<point]) + "." + String(padded[point...])
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
        significand: Int128,
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
            // ten `Int128` holds, which leaves non-zero digits beyond the 18th place.
            guard shifted + Fixed.fractionalDigits < 0 else {
                throw .overflow
            }
            throw .inexactRate(maximumFractionDigits: Fixed.fractionalDigits + placesGained)
        }
    }
}
