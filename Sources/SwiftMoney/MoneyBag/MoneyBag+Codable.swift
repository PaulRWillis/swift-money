import Foundation

extension MoneyBag: Codable {
    private enum CodingKeys: String, CodingKey {
        case entries
    }

    /// Encodes this bag into the given encoder.
    ///
    /// The bag is encoded as a keyed object with a single `entries` array
    /// containing each accumulated `AnyMoney` value. The order of entries in
    /// the `entries` array is sorted by currency code for determinism.
    ///
    /// Example JSON output for a two-currency bag:
    /// ```json
    /// {
    ///   "entries": [
    ///     { "currencyCode": "EUR", "minimalQuantisation": 100, "minorUnits": 1000 },
    ///     { "currencyCode": "GBP", "minimalQuantisation": 100, "minorUnits": 500 }
    ///   ]
    /// }
    /// ```
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode in sorted order so output is deterministic.
        try container.encode(_storage.values.sorted(), forKey: .entries)
    }

    /// Creates a `MoneyBag` by decoding from the given decoder.
    ///
    /// Decodes the `entries` array and reconstructs `_storage`. Each entry's
    /// `currencyCode` must be unique; duplicate currency codes in the encoded
    /// payload are treated as corrupt data and cause a `DecodingError` to be
    /// thrown.
    ///
    /// The `currency` metatype on each entry will be `nil` after decoding —
    /// only the scalar fields are persisted. Use `amount(in:)` to
    /// retrieve typed `Money<C>` values.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let entries = try container.decode([AnyMoney].self, forKey: .entries)

        var storage: [CurrencyCode: AnyMoney] = [:]
        storage.reserveCapacity(entries.count)
        for entry in entries {
            guard storage[entry.currencyCode] == nil else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath + [CodingKeys.entries],
                        debugDescription: "Duplicate currency code '\(String(entry.currencyCode))' in MoneyBag entries."
                    )
                )
            }
            storage[entry.currencyCode] = entry
        }
        self._storage = storage
    }
}
