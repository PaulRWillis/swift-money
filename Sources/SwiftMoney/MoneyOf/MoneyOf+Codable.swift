extension MoneyOf: Codable {
    /// Writes the amount and its currency, as one string unless the encoder asks for otherwise.
    ///
    /// ```swift
    /// GBP(minorUnits: 4_99)                        // "GBP 499"
    /// Money(minorUnits: 499, currency: .jpy)       // "JPY 499"
    /// ```
    ///
    /// Give the encoder a ``MoneyCodingFormat`` to write a different shape.
    public func encode(to encoder: any Encoder) throws {
        switch encoder.moneyCodingFormat.shape {
        case let .codedString(units):
            var container = encoder.singleValueContainer()

            try container.encode(codedString(units))

        case let .fields(currencyKey, amountKey, amount):
            var container = encoder.container(keyedBy: MoneyCodingKey.self)

            try container.encode(currency.code, forKey: MoneyCodingKey(currencyKey))

            switch amount {
            case .number:
                try container.encode(minorUnits, forKey: MoneyCodingKey(amountKey))

            case let .string(units):
                try container.encode(amountText(units), forKey: MoneyCodingKey(amountKey))
            }
        }
    }

    /// Reads an amount, in any form this library writes.
    ///
    /// ```swift
    /// "GBP 499"                          // £4.99, into GBP or into Money
    /// "GBP 4.99"                         // £4.99, into GBP or into Money
    /// "499"                              // £4.99, into GBP only
    /// {"currency": "GBP", "amount": 499} // £4.99, into GBP or into Money
    /// {"amount": "4.99"}                 // £4.99, into GBP only
    /// ```
    ///
    /// The payload's own shape decides, so no format has to be set to read any of these. A `.`
    /// means major units and no `.` means the currency's smallest units. The currency may be left
    /// out only where the type names it, and must match where it is given. A format is needed only
    /// where the fields are under keys of an API's own choosing.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the string is not an amount this currency can
    ///   hold exactly.
    public init(from decoder: any Decoder) throws {
        // The payload's own shape decides, so nothing has to be configured to read either, and a
        // string is tried first because it is what this library writes unless told otherwise. The
        // format supplies only the keys, which nothing else could know.
        let container = try decoder.singleValueContainer()

        guard let text = try? container.decode(String.self) else {
            self = try Self.fromFields(decoder, keys: decoder.moneyCodingFormat.fieldKeys)

            return
        }

        do {
            self = try MoneyOf(codedString: text)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: Self.refusal(of: text, because: error)
            )
        }
    }

    private static func fromFields(
        _ decoder: any Decoder,
        keys: (currency: MoneyCodingKey, amount: MoneyCodingKey)
    ) throws -> MoneyOf {
        let container = try decoder.container(keyedBy: MoneyCodingKey.self)
        let code = try container.decodeIfPresent(CurrencyCode.self, forKey: keys.currency)

        guard let storage = C.storage(forCode: code) else {
            throw DecodingError.dataCorruptedError(
                forKey: keys.currency,
                in: container,
                debugDescription: Self.refusal(forCurrency: code, in: keys.currency.stringValue)
            )
        }

        let currency = C.currency(for: storage)

        if let text = try? container.decode(String.self, forKey: keys.amount) {
            guard let minorUnits = parsedMinorUnits(text, in: currency) else {
                throw DecodingError.dataCorruptedError(
                    forKey: keys.amount,
                    in: container,
                    debugDescription: Self.refusal(of: text, because: .inexactAmount(currency))
                )
            }

            return MoneyOf(unchecked: minorUnits, storage: storage)
        }

        // Decoded at the width an amount is stored in, so what fits is exactly what can be held and
        // anything larger is the coder's own error rather than a check written here.
        return MoneyOf(
            unchecked: try container.decode(MinorUnits.self, forKey: keys.amount),
            storage: storage
        )
    }

    // The currency every amount of this type is in, where its representation fixes one.
    private static var impliedCurrency: Currency? {
        C.storage(forCode: nil).map(C.currency(for:))
    }

    // Three failures with three remedies. A currency that cannot be resolved is nothing like an
    // amount written too finely, and telling a caller to write fewer decimals when their currency
    // is the problem sends them the wrong way.
    private static func refusal(
        of text: String,
        because error: CodedStringError
    ) -> String {
        switch error {
        case .unnamedCurrency:
            return "\(refusal(forCurrency: nil, in: nil)) Read in \"\(text)\", where \"GBP 499\" would do."

        case let .unresolvedCurrency(code):
            return "\(refusal(forCurrency: code, in: nil)) Read in \"\(text)\"."

        case let .inexactAmount(currency):
            return """
                Not an amount \(currency.code) can hold exactly: "\(text)". \
                Write it to the precision \(currency.code) divides into, as in "499" or "4.99".
                """
        }
    }

    // Shared by both shapes, since a currency is unusable for the same reasons whether it was read
    // from a field or from the front of a string. `field` names where to look when there was one.
    private static func refusal(
        forCurrency code: CurrencyCode?,
        in field: String?
    ) -> String {
        let place = field.map { " in the \"\($0)\" field" } ?? ""

        guard let code else {
            return """
                No currency named\(place), and this amount can only take one from what it reads. \
                Name the currency, or decode into a type that names it.
                """
        }

        guard let implied = impliedCurrency else {
            return """
                Unknown currency code "\(code)"\(place). Decode into a type that names the currency, \
                or read the code and the amount separately and use Money(string:currency:).
                """
        }

        return """
            Expected \(implied.code) but read "\(code)"\(place). \
            Leave the currency out, or name the one this type holds.
            """
    }
}
