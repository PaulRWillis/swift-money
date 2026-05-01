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
