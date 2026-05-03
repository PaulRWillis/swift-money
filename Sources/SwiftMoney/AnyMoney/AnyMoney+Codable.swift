#if canImport(Foundation)
import Foundation

// MARK: - Codable

extension AnyMoney: Codable {

    /// Encodes this ``AnyMoney`` value using the strategy configured on the encoder.
    ///
    /// The active strategy is read from `encoder.userInfo[.anyMoneyEncodingStrategy]`
    /// (set via ``JSONEncoder/anyMoneyEncodingStrategy``). Defaults to
    /// ``AnyMoneyEncodingStrategy/full`` when not set.
    ///
    /// - SeeAlso: ``JSONEncoder/anyMoneyEncodingStrategy``
    public func encode(to encoder: any Encoder) throws {
        let strategy = encoder.userInfo[.anyMoneyEncodingStrategy] as? AnyMoneyEncodingStrategy ?? .full
        try _encode(strategy: strategy, to: encoder)
    }

    /// Creates an ``AnyMoney`` by decoding from the given decoder.
    ///
    /// The active strategy is read from `decoder.userInfo[.anyMoneyDecodingStrategy]`
    /// (set via ``JSONDecoder/anyMoneyDecodingStrategy``). Defaults to
    /// ``AnyMoneyDecodingStrategy/full`` when not set.
    ///
    /// The decoding strategy **must** match the encoding strategy that produced
    /// the data, or a `DecodingError` will be thrown.
    ///
    /// - SeeAlso: ``JSONDecoder/anyMoneyDecodingStrategy``
    public init(from decoder: any Decoder) throws {
        let strategy = decoder.userInfo[.anyMoneyDecodingStrategy] as? AnyMoneyDecodingStrategy ?? .full
        self = try AnyMoney._decode(strategy: strategy, from: decoder)
    }
}

// MARK: - Internal helpers (used by MoneyBag+Codable.swift)
//
// These bypass the userInfo dispatch so MoneyBag can control per-entry encoding
// without the outer encoder's anyMoneyEncodingStrategy bleeding through.

extension AnyMoney {

    // MARK: Coding keys

    fileprivate enum FullKey: String, CodingKey {
        case minorUnits, currencyCode, minimalQuantisation
    }

    fileprivate enum ObjectKey: String, CodingKey {
        case currencyCode, amount
    }

    // MARK: Dispatch

    /// Encodes using an explicit strategy. Called by `MoneyBag+Codable.swift`.
    internal func _encode(strategy: AnyMoneyEncodingStrategy, to encoder: any Encoder) throws {
        switch strategy {
        case .full:
            try _encodeFull(to: encoder)
        case .object(let amountStrategy):
            try _encodeObject(amountStrategy: amountStrategy, to: encoder)
        }
    }

    /// Decodes using an explicit strategy. Called by `MoneyBag+Codable.swift`.
    internal static func _decode(strategy: AnyMoneyDecodingStrategy, from decoder: any Decoder) throws -> AnyMoney {
        switch strategy {
        case .full:
            return try _decodeFull(from: decoder)
        case .object(let amountStrategy, let resolver):
            return try _decodeObject(amountStrategy: amountStrategy, resolver: resolver, from: decoder)
        }
    }

    // MARK: Encode helpers

