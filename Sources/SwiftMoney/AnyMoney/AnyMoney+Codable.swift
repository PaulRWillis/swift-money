import Foundation

extension AnyMoney: Codable {
    private enum CodingKeys: String, CodingKey {
        case minorUnits
        case currencyCode
        case minorUnitRatio
    }

    /// Encodes this value into the given encoder.
    ///
    /// Encodes the three scalar fields — ``minorUnits``, ``currencyCode``, and
    /// ``minorUnitRatio`` — as a keyed container. The ``currency`` metatype is
    /// not encoded; it is a runtime-only convenience.
    ///
    /// Example JSON output:
    /// ```json
    /// { "minorUnits": 500, "currencyCode": "GBP", "minorUnitRatio": 100 }
    /// ```
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minorUnits, forKey: .minorUnits)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(minorUnitRatio, forKey: .minorUnitRatio)
    }

    /// Creates an `AnyMoney` by decoding from the given decoder.
    ///
    /// Decodes ``minorUnits``, ``currencyCode``, and ``minorUnitRatio`` from a
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
        let currencyCode = try container.decode(String.self, forKey: .currencyCode)
        let minorUnitRatio = try container.decode(Int64.self, forKey: .minorUnitRatio)
        self.init(minorUnits: minorUnits, currencyCode: currencyCode, minorUnitRatio: minorUnitRatio)
    }
}
