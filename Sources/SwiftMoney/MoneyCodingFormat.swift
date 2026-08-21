/// The shape an amount takes on the wire.
///
/// Set it on a coder to change what is written. Anything this library can write, it can also read,
/// and it reads the other shapes too, so a format is needed only where the default is not wanted.
///
/// ```swift
/// let encoder = JSONEncoder()
/// encoder.userInfo[.moneyCodingFormat] = MoneyCodingFormat.codedString(.majorUnits)
///
/// try encoder.encode(GBP(minorUnits: 4_99))   // "GBP 4.99"
/// ```
public struct MoneyCodingFormat: Sendable, Equatable {
    /// Which units the digits count.
    public enum Units: Sendable, Equatable {
        /// `499`, the currency's smallest units.
        case minorUnits

        /// `4.99`, whole units and a fraction.
        case majorUnits
    }

    enum Shape: Sendable, Equatable {
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
