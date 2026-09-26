#if !hasFeature(Embedded)

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

#endif
