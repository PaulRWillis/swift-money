// The result of scaling a whole number of minor units by a rate: the whole part truncated toward zero,
// and any part of a unit left over. `nil` when the whole part is not representable as an `Int64`.
//
// Here beside `Rate` because it builds a `FractionalRemainder`, whose initializer is deliberately
// reachable from nowhere else.
@usableFromInline
func scaled(
    _ amount: Int64,
    by rate: Rate
) -> Scaled<Int64>? {
    let product = Fixed(amount).multipliedIfRepresentable(by: rate.value)

    guard let product,
          let whole = Int64(exactly: Int128(product, rounding: .towardZero)) else {
        return nil
    }

    guard let remainder = Rate.FractionalRemainder(leftOverOf: product) else {
        return .exact(whole)
    }

    return .inexact(whole, remainder: remainder)
}

public extension Rate {
    /// The part of one unit left over by a division.
    ///
    /// Never zero, and always less than one whole. There is no way to create one: a remainder comes
    /// only from a division that left something over, so a result cannot claim a remainder it does not
    /// have.
    struct FractionalRemainder: Equatable, Hashable, Sendable {
        // The leftover fraction, in (−1, 1) and never zero. `internal`, not public: the guarantee holds
        // only because nothing outside this file can build one.
        let value: Fixed

        // The part of `product` beyond its whole units, or `nil` when it divided exactly.
        init?(leftOverOf product: Fixed) {
            let whole = Fixed(Int128(product, rounding: .towardZero))
            let leftOver = product - whole

            guard leftOver != .zero else {
                return nil
            }

            self.value = leftOver
        }
    }

    /// Creates a rate from the part of a unit left over by a division.
    init(_ remainder: FractionalRemainder) {
        self.init(remainder.value)
    }
}

extension Rate.FractionalRemainder {
    // The whole number `nearZero` becomes once this leftover is resolved by `rule`.
    //
    // `nil` when that step is not representable: an amount that fits may not once it steps.
    @usableFromInline
    func resolving(
        _ nearZero: Int64,
        _ rule: RoundingRule
    ) -> Int64? {
        Int64(exactly: Int128(Fixed(nearZero) + value, rounding: rule))
    }
}
