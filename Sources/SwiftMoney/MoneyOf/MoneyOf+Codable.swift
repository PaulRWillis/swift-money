extension MoneyOf: Codable {
    /// Writes the amount and its currency as one string.
    ///
    /// ```swift
    /// try JSONEncoder().encode(GBP(minorUnits: 4_99))   // "GBP 499"
    /// ```
    ///
    /// Set ``CodingUserInfoKey/moneyCodingFormat`` on the encoder to write another shape.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch encoder.moneyCodingFormat.shape {
        case let .codedString(units):
            try container.encode(codedString(units))
        }
    }

    /// Reads an amount from a string.
    ///
    /// ```swift
    /// try JSONDecoder().decode(GBP.self, from: Data(#""GBP 499""#.utf8))    // £4.99
    /// try JSONDecoder().decode(GBP.self, from: Data(#""4.99""#.utf8))       // £4.99
    /// try JSONDecoder().decode(Money.self, from: Data(#""GBP 4.99""#.utf8)) // £4.99
    /// ```
    ///
    /// Either spelling is read whatever the encoder was told to write. A `.` means major units and
    /// no `.` means the currency's smallest units. The code may be left out only where the type
    /// names the currency, and must match where it is given.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the string is not an amount this currency can
    ///   hold exactly.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)

        guard let amount = MoneyOf(codedString: text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: Self.refusal(for: text)
            )
        }

        self = amount
    }

    // The currency comes from the type where it names one, and from the string where it does not.
    init?(codedString text: String) {
        if let implied = C.impliedCurrency {
            guard let minorUnits = parsedMinorUnits(text, in: implied),
                  let storage = C.storage(for: implied)
            else {
                return nil
            }

            self.init(unchecked: minorUnits, storage: storage)
        } else {
            guard let parsed = parsedISOAmount(text),
                  let storage = C.storage(for: parsed.currency)
            else {
                return nil
            }

            self.init(unchecked: parsed.minorUnits, storage: storage)
        }
    }

    static func refusal(for text: String) -> String {
        guard let implied = C.impliedCurrency else {
            return """
                Not an amount an ISO 4217 currency can hold exactly: "\(text)". \
                Write the code and the amount, as in "GBP 499" or "GBP 4.99".
                """
        }

        return """
            Not an amount \(implied.code) can hold exactly: "\(text)". \
            Write "499" or "4.99", or name the currency, as in "\(implied.code) 4.99".
            """
    }
}
