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
    /// Which units the digits count.
    ///
    /// ```swift
    /// .minorUnits   // 499
    /// .majorUnits   // 4.99
    /// ```
    ///
    /// A string says which it is for itself, a `.` meaning major units, so this decides only what a
    /// number means. A number cannot say: `400` and `400.00` are one JSON number, and reading the
    /// fraction as a hint would make the same payload mean two amounts a hundredfold apart.
    public enum Units: Sendable, Equatable, Hashable {
        /// The currency's smallest units, so pence rather than pounds.
        case minorUnits

        /// Whole units and a fraction, so pounds and pence.
        ///
        /// A currency whose scale writes no exact decimal, such as a pound of 240 pence, falls back
        /// to its smallest units.
        case majorUnits
    }

    /// How the amount itself is written.
    public enum Amount: Sendable, Equatable, Hashable {
        /// `499` or `4.99`, a JSON number in the units named.
        case number(Units)

        /// `"499"` or `"4.99"`, a JSON string in the units named.
        case string(Units)
    }

    enum Shape: Sendable, Equatable, Hashable {
        case codedString(Units)
        case fields(currencyKey: String, amountKey: String, amount: Amount)
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
    public static func codedString(_ units: Units) -> MoneyCodingFormat {
        MoneyCodingFormat(shape: .codedString(units))
    }

    /// The code and the amount in two fields, `{"currency": "GBP", "amount": 499}`.
    public static let fields = MoneyCodingFormat.fields()

    /// The code and the amount in two fields, under the keys an API uses.
    ///
    /// ```swift
    /// .fields()                                        // {"currency": "GBP", "amount": 499}
    /// .fields(amount: .number(.majorUnits))            // {"currency": "GBP", "amount": 4.99}
    /// .fields(amount: .string(.majorUnits))            // {"currency": "GBP", "amount": "4.99"}
    /// .fields(currencyKey: "ccy", amountKey: "value")  // {"ccy": "GBP", "value": 499}
    /// ```
    ///
    /// - Parameters:
    ///   - currencyKey: The key the currency code is written under.
    ///   - amountKey: The key the amount is written under.
    ///   - amount: How the amount is written.
    public static func fields(
        currencyKey: String = "currency",
        amountKey: String = "amount",
        amount: Amount = .number(.minorUnits)
    ) -> MoneyCodingFormat {
        MoneyCodingFormat(shape: .fields(currencyKey: currencyKey, amountKey: amountKey, amount: amount))
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

// A key an API names, rather than one this library fixes.
struct MoneyCodingKey: CodingKey {
    let stringValue: String

    var intValue: Int? { nil }

    init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue _: Int) {
        nil
    }
}

public extension CodingUserInfoKey {
    /// The key a coder carries a ``MoneyCodingFormat`` under.
    ///
    /// ```swift
    /// decoder.userInfo[.moneyCodingFormat] = MoneyCodingFormat.codedString(.majorUnits)
    /// ```
    static let moneyCodingFormat: CodingUserInfoKey = {
        guard let key = CodingUserInfoKey(rawValue: "tech.tyneside.swift-money.coding-format") else {
            preconditionFailure("A currency coding key could not be made from a literal")
        }

        return key
    }()
}

extension MoneyCodingFormat.Amount {
    var units: MoneyCodingFormat.Units {
        switch self {
        case let .number(units):
            return units

        case let .string(units):
            return units
        }
    }
}

extension MoneyCodingFormat {
    // Which units a number on the wire counts. Reading needs this whatever shape was set for
    // writing, a number being the one form that cannot say for itself.
    var units: Units {
        switch shape {
        case let .codedString(units):
            return units

        case let .fields(_, _, amount):
            return amount.units

        case let .amountOnly(amount):
            return amount.units
        }
    }

    // The keys a field payload uses. Reading needs these whatever shape was set for writing, since
    // nothing but the format can say what an API calls them.
    var fieldKeys: (currency: MoneyCodingKey, amount: MoneyCodingKey) {
        guard case let .fields(currencyKey, amountKey, _) = shape else {
            return (MoneyCodingKey("currency"), MoneyCodingKey("amount"))
        }

        return (MoneyCodingKey(currencyKey), MoneyCodingKey(amountKey))
    }
}

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
