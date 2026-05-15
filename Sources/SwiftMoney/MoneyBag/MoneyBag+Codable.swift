#if canImport(Foundation)
import Foundation

extension MoneyBag: Codable {

    // MARK: Coding key for .full (wrapped entries array)

    private enum EntriesKey: String, CodingKey {
        case entries
    }

    // MARK: Encoding

    /// Encodes this ``MoneyBag`` using the strategy configured on the encoder.
    ///
    /// The active strategy is read from `encoder.userInfo[.moneyBagEncodingStrategy]`
    /// (set via ``JSONEncoder/moneyBagEncodingStrategy``). Defaults to
    /// ``MoneyBagEncodingStrategy/full`` when not set.
    ///
    /// Entries are always output in ascending currency-code order for determinism.
    ///
    /// - SeeAlso: ``JSONEncoder/moneyBagEncodingStrategy``
    public func encode(to encoder: any Encoder) throws {
        let strategy = encoder.userInfo[.moneyBagEncodingStrategy] as? MoneyBagEncodingStrategy ?? .full
        let sorted = _storage.values.sorted()
        switch strategy {

        case .full:
            // {"entries": [...full AnyMoney objects...]}
            // Each entry is encoded in AnyMoney.full format regardless of any
            // anyMoneyEncodingStrategy set on the outer encoder.
            var outer = encoder.container(keyedBy: EntriesKey.self)
            var array = outer.nestedUnkeyedContainer(forKey: .entries)
            for entry in sorted {
                let entryEncoder = array.superEncoder()
                try entry._encode(strategy: .full, to: entryEncoder)
            }

        case .array(let entryStrategy):
            // [...per-entry AnyMoney objects...]
            var array = encoder.unkeyedContainer()
            for entry in sorted {
                let entryEncoder = array.superEncoder()
                try entry._encode(strategy: entryStrategy, to: entryEncoder)
            }

        case .dictionary(let amountStrategy):
            // {"GBP": 1.25, "JPY": 500, ...}
            var dictionaryContainer = encoder.container(keyedBy: _StringCodingKey.self)
            for entry in sorted {
                let key = _StringCodingKey(stringValue: entry.currencyCode.stringValue)
                switch amountStrategy {
                case .minorUnits:
                    try dictionaryContainer.encode(entry.minorUnits, forKey: key)
                case .majorUnits:
                    try dictionaryContainer.encode(entry.decimalValue, forKey: key)
                case .string(let locale):
                    try dictionaryContainer.encode(entry.formatted(AnyMoney.FormatStyle().locale(locale)), forKey: key)
                }
            }
        }
    }

    // MARK: Decoding

    /// Creates a ``MoneyBag`` by decoding from the given decoder.
    ///
    /// The active strategy is read from `decoder.userInfo[.moneyBagDecodingStrategy]`
    /// (set via ``JSONDecoder/moneyBagDecodingStrategy``). Defaults to
    /// ``MoneyBagDecodingStrategy/full`` when not set.
    ///
    /// Duplicate currency codes in the decoded payload are rejected with
    /// `DecodingError.dataCorrupted`.
    ///
    /// - SeeAlso: ``JSONDecoder/moneyBagDecodingStrategy``
    public init(from decoder: any Decoder) throws {
        let strategy = decoder.userInfo[.moneyBagDecodingStrategy] as? MoneyBagDecodingStrategy ?? .full
        switch strategy {

        case .full:
            // {"entries": [...full AnyMoney objects...]}
            // Each entry is decoded in AnyMoney.full format regardless of any
            // anyMoneyDecodingStrategy set on the outer decoder.
            let outer = try decoder.container(keyedBy: EntriesKey.self)
            var array = try outer.nestedUnkeyedContainer(forKey: .entries)
            var entries: [AnyMoney] = []
            while !array.isAtEnd {
                let entryDecoder = try array.superDecoder()
                entries.append(try AnyMoney._decode(strategy: .full, from: entryDecoder))
            }
            self._storage = try MoneyBag._buildStorage(from: entries, codingPath: decoder.codingPath)

        case .array(let entryStrategy):
            // [...per-entry AnyMoney objects...]
            var array = try decoder.unkeyedContainer()
            var entries: [AnyMoney] = []
            while !array.isAtEnd {
                let entryDecoder = try array.superDecoder()
                entries.append(try AnyMoney._decode(strategy: entryStrategy, from: entryDecoder))
            }
            self._storage = try MoneyBag._buildStorage(from: entries, codingPath: decoder.codingPath)

        case .dictionary(let amountStrategy, let resolver):
            // {"GBP": 1.25, "JPY": 500, ...}
            self._storage = try MoneyBag._decodeDictionary(
                amountStrategy: amountStrategy,
                resolver: resolver,
                from: decoder
            )
        }
    }

    // MARK: Private helpers

    /// Builds `_storage` from a decoded array of entries, rejecting duplicate currency codes.
    private static func _buildStorage(
        from entries: [AnyMoney],
        codingPath: [any CodingKey]
    ) throws -> [CurrencyCode: AnyMoney] {
        var storage: [CurrencyCode: AnyMoney] = [:]
        storage.reserveCapacity(entries.count)
        for entry in entries {
            let isNewCurrency = storage[entry.currencyCode] == nil
            guard isNewCurrency else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: codingPath,
                        debugDescription: "Duplicate currency code '\(entry.currencyCode)' in MoneyBag entries."
                    )
                )
            }
            storage[entry.currencyCode] = entry
        }
        return storage
    }

    /// Decodes a `{"GBP": ..., "JPY": ...}` dictionary into storage,
    /// resolving each currency code's `MinimalQuantisation` via the provided closure.
    private static func _decodeDictionary(
        amountStrategy: MoneyAmountDecodingStrategy,
        resolver: @Sendable (CurrencyCode) -> MinimalQuantisation?,
        from decoder: any Decoder
    ) throws -> [CurrencyCode: AnyMoney] {
        let container = try decoder.container(keyedBy: _StringCodingKey.self)
        var storage: [CurrencyCode: AnyMoney] = [:]
        for key in container.allKeys {
            let currencyCode = CurrencyCode(key.stringValue)
            guard let minimalQuantisation = resolver(currencyCode) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "No MinimalQuantisation found for currency '\(currencyCode)'. Provide a resolver that covers this currency."
                    )
                )
            }
            let isNewCurrency = storage[currencyCode] == nil
            guard isNewCurrency else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Duplicate currency code '\(currencyCode)' in MoneyBag dictionary."
                    )
                )
            }
            let minorUnits: Int64
            switch amountStrategy {
            case .minorUnits:
                minorUnits = try container.decode(Int64.self, forKey: key)
            case .majorUnits:
                let decimal = try container.decode(Decimal.self, forKey: key)
                minorUnits = try AnyMoney._decimalToMinorUnits(
                    decimal, minimalQuantisation: minimalQuantisation, codingPath: container.codingPath
                )
            case .string(let locale):
                let string = try container.decode(String.self, forKey: key)
                let decimal = try AnyMoney._parseFormattedAmount(
                    string, currencyCode: currencyCode, locale: locale, codingPath: container.codingPath
                )
                minorUnits = try AnyMoney._decimalToMinorUnits(
                    decimal, minimalQuantisation: minimalQuantisation, codingPath: container.codingPath
                )
            }
            storage[currencyCode] = AnyMoney(
                minorUnits: minorUnits,
                currencyCode: currencyCode,
                minimalQuantisation: minimalQuantisation
            )
        }
        return storage
    }
}

// MARK: - Dynamic string CodingKey (used by .dictionary strategy)

private struct _StringCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}
#endif
