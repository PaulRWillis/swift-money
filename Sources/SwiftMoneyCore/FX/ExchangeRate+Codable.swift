#if !hasFeature(Embedded)

extension FX.ExchangeRate: Codable {
    /// Writes the rate as its two currency codes and its market quote.
    ///
    /// The quote is `To` major units per one `From` major unit, as a decimal string carrying every
    /// digit the rate holds, so it reads back unchanged.
    ///
    /// ```swift
    /// let eurGbp = FX.ExchangeRate<Currencies.EUR, Currencies.GBP>("0.87")!
    /// try encoder.encode(eurGbp)   // {"from":"EUR","rate":"0.87","to":"GBP"}
    /// ```
    ///
    /// - Parameter encoder: The encoder to write to.
    /// - Throws: Only what `encoder` throws.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(String(From.currency.code), forKey: .from)
        try container.encode(String(To.currency.code), forKey: .to)
        try container.encode(marketQuoteText, forKey: .rate)
    }

    /// Reads a rate written as its two currency codes and its market quote.
    ///
    /// The codes must be `From`'s and `To`'s. The quote is a positive decimal string the rate can
    /// hold exactly: it is never rounded.
    ///
    /// ```swift
    /// {"from": "EUR", "to": "GBP", "rate": "0.87"}                    // €1 = £0.87
    /// {"from": "USD", "to": "GBP", "rate": "0.75"}                    // refused: not a EUR→GBP rate
    /// {"from": "EUR", "to": "GBP", "rate": "0.8765262907123456789"}   // refused: too many places
    /// ```
    ///
    /// - Parameter decoder: The decoder to read from.
    /// - Throws: `DecodingError` if a field is missing, a code is not the one this type names, or
    ///   the quote is not a positive decimal the rate can hold exactly.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try Self.check(container, key: .from, holds: From.currency.code)
        try Self.check(container, key: .to, holds: To.currency.code)

        let text = try container.decode(String.self, forKey: .rate)

        guard let (significand, fractionDigits) = Rate.scanDecimal(text[...]), significand > 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .rate,
                in: container,
                debugDescription: """
                    Not a market quote: "\(text)" in the "\(CodingKeys.rate.stringValue)" field. \
                    Write the rate as a positive decimal string, as in "0.87".
                    """
            )
        }

        // Moving the point rescales the quote to minor units without rounding it, where building a
        // `Rate` first would round any quote finer than eighteen places before the check below.
        let exactness = Fixed.exactness(
            significand: significand,
            exponent: Self.placesGained - fractionDigits,
            rounding: .toNearestOrEven
        )

        guard let exactness else {
            throw DecodingError.dataCorruptedError(
                forKey: .rate,
                in: container,
                debugDescription: """
                    A rate from \(From.currency.code) to \(To.currency.code) can't hold "\(text)": \
                    it is too large, or has more decimal places than the rate can hold.
                    """
            )
        }

        // An exact positive quote is a positive rate, so the init can't fail here.
        guard case let .exact(stored) = exactness, let rate = Self(minorPerMinor: Rate(stored)) else {
            throw DecodingError.dataCorruptedError(
                forKey: .rate,
                in: container,
                debugDescription: """
                    A rate from \(From.currency.code) to \(To.currency.code) holds a quote to at \
                    most \(Fixed.fractionalDigits + Self.placesGained) decimal places, but read \
                    "\(text)". Round the quote to that many places before sending it.
                    """
            )
        }

        self = rate
    }
}

extension FX.ExchangeRate {
    /// The keys a rate's fields are written under.
    private enum CodingKeys: String, CodingKey {
        /// The code of the currency the rate converts from.
        case from

        /// The code of the currency the rate converts to.
        case to

        /// The market quote: `to` major units per one `from` major unit.
        case rate
    }

    /// The decimal places a quote gains when rescaled from major units to minor units: `To`'s
    /// places less `From`'s, from `-18` to `18`.
    private static var placesGained: Int {
        To.currency.unitScale.decimalPlaces - From.currency.unitScale.decimalPlaces
    }

    /// The market quote written out in full, with no trailing zeros.
    private var marketQuoteText: String {
        // The stored rate is a whole number of 10⁻¹⁸ minor-unit parts, and positive, so its digits
        // are the quote's with the point moved: `18 + placesGained` places in, `0...36`.
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

    /// Reads a currency code and checks that it is the one this type names.
    ///
    /// - Parameters:
    ///   - container: The container to read from.
    ///   - key: The field the code is under.
    ///   - expected: The code this type names for that field.
    /// - Throws: `DecodingError` if the field is missing, is not a code, or is a different code.
    private static func check(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys,
        holds expected: CurrencyCode
    ) throws {
        let text = try container.decode(String.self, forKey: key)

        guard CurrencyCode(string: text) == expected else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: """
                    Expected \(expected) but read "\(text)" in the "\(key.stringValue)" field. \
                    Decode into a rate between the currencies the payload names.
                    """
            )
        }
    }
}

#endif
