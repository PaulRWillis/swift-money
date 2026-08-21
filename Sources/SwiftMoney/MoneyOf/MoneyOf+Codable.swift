extension MoneyOf: Codable {
    /// Writes the amount and its currency as one string.
    ///
    /// ```swift
    /// GBP(minorUnits: 4_99)                        // "GBP 499"
    /// Money(minorUnits: 499, currency: .jpy)       // "JPY 499"
    /// ```
    ///
    /// Give the encoder a ``MoneyCodingFormat`` to write a different shape.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch encoder.moneyCodingFormat.shape {
        case let .codedString(units):
            try container.encode(codedString(units))
        }
    }

    /// Reads an amount from a string, in any form this library writes.
    ///
    /// ```swift
    /// "GBP 499"    // £4.99, into GBP or into Money
    /// "GBP 4.99"   // £4.99, into GBP or into Money
    /// "499"        // £4.99, into GBP only
    /// "4.99"       // £4.99, into GBP only
    /// ```
    ///
    /// A `.` means major units and no `.` means the currency's smallest units, so no format has to
    /// be set to read either. The code may be left out only where the type names the currency, and
    /// must match where it is given.
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

    // The currency every amount of this type is in, where its representation fixes one.
    private static var impliedCurrency: Currency? {
        C.storage(forCode: nil).map(C.currency(for:))
    }

    private static func refusal(for text: String) -> String {
        guard let implied = impliedCurrency else {
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
