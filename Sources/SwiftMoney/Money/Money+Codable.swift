#if canImport(Foundation)
import Foundation

// MARK: - Codable

extension Money: Codable {

    // MARK: Private coding key

    private enum CodingKey: String, Swift.CodingKey {
        case currencyCode
        case amount
    }

    // MARK: - Encoding

    /// Encodes this `Money` value using the strategy configured on the encoder.
    ///
    /// The active strategy is read from `encoder.userInfo[.moneyEncodingStrategy]`
    /// (set via ``JSONEncoder/moneyEncodingStrategy``). When no strategy is
    /// configured, ``MoneyEncodingStrategy/object`` is used, producing:
    ///
    /// ```json
    /// {"currencyCode":"GBP","amount":1.25}
    /// ```
    ///
    /// Only ``MoneyEncodingStrategy/minorUnits`` preserves ``Money/nan``;
    /// all other strategies throw `EncodingError.invalidValue` for NaN values.
    ///
    /// - SeeAlso: ``JSONEncoder/moneyEncodingStrategy``
    public func encode(to encoder: any Encoder) throws {
        let strategy = encoder.userInfo[.moneyEncodingStrategy] as? MoneyEncodingStrategy ?? .object
        switch strategy {
        case .minorUnits:
            try _encodeMinorUnits(to: encoder)
        case .majorUnits:
            try _encodeMajorUnits(to: encoder)
        case .string(let locale):
            try _encodeString(locale: locale, to: encoder)
        case .object(let amountStrategy):
            try _encodeObject(amountStrategy: amountStrategy, to: encoder)
        }
    }

    // MARK: - Decoding

    /// Creates a `Money` by decoding from the given decoder.
    ///
    /// The active strategy is read from `decoder.userInfo[.moneyDecodingStrategy]`
    /// (set via ``JSONDecoder/moneyDecodingStrategy``). When no strategy is
    /// configured, ``MoneyDecodingStrategy/object`` is used, expecting:
    ///
    /// ```json
    /// {"currencyCode":"GBP","amount":1.25}
    /// ```
    ///
    /// The decoding strategy **must** match the encoding strategy that produced
    /// the data, or a `DecodingError` will be thrown.
    ///
    /// - SeeAlso: ``JSONDecoder/moneyDecodingStrategy``
    public init(from decoder: any Decoder) throws {
        let strategy = decoder.userInfo[.moneyDecodingStrategy] as? MoneyDecodingStrategy ?? .object
        switch strategy {
        case .minorUnits:
            self = try Money._decodeMinorUnits(from: decoder)
        case .majorUnits:
            self = try Money._decodeMajorUnits(from: decoder)
        case .string(let locale):
            self = try Money._decodeString(locale: locale, from: decoder)
        case .object(let amountStrategy):
            self = try Money._decodeObject(amountStrategy: amountStrategy, from: decoder)
        }
    }

    // MARK: - Private encode helpers

