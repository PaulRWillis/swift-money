#if !hasFeature(Embedded)

extension FX.ExchangeRateOf: Codable {
    /// Writes the rate as its two currency codes and its market quote.
    ///
    /// The quote is `To` major units per one `From` major unit, as a decimal string carrying every
    /// digit the rate holds, so it reads back unchanged. A currency the ISO table doesn't ship is
    /// written with its scale too, so a runtime rate can read it back, whichever form wrote it.
    ///
    /// ```swift
    /// let eurGbp = FX.ExchangeRate("0.87", from: .eur, to: .gbp)!
    /// try encoder.encode(eurGbp)   // {"from":"EUR","rate":"0.87","to":"GBP"}
    /// let ether = Currency(code: "ETH", unitScale: 1_000_000_000_000_000_000)!
    /// let ethGbp = FX.ExchangeRate("3200.12", from: ether, to: .gbp)!
    /// try encoder.encode(ethGbp)   // {"from":"ETH","fromScale":18,"rate":"3200.12","to":"GBP"}
    /// ```
    ///
    /// - Parameter encoder: The encoder to write to.
    /// - Throws: Only what `encoder` throws.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: FX.ExchangeRateCodingKey.self)
        let from = from
        let to = to

        try FX.encodeCurrency(from, codeKey: .from, scaleKey: .fromScale, in: &container)
        try FX.encodeCurrency(to, codeKey: .to, scaleKey: .toScale, in: &container)
        try container.encode(
            FX.quoteText(of: minorPerMinorRate, placesGained: FX.placesGained(from: from, to: to)),
            forKey: .rate
        )
    }

    /// Reads a rate written as its two currency codes, their scales where needed, and its market
    /// quote.
    ///
    /// A code alone names a currency the ISO table ships. A code and a scale name any currency, and
    /// a shipped code must come with its own scale. A typed rate reads only its own currencies. The
    /// quote is a positive decimal string the rate can hold exactly: it is never rounded.
    ///
    /// ```swift
    /// {"from": "EUR", "to": "GBP", "rate": "0.87"}                    // €1 = £0.87
    /// {"from": "ETH", "fromScale": 18, "to": "GBP", "rate": "3200"}   // 1 ETH = £3,200, runtime only
    /// {"from": "EUR", "fromScale": 3, "to": "GBP", "rate": "0.87"}    // refused: EUR has 2 places
    /// {"from": "EUR", "to": "GBP", "rate": "0.8765262907123456789"}   // refused: too many places
    /// ```
    ///
    /// - Parameter decoder: The decoder to read from.
    /// - Throws: `DecodingError` if a code is missing, unknown without a scale, or not one this type
    ///   holds; if a scale is outside `0` to `18` or not the scale of a currency the code names; or if
    ///   the quote is missing or not a positive decimal the rate can hold exactly.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: FX.ExchangeRateCodingKey.self)
        let fromStorage = try FX.decodedStorage(From.self, in: container, codeKey: .from, scaleKey: .fromScale)
        let toStorage = try FX.decodedStorage(To.self, in: container, codeKey: .to, scaleKey: .toScale)
        let text = try container.decode(String.self, forKey: .rate)

        do {
            self = try Self(quote: text, fromStorage: fromStorage, toStorage: toStorage)
        } catch {
            throw DecodingError.dataCorruptedError(
                forKey: .rate,
                in: container,
                debugDescription: FX.refusal(
                    of: text,
                    from: From.currency(for: fromStorage),
                    to: To.currency(for: toStorage),
                    because: error
                )
            )
        }
    }
}

extension FX {
    /// The keys a rate's fields are written under.
    fileprivate enum ExchangeRateCodingKey: String, CodingKey {
        /// The code of the currency the rate converts from.
        case from

        /// The scale of the currency the rate converts from, where its code alone doesn't name it.
        case fromScale

        /// The code of the currency the rate converts to.
        case to

        /// The scale of the currency the rate converts to, where its code alone doesn't name it.
        case toScale

        /// The market quote: `to` major units per one `from` major unit.
        case rate
    }

    /// Writes one side's currency: its code, and its scale where the ISO table can't rebuild it from
    /// the code alone.
    ///
    /// - Parameters:
    ///   - currency: The currency to write.
    ///   - codeKey: The field its code goes under.
    ///   - scaleKey: The field its scale goes under.
    ///   - container: The container to write to.
    /// - Throws: Only what `container` throws.
    fileprivate static func encodeCurrency(
        _ currency: Currency,
        codeKey: ExchangeRateCodingKey,
        scaleKey: ExchangeRateCodingKey,
        in container: inout KeyedEncodingContainer<ExchangeRateCodingKey>
    ) throws {
        try container.encode(String(currency.code), forKey: codeKey)

        if Currency(iso: currency.code) != currency {
            try container.encode(currency.unitScale.decimalPlaces, forKey: scaleKey)
        }
    }

