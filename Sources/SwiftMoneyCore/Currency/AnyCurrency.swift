/// A currency only known at runtime, so that amounts carry it and combining them can fail.
///
/// Used through ``Money``, which is `MoneyOf<AnyCurrency>`.
public enum AnyCurrency: CurrencyRepresentation {
    public typealias Storage = Currency

    @inlinable
    public static func currency(for storage: Currency) -> Currency { storage }

    @inlinable
    public static func storage(forCode code: CurrencyCode?) -> Currency? {
        code.flatMap(Currency.init(iso:))
    }

    /// Resolves a currency the ISO table ships from the code alone, or a currency the table does not
    /// ship from the code and its scale together. Validates the scale itself, since this is the one
    /// representation that ever looks at it — a malformed scale here is refused, not silently
    /// dropped, but it never reaches a representation that would have ignored it anyway.
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

    @usableFromInline
    static func requireMatch(
        _ lhs: Currency,
        _ rhs: Currency
    ) throws(MoneyError) {
        guard lhs == rhs else {
            throw .currencyMismatch(lhs: lhs, rhs: rhs)
        }
    }
}
