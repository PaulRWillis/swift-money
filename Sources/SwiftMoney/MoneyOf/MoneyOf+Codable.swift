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

        do {
            self = try MoneyOf(codedString: text)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: Self.refusal(of: text, because: error)
            )
        }
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
            return """
                No currency named in "\(text)", and this amount can only take one from what it \
                reads. Write the code with the amount, as in "GBP 499", or decode into a type that \
                names the currency.
                """

        case let .unresolvedCurrency(code):
            guard let implied = impliedCurrency else {
                return """
                    Unknown currency code "\(code)" in "\(text)". Decode into a type that names the \
                    currency, or read the code and the amount separately and use \
                    Money(string:currency:).
                    """
            }

            return """
                Expected \(implied.code) but read "\(code)" in "\(text)". \
                Leave the code out, or write the one this type names.
                """

        case let .inexactAmount(currency):
            return """
                Not an amount \(currency.code) can hold exactly: "\(text)". \
                Write it to the precision \(currency.code) divides into, as in "499" or "4.99".
                """
        }
    }
}
