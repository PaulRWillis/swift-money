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
