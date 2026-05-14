// MARK: - CustomStringConvertible

extension RateCalculation: CustomStringConvertible {
    /// A human-readable description showing the amount and the rate applied.
    ///
    /// ```swift
    /// // "1 (at rate: 1/101)"
    /// ```
    public var description: String {
        "\(amount) (at rate: \(effectiveRate))"
    }
}