    private func _encodeFull(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: FullKey.self)
        try container.encode(minorUnits, forKey: .minorUnits)
        try container.encode(currencyCode.stringValue, forKey: .currencyCode)
        try container.encode(minimalQuantisation.int64Value, forKey: .minimalQuantisation)
    }

    private func _encodeObject(amountStrategy: MoneyAmountEncodingStrategy, to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ObjectKey.self)
        try container.encode(currencyCode.stringValue, forKey: .currencyCode)
        switch amountStrategy {
        case .minorUnits:
            try container.encode(minorUnits, forKey: .amount)
        case .majorUnits:
            guard !isNaN else {
                throw EncodingError.invalidValue(
                    self,
                    EncodingError.Context(
                        codingPath: encoder.codingPath,
                        debugDescription: "AnyMoney.nan cannot be encoded using .object(amount: .majorUnits). Use .full or .object(amount: .minorUnits) to preserve NaN."
                    )
                )
            }
            try container.encode(decimalValue, forKey: .amount)
        case .string(let locale):
            guard !isNaN else {
                throw EncodingError.invalidValue(
                    self,
                    EncodingError.Context(
                        codingPath: encoder.codingPath,
                        debugDescription: "AnyMoney.nan cannot be encoded using .object(amount: .string). Use .full or .object(amount: .minorUnits) to preserve NaN."
                    )
                )
            }
            try container.encode(formatted(AnyMoney.FormatStyle(locale: locale)), forKey: .amount)
        }
    }

    // MARK: Decode helpers

    private static func _decodeFull(from decoder: any Decoder) throws -> AnyMoney {
        let container = try decoder.container(keyedBy: FullKey.self)
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
        let isPositiveQuantisation = quantisationInt > 0
        guard isPositiveQuantisation else {
            throw DecodingError.dataCorruptedError(
                forKey: .minimalQuantisation,
                in: container,
                debugDescription: "AnyMoney minimalQuantisation must be > 0 (decoded \(quantisationInt))"
            )
        }
        return AnyMoney(
            minorUnits: minorUnits,
            currencyCode: CurrencyCode(currencyCodeString),
            minimalQuantisation: MinimalQuantisation(quantisationInt)
        )
    }

    private static func _decodeObject(
        amountStrategy: MoneyAmountDecodingStrategy,
        resolver: @Sendable (CurrencyCode) -> MinimalQuantisation?,
        from decoder: any Decoder
    ) throws -> AnyMoney {
        let container = try decoder.container(keyedBy: ObjectKey.self)
        let currencyCodeString = try container.decode(String.self, forKey: .currencyCode)
        guard !currencyCodeString.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .currencyCode,
                in: container,
                debugDescription: "AnyMoney currencyCode cannot be empty"
            )
        }
        let code = CurrencyCode(currencyCodeString)
        guard let minimalQuantisation = resolver(code) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "No MinimalQuantisation found for currency '\(code)'. Provide a resolver that covers this currency."
                )
            )
        }
        let minorUnits: Int64
        switch amountStrategy {
        case .minorUnits:
            minorUnits = try container.decode(Int64.self, forKey: .amount)
        case .majorUnits:
            let decimal = try container.decode(Decimal.self, forKey: .amount)
            minorUnits = try _decimalToMinorUnits(decimal, minQ: minimalQuantisation, codingPath: container.codingPath)
        case .string(let locale):
            let string = try container.decode(String.self, forKey: .amount)
            let decimal = try _parseFormattedAmount(
                string, currencyCode: code, locale: locale, codingPath: container.codingPath
            )
            minorUnits = try _decimalToMinorUnits(decimal, minQ: minimalQuantisation, codingPath: container.codingPath)
        }
        return AnyMoney(minorUnits: minorUnits, currencyCode: code, minimalQuantisation: minimalQuantisation)
    }

    // MARK: Shared arithmetic helpers (internal so MoneyBag+Codable.swift can reuse them)

    /// Multiplies a major-unit Decimal by `minQ`, rounds to nearest minor unit (`.plain`),
    /// and converts to `Int64`. Throws on overflow or NaN-sentinel collision.
    internal static func _decimalToMinorUnits(
        _ decimal: Decimal,
        minQ: MinimalQuantisation,
        codingPath: [any CodingKey]
    ) throws -> Int64 {
        let quantisationDecimal = Decimal(minQ.int64Value)
        var product = decimal * quantisationDecimal
        var rounded = Decimal()
        NSDecimalRound(&rounded, &product, 0, .plain)
        let roundedMinorUnits = (rounded as NSDecimalNumber).int64Value
        let isWithinInt64Range = Decimal(roundedMinorUnits) == rounded
        guard isWithinInt64Range else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Decoded major-unit value \(decimal) overflows the Int64 minor-unit range."
                )
            )
        }
        let isNaNSentinel = roundedMinorUnits == .min
        guard !isNaNSentinel else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Decoded minor-unit value \(roundedMinorUnits) collides with the NaN sentinel (Int64.min)."
                )
            )
        }
        return roundedMinorUnits
    }

    /// Parses a locale-formatted currency string to a major-unit `Decimal`.
    /// Throws `DecodingError.dataCorrupted` on parse failure.
    internal static func _parseFormattedAmount(
        _ string: String,
        currencyCode: CurrencyCode,
        locale: Locale,
        codingPath: [any CodingKey]
    ) throws -> Decimal {
        let formatter = Decimal.FormatStyle.Currency(
            code: currencyCode.stringValue,
            locale: locale
        )
        do {
            return try formatter.parseStrategy.parse(string)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Could not parse '\(string)' as currency amount for '\(currencyCode)' using the configured locale."
                )
            )
        }
    }
}
#endif
