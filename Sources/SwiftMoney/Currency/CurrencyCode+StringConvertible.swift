// MARK: - CustomStringConvertible

extension CurrencyCode: CustomStringConvertible {
    /// The currency code string, e.g. `"GBP"`.
    public var description: String { _value }
}
