// MARK: - Codable

extension DistributionParts: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let n = try container.decode(Int.self)
        guard n >= 1 else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "DistributionParts must be at least 1 (decoded \(n))"
            )
        }
        _value = n
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_value)
    }
}
