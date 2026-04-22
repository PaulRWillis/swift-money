extension AnyMoney: Codable {
    private enum CodingKeys: String, CodingKey {
        case minorUnits
        case currencyCode
        case minimalQuantisation
    }

    /// Encodes this value into the given encoder.
    ///
    /// Encodes the three scalar fields — ``minorUnits``, ``currencyCode``, and
    /// ``minimalQuantisation`` — as a keyed container. The ``currency`` metatype is
    /// not encoded; it is a runtime-only convenience.
    ///
    /// Example JSON output:
    /// ```json
    /// { "currencyCode": "GBP", "minimalQuantisation": 100, "minorUnits": 500 }
    /// ```
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minorUnits, forKey: .minorUnits)
        try container.encode(currencyCode.stringValue, forKey: .currencyCode)
        try container.encode(minimalQuantisation.int64Value, forKey: .minimalQuantisation)
    }

    /// Creates an `AnyMoney` by decoding from the given decoder.
    ///
    /// Decodes ``minorUnits``, ``currencyCode``, and ``minimalQuantisation`` from a
    /// keyed container. The ``currency`` metatype will be `nil` on the decoded
    /// value — only the scalar fields are persisted.
    ///
    /// To recover a typed value after decoding, use ``asMoney(_:)``:
    ///
    /// ```swift
    /// let decoded = try JSONDecoder().decode(AnyMoney.self, from: data)
    /// let typed: Money<GBP>? = decoded.asMoney(GBP.self)
    /// ```
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let minorUnits = try container.decode(Int64.self, forKey: .minorUnits)
        let currencyCodeString = try container.decode(String.self, forKey: .currencyCode)
        let quantisationInt = try container.decode(Int64.self, forKey: .minimalQuantisation)
        guard !currencyCodeString.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .currencyCode,
                in: container,
                debugDescription: "AnyMoney currencyCode cannot be empty"
            )
        }
        guard quantisationInt > 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .minimalQuantisation,
                in: container,
                debugDescription: "AnyMoney minimalQuantisation must be > 0 (decoded \(quantisationInt))"
            )
        }
        self.init(
            minorUnits: minorUnits,
            currencyCode: CurrencyCode(currencyCodeString),
            minimalQuantisation: MinimalQuantisation(quantisationInt)
        )
    }
}
