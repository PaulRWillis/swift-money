// MARK: - CustomStringConvertible

extension Rate: CustomStringConvertible {
    /// The rate as a string in the form `"numerator/denominator"`.
    ///
    /// ```swift
    /// Rate(numerator: 11, denominator: 100).description   // "11/100"
    /// Rate(numerator: -1, denominator: 10).description    // "-1/10"
    /// Rate(numerator: 1,  denominator: 1).description     // "1/1"
    /// ```
    public var description: String {
        "\(_numerator)/\(_denominator)"
    }
}

// MARK: - LosslessStringConvertible

extension Rate: LosslessStringConvertible {
    /// Creates a `Rate` from its string representation.
    ///
    /// The string must be in the form `"numerator/denominator"` where both
    /// components are valid `Int64` values and the denominator is positive.
    ///
    /// ```swift
    /// let rate = Rate("23/1000000")   // 23/1000000
    /// let bad  = Rate("3/0")          // nil
    /// ```
    ///
    /// - Parameter description: A string in `"n/d"` format.
    public init?(_ description: String) {
        let parts = description.split(separator: "/", maxSplits: 1)
        guard parts.count == 2,
              !parts[1].contains("/"),
              let numerator = Int64(parts[0]),
              let denominator = Int64(parts[1])
        else { return nil }
        self.init(numerator: numerator, denominator: denominator)
    }
}
