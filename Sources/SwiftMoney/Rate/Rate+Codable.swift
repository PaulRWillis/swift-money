// MARK: - Codable

extension Rate: Codable {
    private enum CodingKeys: String, CodingKey {
        case numerator
        case denominator
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let numerator = try container.decode(Int64.self, forKey: .numerator)
        let denominator = try container.decode(Int64.self, forKey: .denominator)
        guard denominator > 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .denominator,
                in: container,
                debugDescription: "Rate denominator must be > 0 (decoded \(denominator))"
            )
        }
        guard numerator != .min else {
            throw DecodingError.dataCorruptedError(
                forKey: .numerator,
                in: container,
                debugDescription: "Rate numerator must not be Int64.min"
            )
        }
        self.init(_unchecked: numerator, denominator: denominator)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_numerator, forKey: .numerator)
        try container.encode(_denominator, forKey: .denominator)
    }
}
