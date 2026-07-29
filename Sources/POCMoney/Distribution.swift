public enum Distribution<Value: Equatable> {
    case equal(Portion<Value>)
    case unequal(
        larger: Portion<Value>,
        smaller: Portion<Value>
    )
}

extension Distribution {
    public var values: [Value] {
        switch self {
        case let .equal(portion):
            return Array.init(repeating: portion.value, count: Int(portion.count))
        case let .unequal(larger, smaller):
            return [
                Array.init(repeating: larger.value, count: Int(larger.count)),
                Array.init(repeating: smaller.value, count: Int(smaller.count))
            ].flatMap { $0 }
        }
    }
}

extension Distribution {
    static func equal(count: PartCount, value: Value) -> Self {
        self.equal(
            Portion(
                count: count,
                value: value
            )
        )
    }

    static func unequal(
        larger: (count: PartCount, value: Value),
        smaller: (count: PartCount, value: Value),
    ) -> Self {
        self.unequal(
            larger: Portion(
                count: larger.count,
                value: larger.value
            ),
            smaller: Portion(
                count: smaller.count,
                value: smaller.value
            )
        )
    }
}

extension Distribution {
    public struct Portion<T: Equatable>: Equatable {
        public let count: PartCount
        public let value: T

        fileprivate init(
            count: PartCount,
            value: T
        ) {
            self.count = count
            self.value = value
        }
    }
}

// MARK: - Equatable

extension Distribution: Equatable {}

extension Distribution {
    func map<NewValue>(
        _ transform: (Value) -> NewValue
    ) -> Distribution<NewValue> {
        switch self {
        case let .equal(distribution):
            return .equal(
                count: distribution.count,
                value: transform(distribution.value)
            )
        case let .unequal(larger, smaller):
            return .unequal(
                larger: (
                    count: larger.count,
                    value: transform(larger.value)
                ),
                smaller: (
                    count: smaller.count,
                    value: transform(smaller.value)
                ),
            )
        }
    }
}

func distributed(
    _ amount: Int,
    into count: PartCount
) -> Distribution<Int> {
    guard let amount = NonZeroInt(amount) else {
        return .equal(count: count, value: 0)
    }

    let (quotient, remainder) = amount.quotientAndRemainder(dividingBy: count)

    switch remainder {
    case .zero:
        return .equal(count: count, value: quotient)
    case .nonZero(let nonZeroRemainder):
        let largerCount = abs(nonZeroRemainder)

        return .unequal(
            larger: (
                count: largerCount,
                value: quotient + amount.signum
            ),
            smaller: (
                count: count.subtracting(largerCount),
                value: quotient
            )
        )
    }
}

func abs(_ value: NonZeroInt) -> PartCount {
    PartCount(unchecked: abs(value.rawValue))
}
