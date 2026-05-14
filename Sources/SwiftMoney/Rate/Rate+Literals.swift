// MARK: - ExpressibleByIntegerLiteral (poisoned)

extension Rate {
    @available(*, unavailable, message: "Use Rate(numerator:denominator:) for explicit rate values")
    public init(integerLiteral value: Int64) {
        fatalError("Use Rate(numerator:denominator:) for explicit rate values")
    }
}
