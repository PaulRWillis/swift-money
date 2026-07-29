public enum Split<Value: Equatable> {
    case even(Group<Value>)
    case uneven(
        larger: Group<Value>,
        smaller: Group<Value>
    )
}

extension Split {
    public var values: [Value] {
        switch self {
        case let .even(group):
            return Array.init(repeating: group.value, count: Int(group.count))
        case let .uneven(larger, smaller):
            return [
                Array.init(repeating: larger.value, count: Int(larger.count)),
                Array.init(repeating: smaller.value, count: Int(smaller.count))
            ].flatMap { $0 }
        }
    }
}

extension Split {
    static func even(count: PartCount, value: Value) -> Self {
        self.even(
            Group(
                count: count,
                value: value
            )
        )
    }

    static func uneven(
        larger: (count: PartCount, value: Value),
        smaller: (count: PartCount, value: Value),
    ) -> Self {
        self.uneven(
            larger: Group(
                count: larger.count,
                value: larger.value
            ),
            smaller: Group(
                count: smaller.count,
                value: smaller.value
            )
        )
    }
}

extension Split {
    public struct Group<T: Equatable>: Equatable {
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

extension Split: Equatable {}

extension Split {
    func map<NewValue>(
        _ transform: (Value) -> NewValue
    ) -> Split<NewValue> {
        switch self {
        case let .even(group):
            return .even(
                count: group.count,
                value: transform(group.value)
            )
        case let .uneven(larger, smaller):
            return .uneven(
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

func split(
    _ amount: Int,
    into parts: PartCount
) -> Split<Int> {
    guard let amount = NonZeroInt(amount) else {
        return .even(count: parts, value: 0)
    }

    let (quotient, remainder) = amount.quotientAndRemainder(dividingBy: parts)

    switch remainder {
    case .zero:
        return .even(count: parts, value: quotient)
    case .nonZero(let nonZeroRemainder):
        let largerCount = abs(nonZeroRemainder)

        return .uneven(
            larger: (
                count: largerCount,
                value: quotient + amount.signum
            ),
            smaller: (
                count: parts.subtracting(largerCount),
                value: quotient
            )
        )
    }
}

func abs(_ value: NonZeroInt) -> PartCount {
    PartCount(unchecked: abs(value.rawValue))
}
