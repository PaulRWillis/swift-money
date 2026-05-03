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
                    guard !entry.isNaN else {
                        throw EncodingError.invalidValue(
                            entry,
                            EncodingError.Context(
                                codingPath: encoder.codingPath,
                                debugDescription: "NaN AnyMoney cannot be encoded using .dictionary(amount: .majorUnits). Use .full or .minorUnits to preserve NaN."
                            )
                        )
                    }
                    try dictionaryContainer.encode(entry.decimalValue, forKey: key)
                case .string(let locale):
                    guard !entry.isNaN else {
                        throw EncodingError.invalidValue(
                            entry,
                            EncodingError.Context(
                                codingPath: encoder.codingPath,
                                debugDescription: "NaN AnyMoney cannot be encoded using .dictionary(amount: .string). Use .full or .minorUnits to preserve NaN."
                            )
                        )
                    }
                    try dictionaryContainer.encode(entry.formatted(AnyMoney.FormatStyle(locale: locale)), forKey: key)
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
            let dictionaryContainer = try decoder.container(keyedBy: _StringCodingKey.self)
            var storage: [CurrencyCode: AnyMoney] = [:]
            for key in dictionaryContainer.allKeys {
                let code = CurrencyCode(key.stringValue)
                guard let minimalQuantisation = resolver(code) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: dictionaryContainer.codingPath,
                            debugDescription: "No MinimalQuantisation found for currency '\(code)'. Provide a resolver that covers this currency."
                        )
                    )
                }
                let isNewCurrency = storage[code] == nil
                guard isNewCurrency else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: dictionaryContainer.codingPath,
                            debugDescription: "Duplicate currency code '\(code)' in MoneyBag dictionary."
                        )
                    )
                }
                let minorUnits: Int64
                switch amountStrategy {
                case .minorUnits:
                    minorUnits = try dictionaryContainer.decode(Int64.self, forKey: key)
                case .majorUnits:
                    let decimal = try dictionaryContainer.decode(Decimal.self, forKey: key)
                    minorUnits = try AnyMoney._decimalToMinorUnits(
                        decimal, minQ: minimalQuantisation, codingPath: dictionaryContainer.codingPath
                    )
                case .string(let locale):
                    let string = try dictionaryContainer.decode(String.self, forKey: key)
                    let decimal = try AnyMoney._parseFormattedAmount(
                        string, currencyCode: code, locale: locale, codingPath: dictionaryContainer.codingPath
                    )
                    minorUnits = try AnyMoney._decimalToMinorUnits(
                        decimal, minQ: minimalQuantisation, codingPath: dictionaryContainer.codingPath
                    )
                }
                storage[code] = AnyMoney(
                    minorUnits: minorUnits,
                    currencyCode: code,
                    minimalQuantisation: minimalQuantisation
                )
            }
            self._storage = storage
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
}

// MARK: - Dynamic string CodingKey (used by .dictionary strategy)

private struct _StringCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}
#endif
