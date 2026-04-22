// MARK: - CustomStringConvertible

extension DistributionParts: CustomStringConvertible {
    /// The number of parts as a decimal string, e.g. `"3"`.
    public var description: String { String(_value) }
}

// MARK: - ExpressibleByIntegerLiteral

extension DistributionParts: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}
