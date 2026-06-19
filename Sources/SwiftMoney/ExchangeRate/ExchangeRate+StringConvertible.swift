// MARK: - CustomStringConvertible

#warning("Remove this for now")
extension ExchangeRate: CustomStringConvertible {
    /// A human-readable description showing the GCD-reduced pair, e.g. `"20 EUR = 17 GBP"`.
    public var description: String {
        "\(fromMinorUnits) \(From.code) = \(toMinorUnits) \(To.code)"
    }
}
