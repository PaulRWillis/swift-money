/// A multiplier applied to a money amount — an interest rate, a fee rate, or an exchange rate.
public struct Rate: Equatable, Hashable, Sendable {
    private let value: Fixed

    private init(_ value: Fixed) {
        self.value = value
    }
}

public extension Rate {
    /// A rate equal to `p` percent, so `Rate.percent(50)` is one half.
    ///
    /// - Precondition: `p` is within the representable range; any realistic percentage is.
    static func percent(_ p: some BinaryInteger) -> Rate {
        guard let significand = Int128(exactly: p),
              let fixed = Fixed(significand: significand, exponent: -percentFractionDigits) else {
            preconditionFailure("Rate.percent(\(p)) is out of range")  // coverage:ignore — exit-test trap
        }
        return Rate(fixed)
    }

    /// A rate equal to `bp` basis points — one basis point is a hundredth of one percent, so
    /// `Rate.basisPoints(5000)` is one half.
    ///
    /// - Precondition: `bp` is within the representable range; any realistic rate is.
    static func basisPoints(_ bp: some BinaryInteger) -> Rate {
        guard let significand = Int128(exactly: bp),
              let fixed = Fixed(significand: significand, exponent: -basisPointFractionDigits) else {
            preconditionFailure("Rate.basisPoints(\(bp)) is out of range")  // coverage:ignore — exit-test trap
        }
        return Rate(fixed)
    }
}

private extension Rate {
    static let percentFractionDigits = 2       // percent = value / 10²
    static let basisPointFractionDigits = 4    // basis points = value / 10⁴
}