    private func _encodeMinorUnits(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_storage)
    }

    private func _encodeMajorUnits(to encoder: any Encoder) throws {
        guard !isNaN else {
            throw EncodingError.invalidValue(
                self,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Money.nan cannot be encoded using the .majorUnits strategy. Use .minorUnits to preserve NaN."
                )
            )
        }
        var container = encoder.singleValueContainer()
        try container.encode(_majorUnitsDecimal())
    }

    private func _encodeString(locale: Locale, to encoder: any Encoder) throws {
        guard !isNaN else {
            throw EncodingError.invalidValue(
                self,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Money.nan cannot be encoded using the .string strategy. Use .minorUnits to preserve NaN."
                )
            )
        }
        var container = encoder.singleValueContainer()
        try container.encode(self.formatted(Money<Currency>.FormatStyle(locale: locale)))
    }

    private func _encodeObject(amountStrategy: MoneyAmountEncodingStrategy, to encoder: any Encoder) throws {
        guard !isNaN else {
            throw EncodingError.invalidValue(
                self,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Money.nan cannot be encoded using the .object strategy. Use .minorUnits to preserve NaN."
                )
            )
        }
        var container = encoder.container(keyedBy: CodingKey.self)
        try container.encode(Currency.code.stringValue, forKey: .currencyCode)
        switch amountStrategy {
        case .minorUnits:
            try container.encode(_storage, forKey: .amount)
        case .majorUnits:
            try container.encode(_majorUnitsDecimal(), forKey: .amount)
        case .string(let locale):
            try container.encode(self.formatted(Money<Currency>.FormatStyle(locale: locale)), forKey: .amount)
        }
    }

    // MARK: - Private decode helpers

    private static func _decodeMinorUnits(from decoder: any Decoder) throws -> Money<Currency> {
        let container = try decoder.singleValueContainer()
        let minorUnits = try container.decode(Int64.self)
        // Int64.min is the NaN sentinel — preserve it via _unchecked initialiser.
        return Money(_unchecked: minorUnits)
    }

    private static func _decodeMajorUnits(from decoder: any Decoder) throws -> Money<Currency> {
        let container = try decoder.singleValueContainer()
        let decimal = try container.decode(Decimal.self)
        return try _decimalToMoney(decimal, codingPath: decoder.codingPath)
    }

    private static func _decodeString(locale: Locale, from decoder: any Decoder) throws -> Money<Currency> {
        let container = try decoder.singleValueContainer()
        let formattedAmount = try container.decode(String.self)
        do {
            return try Money<Currency>(formattedAmount, format: Money<Currency>.FormatStyle(locale: locale))
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Could not parse '\(formattedAmount)' as \(Currency.code) using the configured locale."
            )
        }
    }

    private static func _decodeObject(amountStrategy: MoneyAmountDecodingStrategy, from decoder: any Decoder) throws -> Money<Currency> {
        let container = try decoder.container(keyedBy: CodingKey.self)

        let encodedCurrencyCode = try container.decode(String.self, forKey: .currencyCode)
        guard encodedCurrencyCode == Currency.code.stringValue else {
            let context = DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Currency mismatch: expected \(Currency.code), got '\(encodedCurrencyCode)'."
            )
            throw DecodingError.typeMismatch(Money<Currency>.self, context)
        }

        switch amountStrategy {
        case .minorUnits:
            let minorUnits = try container.decode(Int64.self, forKey: .amount)
            return Money(_unchecked: minorUnits)
        case .majorUnits:
            let decimal = try container.decode(Decimal.self, forKey: .amount)
            return try _decimalToMoney(decimal, codingPath: container.codingPath)
        case .string(let locale):
            let formattedAmount = try container.decode(String.self, forKey: .amount)
            do {
                return try Money<Currency>(formattedAmount, format: Money<Currency>.FormatStyle(locale: locale))
            } catch {
                throw DecodingError.dataCorruptedError(
                    forKey: .amount,
                    in: container,
                    debugDescription: "Could not parse '\(formattedAmount)' as \(Currency.code) using the configured locale."
                )
            }
        }
    }

    // MARK: - Shared arithmetic helpers

    /// Converts `_storage` (minor units) to major-unit `Decimal` for encoding.
    private func _majorUnitsDecimal() -> Decimal {
        let quantisation = Decimal(Currency.minimalQuantisation.int64Value)
        return Decimal(_storage) / quantisation
    }

    /// Converts a major-unit `Decimal` into a `Money` value by multiplying by
    /// `minimalQuantisation` and rounding to the nearest minor unit (`.plain`).
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the result overflows `Int64`
    ///   or lands on the NaN sentinel (`Int64.min`).
    private static func _decimalToMoney(_ decimal: Decimal, codingPath: [any Swift.CodingKey]) throws -> Money<Currency> {
        let quantisation = Decimal(Currency.minimalQuantisation.int64Value)
        var product = decimal * quantisation
        var rounded = Decimal()
        NSDecimalRound(&rounded, &product, 0, .plain)
        let roundedMinorUnits = (rounded as NSDecimalNumber).int64Value
        guard Decimal(roundedMinorUnits) == rounded else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Decoded major-unit value \(decimal) overflows the Int64 minor-unit range."
            )
            throw DecodingError.dataCorrupted(context)
        }
        guard roundedMinorUnits != .min else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Decoded minor-unit value \(roundedMinorUnits) collides with the NaN sentinel (Int64.min)."
            )
            throw DecodingError.dataCorrupted(context)
        }
        return Money(_unchecked: roundedMinorUnits)
    }
}
#endif
