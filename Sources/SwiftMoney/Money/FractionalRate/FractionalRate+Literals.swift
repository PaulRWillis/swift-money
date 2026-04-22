// MARK: - CustomStringConvertible

extension FractionalRate: CustomStringConvertible {
    /// The rate as a string in the form `"numerator/denominator"`.
    ///
    /// ```swift
    /// FractionalRate(numerator: 11, denominator: 100).description   // "11/100"
    /// FractionalRate(numerator: -1, denominator: 10).description    // "-1/10"
    /// FractionalRate(numerator: 1,  denominator: 1).description     // "1/1"
    /// ```
    public var description: String {
        "\(_numerator)/\(_denominator)"
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension FractionalRate: ExpressibleByIntegerLiteral {
    /// Creates a `FractionalRate` equal to the given integer (denominator is 1).
    ///
    /// ```swift
    /// let doubling: FractionalRate = 2   // numerator: 2, denominator: 1
    /// let identity: FractionalRate = 1   // numerator: 1, denominator: 1
    /// ```
    public init(integerLiteral value: Int64) {
        precondition(value != .min, "FractionalRate integer literal must not be Int64.min")
        self.init(_unchecked: value, denominator: 1)
    }
}
