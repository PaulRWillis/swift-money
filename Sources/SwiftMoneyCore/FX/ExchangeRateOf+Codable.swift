#if !hasFeature(Embedded)

extension FX.ExchangeRateOf: Codable {
    /// Writes the rate as its two currency codes and its market quote.
    ///
    /// The quote is `To` major units per one `From` major unit, as a decimal string carrying every
    /// digit the rate holds, so it reads back unchanged.
    ///
    /// ```swift
    /// let eurGbp = FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.87")!
    /// try encoder.encode(eurGbp)   // {"from":"EUR","rate":"0.87","to":"GBP"}
    /// ```
    ///
    /// - Parameter encoder: The encoder to write to.
    /// - Throws: Only what `encoder` throws.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(String(From.currency.code), forKey: .from)
        try container.encode(String(To.currency.code), forKey: .to)
        try container.encode(description, forKey: .rate)
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

        do {
            self = try Self(string: text)
        } catch {
            throw DecodingError.dataCorruptedError(
                forKey: .rate,
                in: container,
                debugDescription: Self.refusal(of: text, because: error)
            )
        }
    }
}

extension FX.ExchangeRateOf {
    /// The keys a rate's fields are written under.
    private enum CodingKeys: String, CodingKey {
        /// The code of the currency the rate converts from.
        case from

        /// The code of the currency the rate converts to.
        case to

        /// The market quote: `to` major units per one `from` major unit.
        case rate
    }

    /// Returns why a quote read from the wire is refused, and how to fix it.
    ///
    /// - Parameters:
    ///   - text: The quote as it was read.
    ///   - error: Why it isn't a rate.
    /// - Returns: What was wrong with the quote, and what to send instead.
    private static func refusal(of text: String, because error: FX.ExchangeRateParsingError) -> String {
        let pair = "\(From.currency.code) to \(To.currency.code)"

        switch error {
        case .unrecognizedText:
            return """
                Not a market quote: "\(text)" in the "\(CodingKeys.rate.stringValue)" field. \
                Write the rate as a decimal string, as in "0.87".
                """

        case .notPositive:
            return "A rate from \(pair) must be greater than zero, but read \"\(text)\"."

        case let .inexactRate(maximumFractionDigits):
            return """
                A rate from \(pair) holds a quote to at most \(maximumFractionDigits) decimal \
                places, but read "\(text)". Round the quote to that many places before sending it.
                """

        case .overflow:
            return "A rate from \(pair) can't hold \"\(text)\": it is too large."
        }
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
