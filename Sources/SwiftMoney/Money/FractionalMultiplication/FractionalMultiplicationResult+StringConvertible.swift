// MARK: - CustomStringConvertible

extension FractionalMultiplicationResult: CustomStringConvertible {
    /// A human-readable description showing the result and the rate applied.
    ///
    /// ```swift
    /// // "1 (at rate: 1/101)"
    /// ```
    public var description: String {
        "\(result) (at rate: \(actualRate))"
    }
}
