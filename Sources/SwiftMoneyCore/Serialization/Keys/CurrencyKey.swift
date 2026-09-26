/// The key a currency's code is written under, on the ``MoneyCodingFormat/fields(currencyKey:amountKey:amount:)`` shape.
public struct CurrencyKey: Hashable, Sendable, ExpressibleByStringLiteral {
    fileprivate let storage: String

    /// Creates a currency key from a string that may not be a literal.
    ///
    /// - Parameter stringValue: The key.
    public init(_ stringValue: String) {
        storage = stringValue
    }

    /// Creates a currency key from a string literal.
    ///
    /// - Parameter value: The key.
    public init(stringLiteral value: String) {
        self.init(value)
    }

    /// The key this shape uses unless told otherwise, `"currency"`.
    public static let `default` = CurrencyKey("currency")
}

public extension String {
    /// Creates a string from a currency key.
    init(_ key: CurrencyKey) {
        self = key.storage
    }
}

// `MoneyCodingKey` is the `CodingKey` a coder actually uses; it doesn't exist in Embedded, unlike
// `CurrencyKey` itself, so only this bridge needs the guard.
#if !hasFeature(Embedded)
extension MoneyCodingKey {
    init(_ key: CurrencyKey) {
        self.init(String(key))
    }
}
#endif
