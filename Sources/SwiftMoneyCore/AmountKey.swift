/// The key an amount is written under, on the ``MoneyCodingFormat/fields(currencyKey:amountKey:amount:)`` shape.
public struct AmountKey: Hashable, Sendable, ExpressibleByStringLiteral {
    fileprivate let storage: String

    /// Creates an amount key from a string that may not be a literal.
    ///
    /// - Parameter stringValue: The key.
    public init(_ stringValue: String) {
        storage = stringValue
    }

    /// Creates an amount key from a string literal.
    ///
    /// - Parameter value: The key.
    public init(stringLiteral value: String) {
        self.init(value)
    }

    /// The key this shape uses unless told otherwise, `"amount"`.
    public static let `default` = AmountKey("amount")
}

public extension String {
    /// Creates a string from an amount key.
    init(_ key: AmountKey) {
        self = key.storage
    }
}

// `MoneyCodingKey` is the `CodingKey` a coder actually uses; it doesn't exist in Embedded, unlike
// `AmountKey` itself, so only this bridge needs the guard.
#if !hasFeature(Embedded)
extension MoneyCodingKey {
    init(_ key: AmountKey) {
        self.init(String(key))
    }
}
#endif
