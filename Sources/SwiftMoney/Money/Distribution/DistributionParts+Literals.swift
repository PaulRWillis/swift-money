// MARK: - ExpressibleByIntegerLiteral

extension DistributionParts: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}
