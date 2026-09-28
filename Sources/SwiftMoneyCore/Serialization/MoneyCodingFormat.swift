/// The shape an amount takes on the wire.
///
/// Nothing has to set one. An amount writes `"GBP 499"` and reads back every shape this library
/// writes, so a format is only for matching an API that wants something else.
///
/// ```swift
/// coder.userInfo[.moneyCodingFormat] = MoneyCodingFormat.codedString(.majorUnits)
///
/// GBP(minorUnits: 4_99)   // "GBP 4.99" rather than "GBP 499"
/// ```
public struct MoneyCodingFormat: Sendable, Equatable, Hashable {
    /// How the amount itself is written.
    public enum Amount: Sendable, Equatable, Hashable {
        /// `499` or `4.99`, a JSON number in the units named.
        case number(MoneyCodingUnits)

        /// `"499"` or `"4.99"`, a JSON string in the units named.
        case string(MoneyCodingUnits)
    }

    enum Shape: Sendable, Equatable, Hashable {
        case codedString(MoneyCodingUnits)
        case fields(currencyKey: CurrencyKey, amountKey: AmountKey, amount: Amount)
        case amountOnly(Amount)
    }

    let shape: Shape

    /// The code and the amount in one string, `"GBP 499"`.
    public static let codedString = MoneyCodingFormat(shape: .codedString(.minorUnits))

    /// The code and the amount in one string, in the units named.
    ///
    /// ```swift
    /// .codedString(.minorUnits)   // "GBP 499"
    /// .codedString(.majorUnits)   // "GBP 4.99"
    /// ```
    ///
    /// - Parameter units: Which units the digits count.
    public static func codedString(_ units: MoneyCodingUnits) -> MoneyCodingFormat {
        MoneyCodingFormat(shape: .codedString(units))
    }

    /// The code and the amount in two fields, `{"currency": "GBP", "amount": 499}`.
    public static let fields = MoneyCodingFormat.fields()

    /// The code and the amount in two fields, under this shape's own keys.
    ///
    /// ```swift
    /// .fields()                              // {"currency": "GBP", "amount": 499}
    /// .fields(amount: .number(.majorUnits))  // {"currency": "GBP", "amount": 4.99}
    /// .fields(amount: .string(.majorUnits))  // {"currency": "GBP", "amount": "4.99"}
    /// ```
    ///
    /// - Parameter amount: How the amount is written.
    public static func fields(amount: Amount = .number(.minorUnits)) -> MoneyCodingFormat {
        MoneyCodingFormat(shape: .fields(currencyKey: .default, amountKey: .default, amount: amount))
    }

    /// The code and the amount in two fields, under the keys named.
    ///
    /// ```swift
    /// try .fields(currencyKey: "ccy", amountKey: "value")  // {"ccy": "GBP", "value": 499}
    /// ```
    ///
    /// - Parameters:
    ///   - currencyKey: The key the currency code is written under.
    ///   - amountKey: The key the amount is written under.
    ///   - amount: How the amount is written.
    /// - Throws: `MoneyCodingFormatError.duplicateFieldKey` if `currencyKey`, `amountKey`, or the
    ///   reserved key `"scale"` (which a currency outside ISO 4217 may also need on the wire) are
    ///   not all different — writing two of them under the same key would silently drop one.
    public static func fields(
        currencyKey: CurrencyKey,
        amountKey: AmountKey,
        amount: Amount = .number(.minorUnits)
    ) throws(MoneyCodingFormatError) -> MoneyCodingFormat {
        // "scale" — drop this entry, and this guard shrinks to just the two caller keys, once the
        // custom-currency registry ships and a scale never needs to be written at all.
        let keys = [String(currencyKey), String(amountKey), "scale"]

        guard let duplicate = keys.firstDuplicate() else {
            return MoneyCodingFormat(shape: .fields(currencyKey: currencyKey, amountKey: amountKey, amount: amount))
        }

        throw .duplicateFieldKey(duplicate)
    }

    /// The amount alone, `499`, for a currency the type already names.
    ///
    /// ```swift
    /// struct Product: Codable { let price: GBP }
    ///
    /// try encoder.encode(product)   // {"price": 499}
    /// ```
    ///
    /// Nothing written this way says which currency it is in, so the type has to. Asking a ``Money``
    /// for this shape throws, its currency being known only at runtime.
    public static let amountOnly = MoneyCodingFormat(shape: .amountOnly(.number(.minorUnits)))

    /// The amount alone, written as a number or a string.
    ///
    /// ```swift
    /// .amountOnly(.number(.majorUnits))   // 4.99
    /// .amountOnly(.string(.minorUnits))   // "499"
    /// .amountOnly(.string(.majorUnits))   // "4.99"
    /// ```
    ///
    /// - Parameter amount: How the amount is written.
    public static func amountOnly(_ amount: Amount) -> MoneyCodingFormat {
        MoneyCodingFormat(shape: .amountOnly(amount))
    }
}

extension MoneyCodingFormat.Amount {
    var units: MoneyCodingUnits {
        switch self {
        case let .number(units): units
        case let .string(units): units
        }
    }
}

extension MoneyCodingFormat {
    // Which units a number, or a string's digits without a point, count on the wire. Reading needs
    // this whatever shape was set for writing, since neither can say for itself.
    var units: MoneyCodingUnits {
        switch shape {
        case let .codedString(units): units
        case let .fields(_, _, amount): amount.units
        case let .amountOnly(amount): amount.units
        }
    }

    // The keys a field payload uses. Reading needs these whatever shape was set for writing, since
    // nothing but the format can say what an API calls them.
    #if !hasFeature(Embedded)
    var fieldKeys: (currency: MoneyCodingKey, amount: MoneyCodingKey) {
        guard case let .fields(currencyKey, amountKey, _) = shape else {
            return (MoneyCodingKey("currency"), MoneyCodingKey("amount"))
        }

        return (MoneyCodingKey(currencyKey), MoneyCodingKey(amountKey))
    }
    #endif
}

private extension Array where Element: Hashable {
    // The first element also seen earlier in the array, or `nil` if all are distinct.
    func firstDuplicate() -> Element? {
        var seen: Set<Element> = []

        for element in self where !seen.insert(element).inserted {
            return element
        }

        return nil
    }
}

#if !hasFeature(Embedded)

extension Decoder {
    var moneyCodingFormat: MoneyCodingFormat {
        userInfo[.moneyCodingFormat] as? MoneyCodingFormat ?? .codedString
    }
}

extension Encoder {
    var moneyCodingFormat: MoneyCodingFormat {
        userInfo[.moneyCodingFormat] as? MoneyCodingFormat ?? .codedString
    }
}

#endif