    /// Reads one side's currency and returns what a rate carries for it.
    ///
    /// - Parameters:
    ///   - representation: How the rate knows this side's currency.
    ///   - container: The container to read from.
    ///   - codeKey: The field the code is under.
    ///   - scaleKey: The field the scale is under, if there is one.
    /// - Returns: The storage for the currency the fields name.
    /// - Throws: `DecodingError` if the code is missing or isn't one `representation` can be, or the
    ///   scale is outside `0` to `18` or isn't the scale of a currency the code names.
    fileprivate static func decodedStorage<R: CurrencyRepresentation>(
        _ representation: R.Type,
        in container: KeyedDecodingContainer<ExchangeRateCodingKey>,
        codeKey: ExchangeRateCodingKey,
        scaleKey: ExchangeRateCodingKey
    ) throws -> R.Storage {
        let text = try container.decode(String.self, forKey: codeKey)
        // A lookup and a read only where the scale is there: `decodeIfPresent` costs more when it isn't.
        let rawScale = container.contains(scaleKey) ? try container.decode(Int.self, forKey: scaleKey) : nil
        let code = CurrencyCode(string: text)

        if let rawScale {
            guard let scale = UnitScale(decimalPlaces: rawScale) else {
                throw DecodingError.dataCorruptedError(
                    forKey: scaleKey,
                    in: container,
                    debugDescription: refusal(ofScale: rawScale, in: scaleKey)
                )
            }

            if let code, let expected = R.currency(resolvedFromCodeAlone: code), scale != expected.unitScale {
                throw DecodingError.dataCorruptedError(
                    forKey: scaleKey,
                    in: container,
                    debugDescription: refusal(ofScale: rawScale, for: expected, in: scaleKey)
                )
            }
        }

        guard let code, let storage = R.storage(for: CurrencyField(code: code, rawScale: rawScale)) else {
            throw DecodingError.dataCorruptedError(
                forKey: codeKey,
                in: container,
                debugDescription: refusal(
                    ofCode: text,
                    in: codeKey,
                    scaleKey: scaleKey,
                    implied: R.storage(forCode: nil).map(R.currency(for:))
                )
            )
        }

        return storage
    }

    /// Returns why a currency code read from the wire is refused, and how to fix it.
    ///
    /// - Parameters:
    ///   - text: The code as it was read.
    ///   - codeKey: The field it was read from.
    ///   - scaleKey: The field a scale for it would be read from.
    ///   - implied: The currency the rate's type holds on this side, or `nil` for a runtime rate.
    /// - Returns: What was wrong with the code, and what to send instead.
    fileprivate static func refusal(
        ofCode text: String,
        in codeKey: ExchangeRateCodingKey,
        scaleKey: ExchangeRateCodingKey,
        implied: Currency?
    ) -> String {
        guard let implied else {
            return """
                Unknown currency code "\(text)" in the "\(codeKey.stringValue)" field. Write the \
                currency's scale in the "\(scaleKey.stringValue)" field too, or decode into a typed \
                rate that names the currency.
                """
        }

        return """
            Expected \(implied.code) but read "\(text)" in the "\(codeKey.stringValue)" field. \
            Decode into a rate between the currencies the payload names.
            """
    }

    /// Returns why a scale outside the range a currency can have is refused.
    ///
    /// - Parameters:
    ///   - rawScale: The scale as it was read.
    ///   - scaleKey: The field it was read from.
    /// - Returns: What was wrong with the scale.
    fileprivate static func refusal(ofScale rawScale: Int, in scaleKey: ExchangeRateCodingKey) -> String {
        """
        A scale is from 0 to \(UnitScale.maxDecimalPlaces) decimal places, but read \(rawScale) in \
        the "\(scaleKey.stringValue)" field.
        """
    }

    /// Returns why a scale that isn't the scale of the currency its code names is refused.
    ///
    /// - Parameters:
    ///   - rawScale: The scale as it was read.
    ///   - currency: The currency the code names.
    ///   - scaleKey: The field the scale was read from.
    /// - Returns: What was wrong with the scale, and how to fix it.
    fileprivate static func refusal(ofScale rawScale: Int, for currency: Currency, in scaleKey: ExchangeRateCodingKey) -> String {
        """
        Expected \(currency.code) with a scale of \(currency.unitScale.decimalPlaces) but read \
        \(rawScale) in the "\(scaleKey.stringValue)" field. \
        Leave the scale out, or write the one \(currency.code) has.
        """
    }

    /// Returns why a quote read from the wire is refused, and how to fix it.
    ///
    /// - Parameters:
    ///   - text: The quote as it was read.
    ///   - from: The currency the rate converts from.
    ///   - to: The currency the rate converts to.
    ///   - error: Why it isn't a rate.
    /// - Returns: What was wrong with the quote, and what to send instead.
    fileprivate static func refusal(
        of text: String,
        from: Currency,
        to: Currency,
        because error: FX.ExchangeRateParsingError
    ) -> String {
        let pair = "\(from.code) to \(to.code)"

        switch error {
        case .unrecognizedText:
            return """
                Not a market quote: "\(text)" in the "\(ExchangeRateCodingKey.rate.stringValue)" field. \
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
}

#endif
