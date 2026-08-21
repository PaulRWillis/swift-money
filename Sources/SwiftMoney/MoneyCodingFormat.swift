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

    enum Shape: Sendable, Equatable, Hashable {
        case codedString(Units)
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
