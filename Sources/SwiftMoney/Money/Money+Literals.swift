// MARK: - ExpressibleByIntegerLiteral (poisoned)

extension Money {
    @available(*, unavailable, message: "Use Money(minorUnits:) for explicit minor-unit values")
    public init(integerLiteral value: IntegerLiteralType) {
        fatalError("Use Money(minorUnits:) for explicit minor-unit values")
    }
}
