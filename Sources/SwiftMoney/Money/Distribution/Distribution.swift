/// The result of distributing a `Money` value into `n` equal-or-near-equal parts.
///
/// Because money lives in discrete integer minor units, dividing an amount
/// into `n` parts will often leave a remainder. `Distribution` models the
/// two structurally distinct outcomes:
///
/// - **`.exact`** — the amount divides evenly; every recipient receives the same share.
/// - **`.uneven`** — there is a remainder; `largerCount` recipients receive `larger`
///   and `smallerCount` recipients receive `smaller`, where those two shares differ
///   by exactly one minor unit.
///
/// In both cases the sum invariant holds: `distribution.sum == originalAmount`.
///
/// ### Uneven split
/// ```swift
/// // £10.00 (1000 minor units) into 3 parts:
/// switch Money<GBP>(minorUnits: 1000).distributed(into: 3) {
/// case .exact:
///     break // unreachable — 1000 is not divisible by 3
/// case let .uneven(larger, largerCount, smaller, smallerCount):
///     // larger == £3.34, largerCount == 1
///     // smaller == £3.33, smallerCount == 2
///     // 334×1 + 333×2 == 1000 ✓
/// }
/// ```
///
/// ### Exact split
/// ```swift
/// // £9.00 (900 minor units) into 3 parts:
/// switch Money<GBP>(minorUnits: 900).distributed(into: 3) {
/// case let .exact(share, count):
///     // share == £3.00, count == 3
/// case .uneven:
///     break // unreachable
/// }
/// ```
public enum Distribution<C: Currency>: Sendable, Equatable {
    /// Every recipient receives an identical share.
    ///
    /// Produced when the amount is exactly divisible by `n`.
    case exact(share: Money<C>, count: Int)

    /// Recipients receive one of two adjacent amounts, differing by one minor unit.
    ///
    /// Produced when the amount is not exactly divisible by `n`.
    /// `largerCount` recipients receive `larger`; the remaining `smallerCount`
    /// receive `smaller`.
    case uneven(larger: Money<C>, largerCount: Int, smaller: Money<C>, smallerCount: Int)
}

extension Distribution {
    /// The total number of recipients (`n` passed to `distributed(into:)`).
    public var totalCount: Int {
        switch self {
        case let .exact(_, count):
            return count
        case let .uneven(_, largerCount, _, smallerCount):
            return largerCount + smallerCount
        }
    }

    /// The sum of all shares; always equals the original distributed amount.
    public var sum: Money<C> {
        switch self {
        case let .exact(share, count):
            return share * Int64(count)
        case let .uneven(larger, largerCount, smaller, smallerCount):
            return larger * Int64(largerCount) + smaller * Int64(smallerCount)
        }
    }
}
