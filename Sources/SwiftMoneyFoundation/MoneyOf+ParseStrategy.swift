import Foundation
import SwiftMoney

public extension MoneyOf {
    /// A strategy that turns localized text back into the amount it renders.
    ///
    /// Created from the style whose output it inverts: `parseStrategy` where the type names
    /// the currency, or ``FormatStyle/parseStrategy(for:)`` where only the caller can. There
    /// is no public initializer, so a strategy cannot exist without the currency that gives
    /// the digits their meaning, and a typed strategy cannot carry a currency other than its
    /// type's. Those are the states this type forbids.
    struct ParseStrategy: Equatable, Hashable, Sendable {
        fileprivate let formatStyle: MoneyOf<C>.FormatStyle
        fileprivate let currency: Currency
    }
}

extension MoneyOf.ParseStrategy: Codable {
    private enum CodingKeys: String, CodingKey {
        case formatStyle
        case currencyCode
        case unitScale
    }

    /// Writes the style, and the currency as its code and its scale.
    ///
    /// The two parts of the currency are written separately because `Currency` is not `Codable`.
    ///
    /// - Parameter encoder: The encoder to write to.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(formatStyle, forKey: .formatStyle)
        try container.encode(currency.code, forKey: .currencyCode)
        try container.encode(Int64(currency.unitScale), forKey: .unitScale)
    }

    /// Reads the style and rebuilds the currency from its code and its scale.
    ///
    /// - Parameter decoder: The decoder to read from.
    /// - Throws: `DecodingError.dataCorrupted` if the scale is not a valid one, or if a strategy
    ///   whose type names a currency is asked to read a different one.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let formatStyle = try container.decode(MoneyOf<C>.FormatStyle.self, forKey: .formatStyle)
        let code = try container.decode(CurrencyCode.self, forKey: .currencyCode)
        let rawScale = try container.decode(Int64.self, forKey: .unitScale)

        guard let unitScale = UnitScale(exactly: rawScale) else {
            throw DecodingError.dataCorruptedError(
                forKey: .unitScale,
                in: container,
                debugDescription: """
                    Not a valid unit scale: \(rawScale). \
                    A scale is at least one and divides a power of ten no finer than 10 ^ 18.
                    """
            )
        }

        let currency = Currency(code: code, unitScale: unitScale)

        // A representation that carries its currency stores the currency itself, so this cast
        // succeeds for exactly that one and there is nothing to check: any currency is allowed.
        // A representation that fixes its currency stores nothing, so the cast fails and the
        // currency that was read has to agree with the one the type names.
        if currency as? C.Storage == nil {
            guard let storage = C.storage(forCode: code),
                  C.currency(for: storage) == currency
            else {
                throw DecodingError.dataCorruptedError(
                    forKey: .currencyCode,
                    in: container,
                    debugDescription: """
                        A strategy for \(MoneyOf<C>.self) cannot parse \(currency) amounts.
                        """
                )
            }
        }

        self.init(formatStyle: formatStyle, currency: currency)
    }
}

extension MoneyOf.ParseStrategy: Foundation.ParseStrategy where C: CurrencyType {
    /// The amount the localized text holds, in the currency this strategy's type names.
    ///
    /// - Parameter value: Text in the form the strategy's format style produces.
    public func parse(_ value: String) throws(MoneyParsingError) -> MoneyOf<C> {
        let minorUnits = try smallestUnits(in: value)

        guard let money = MoneyOf<C>(exactly: minorUnits) else {
            throw MoneyParsingError.unrepresentableAmount(currency)
        }

        return money
    }
}

public extension MoneyOf.ParseStrategy where C == AnyCurrency {
    /// The amount the localized text holds, in the currency this strategy carries.
    ///
    /// - Parameter value: Text in the form the strategy's format style produces.
    func parse(_ value: String) throws(MoneyParsingError) -> Money {
        let minorUnits = try smallestUnits(in: value)

        guard let money = Money(exactly: minorUnits, currency: currency) else {
            throw MoneyParsingError.unrepresentableAmount(currency)
        }

        return money
    }
}

private extension MoneyOf.ParseStrategy {
    // The smallest units the text holds. Nothing is rounded, whatever the style that wrote the
    // text was told to round: text finer than the currency divides is refused instead.
    func smallestUnits(in text: String) throws(MoneyParsingError) -> Money.MinorUnits {
        let majorUnits: Decimal

        do {
            majorUnits = try formatStyle.decimalStyle(for: currency).parseStrategy.parse(text)
        } catch {
            throw .unrecognizedText(text)
        }

        guard let minorUnits = exactMinorUnits(majorUnits, in: currency) else {
            throw refusal(of: majorUnits)
        }

        return minorUnits
    }

    // Why an amount the text does hold is still not one this currency can carry. Told apart here
    // because the conversion answers only `nil`, and the two have different remedies: one asks
    // for fewer decimals, the other for a smaller number.
    func refusal(of majorUnits: Decimal) -> MoneyParsingError {
        var value = majorUnits
        var scale = Decimal(UInt64(Int64(currency.unitScale)))
        var smallestUnits = Decimal()

        guard NSDecimalMultiply(&smallestUnits, &value, &scale, .plain) == .noError else {
            return .unrepresentableAmount(currency)
        }

        var whole = Decimal()
        NSDecimalRound(&whole, &smallestUnits, 0, .plain)

        return whole == smallestUnits
            ? .unrepresentableAmount(currency)
            : .inexactAmount(currency)
    }
}

extension MoneyOf.FormatStyle: ParseableFormatStyle where C: CurrencyType {
    /// The strategy that turns this style's output back into the amount it came from.
    ///
    /// One form does not come back. A narrow presentation writes the shortest symbol, and a
    /// short symbol such as `$` is shared by many currencies. Where the locale binds that symbol
    /// to none of them, ICU refuses to guess and the text is reported as unrecognized.
    public var parseStrategy: MoneyOf<C>.ParseStrategy {
        MoneyOf<C>.ParseStrategy(formatStyle: self, currency: C.currency)
    }
}

public extension MoneyOf.FormatStyle where C == AnyCurrency {
    /// The strategy that turns this style's output back into an amount, in a currency the
    /// caller names, nothing else being able to say how finely a runtime currency divides.
    ///
    /// One form does not come back. A narrow presentation writes the shortest symbol, and a
    /// short symbol such as `$` is shared by many currencies. Where the locale binds that symbol
    /// to none of them, ICU refuses to guess and the text is reported as unrecognized.
    ///
    /// - Parameter currency: The currency the text is an amount of.
    func parseStrategy(for currency: Currency) -> Money.ParseStrategy {
        Money.ParseStrategy(formatStyle: self, currency: currency)
    }
}
