import SwiftMoneyCore

extension Gen where Value == PartCount {
    /// A generator of part counts in `range`.
    ///
    /// - Precondition: `range`'s lower bound is at least one, which every caller passes, so
    ///   `PartCount(exactly:)` never returns `nil`; `?? 1` names that unreachable fallback without a
    ///   force unwrap.
    static func partCount(in range: ClosedRange<Int64>) -> Gen<PartCount> {
        precondition(range.lowerBound >= 1, "A part count is at least one")

        return Gen<Int64>.int(in: range).map { PartCount(exactly: Int($0)) ?? 1 }
    }
}

extension Gen where Value == Weight {
    /// A generator of weights in `range`.
    ///
    /// - Precondition: `range`'s lower bound is not negative, which every caller passes, so
    ///   `Weight(exactly:)` never returns `nil`; `?? 0` names that unreachable fallback without a force
    ///   unwrap.
    static func weight(in range: ClosedRange<Int64>) -> Gen<Weight> {
        precondition(range.lowerBound >= 0, "A weight is not negative")

        return Gen<Int64>.int(in: range).map { Weight(exactly: Int($0)) ?? 0 }
    }
}

extension Gen where Value == [Weight] {
    /// A generator of weight lists: between the bounds of `countRange` weights, each in `weightRange`.
    ///
    /// The first weight is drawn from at least one, so the list is never empty and always has a positive
    /// weight — exactly the two conditions `Weights.init` needs — while the rest may be zero. The sum of
    /// at most `countRange.upperBound` weights of at most `weightRange.upperBound` each is far inside
    /// `Int64`, so the sum is always representable too.
    static func weightList(
        countIn countRange: ClosedRange<Int64>,
        weightIn weightRange: ClosedRange<Int64>
    ) -> Gen<[Weight]> {
        precondition(countRange.lowerBound >= 1, "A weight list has at least one weight")

        let positiveRange = max(1, weightRange.lowerBound) ... weightRange.upperBound
        // One weight is the guaranteed-positive head, so the tail holds one fewer than the total count.
        let tailCount = Gen<Int64>.int(in: (countRange.lowerBound - 1) ... (countRange.upperBound - 1))

        return zip(
            Gen<Weight>.weight(in: positiveRange),
            Gen<Weight>.weight(in: weightRange).array(count: tailCount)
        ).map { head, tail in [head] + tail }
    }
}
