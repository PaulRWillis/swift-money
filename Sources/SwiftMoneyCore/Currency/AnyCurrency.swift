/// A currency only known at runtime, so that amounts carry it and combining them can fail.
///
/// Used through ``Money``, which is `MoneyOf<AnyCurrency>`.
public enum AnyCurrency: CurrencyRepresentation {
    public typealias Storage = Currency

    /// A mismatch reports a currency, since amounts can arrive in any one.
    public typealias Mismatch = Currency

    @inlinable
    public static func currency(for storage: Currency) -> Currency { storage }

    @inlinable
    public static func storage(forCode code: CurrencyCode?) -> Currency? {
        code.flatMap(Currency.init(iso:))
    }

    /// Returns the currency a decoded field names, or `nil` where it names none this type can be.
    ///
    /// A code alone resolves a currency the ISO table ships. A code and a scale rebuild any currency,
    /// as ``Currency/init(code:unitScale:)`` does.
    ///
    /// - Parameter field: What a decoded payload named as the currency.
    /// - Returns: The currency `field` names, or `nil` where it names no currency, a code alone the
    ///   ISO table doesn't ship, a scale ``UnitScale`` can't hold, or a shipped code at another
    ///   scale.
    @inlinable
    public static func storage(for field: CurrencyField) -> Currency? {
        switch field {
        case .none:
            return nil

        case let .code(code):
            return Currency(iso: code)

        case let .custom(code, rawScale):
            guard let scale = UnitScale(decimalPlaces: rawScale) else {
                return nil
            }

            return Currency(code: code, unitScale: scale)
        }
    }

    @inlinable
    static func requireMatch(
        _ lhs: Currency,
        _ rhs: Currency
    ) throws(MoneyError) {
        guard lhs == rhs else {
            try mismatch(lhs, rhs)
        }
    }

    // Out of line so that a caller's matching path, the common one, builds no error and saves no
    // registers for one. Throwing in place gave every caller that isn't inlined a stack frame.
    @usableFromInline
    @inline(never)
    static func mismatch(
        _ lhs: Currency,
        _ rhs: Currency
    ) throws(MoneyError) -> Never {
        throw .currencyMismatch(lhs: lhs, rhs: rhs)
    }
}
