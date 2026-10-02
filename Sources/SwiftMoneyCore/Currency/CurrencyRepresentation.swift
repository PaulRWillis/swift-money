/// The means by which a monetary amount knows its currency.
///
/// Conform to ``CurrencyType`` to define a currency. Conforming here directly gives an amount no
/// arithmetic, because the operators are declared only for the two conformances this library
/// provides.
public protocol CurrencyRepresentation: Sendable {
    /// What an amount carries in order to know its currency.
    associatedtype Storage: Hashable & Sendable

    /// What ``MoneyRangeParsingError`` reports as the currency when two bounds' currencies differ,
    /// or `Never` where this representation fixes one currency, so they never can.
    associatedtype Mismatch: Hashable & Sendable

    /// The currency an amount is denominated in, given what it carries.
    static func currency(for storage: Storage) -> Currency

    /// What an amount carries in order to be in the currency a code names, or `nil` where this
    /// representation cannot be that currency.
    ///
    /// The inverse of ``currency(for:)``. ``CurrencyType`` supplies it, so defining a currency does
    /// not mean writing one.
    ///
    /// - Parameter code: The code naming the currency, or `nil` where nothing named one, in which
    ///   case only a representation that fixes a currency of its own can answer.
    static func storage(forCode code: CurrencyCode?) -> Storage?

    /// What an amount carries in order to be in the currency a decoded ``CurrencyField`` names, or
    /// `nil` where this representation cannot be that currency.
    ///
    /// A field with a scale names a currency at that scale, so the answer is `nil` unless the
    /// currency has it. A default implementation answers from ``storage(forCode:)``.
    ///
    /// - Parameter field: What a decoded payload named as the currency.
    /// - Returns: The storage for the currency `field` names, or `nil` where this representation
    ///   cannot be that currency.
    static func storage(for field: CurrencyField) -> Storage?
}

public extension CurrencyRepresentation {
    static func storage(forCode _: CurrencyCode?) -> Storage? { nil }

    /// Returns the storage ``storage(forCode:)`` answers for a decoded field's code, or `nil` where
    /// the field carries a scale that currency doesn't have.
    ///
    /// ```swift
    /// LoyaltyPoints.storage(for: .code("LTY"))                        // not nil
    /// LoyaltyPoints.storage(for: .custom(code: "LTY", rawScale: 0))  // not nil
    /// LoyaltyPoints.storage(for: .custom(code: "LTY", rawScale: 2))  // nil
    /// ```
    ///
    /// - Parameter field: What a decoded payload named as the currency.
    /// - Returns: The storage for the field's code, or for `nil` where the field names none;
    ///   `nil` where that has none, or where the field's scale differs from the currency's.
    static func storage(for field: CurrencyField) -> Storage? {
        switch field {
        case .none:
            return storage(forCode: nil)

        case let .code(code):
            return storage(forCode: code)

        case let .custom(code, rawScale):
            guard
                let storage = storage(forCode: code),
                UnitScale(decimalPlaces: rawScale) == currency(for: storage).unitScale
            else {
                return nil
            }

            return storage
        }
    }
}

extension CurrencyRepresentation {
    /// The currency this representation would resolve from a code alone, with no scale — what
    /// `storage(for:)` already does for a payload naming a code and nothing else, composed with
    /// `currency(for:)` to answer in `Currency` rather than in `Storage`.
    ///
    /// Encoding uses this to decide whether a currency needs its scale on the wire: if the code
    /// alone already resolves to the same currency, a scale would be written only to be thrown
    /// away on decode.
    package static func currency(resolvedFromCodeAlone code: CurrencyCode) -> Currency? {
        storage(for: .code(code)).map(currency(for:))
    }
}
