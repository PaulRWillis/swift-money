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
    public enum Units: Sendable, Equatable, Hashable {
        /// The currency's smallest units, so pence rather than pounds.
        case minorUnits

        /// Whole units and a fraction, so pounds and pence.
        ///
        /// A currency whose scale writes no exact decimal, such as a pound of 240 pence, falls back
        /// to its smallest units.
        case majorUnits
    }

    /// How the amount is written in the field form.
    public enum Amount: Sendable, Equatable, Hashable {
        /// `499`, a JSON number of the currency's smallest units.
        case number

        /// `"499"` or `"4.99"`, a JSON string in the units named.
        case string(Units)
    }

    enum Shape: Sendable, Equatable, Hashable {
        case codedString(Units)
        case fields(currencyKey: String, amountKey: String, amount: Amount)
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
        amount: Amount = .number
    ) -> MoneyCodingFormat {
        MoneyCodingFormat(shape: .fields(currencyKey: currencyKey, amountKey: amountKey, amount: amount))
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

extension MoneyCodingFormat {
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
