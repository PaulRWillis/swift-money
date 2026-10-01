/// The minor units a stride sequence has left to return: the next, the last, and the step between.
///
/// `last` is a whole number of steps from `next`, at or beyond it in the step's direction, so every
/// step up to `last` lands on an amount and the distance between them is below 2⁶⁴.
@usableFromInline
struct StridePositions: Sendable {
    /// The minor units of the next amount to return.
    @usableFromInline
    let next: Int64

    /// The minor units of the final amount to return.
    @usableFromInline
    let last: Int64

    /// The minor units each step moves by. A negative step moves downward.
    @usableFromInline
    let step: NonZeroInt64

    /// Creates the positions from the next amount to the last.
    ///
    /// Doesn't check that `last` is a whole number of steps from `next`; the caller computes it so.
    ///
    /// - Parameters:
    ///   - next: The minor units of the next amount to return.
    ///   - last: The minor units of the final amount to return.
    ///   - step: The minor units each step moves by.
    @inlinable
    init(
        next: Int64,
        last: Int64,
        step: NonZeroInt64
    ) {
        self.next = next
        self.last = last
        self.step = step
    }

    /// The positions after this one, or `nil` once `next` is `last`.
    @inlinable
    var advanced: StridePositions? {
        guard next != last else {
            return nil
        }

        // `next` is short of `last` by a whole number of steps, so one more step stays in `Int64`.
        return StridePositions(next: next &+ step.rawValue, last: last, step: step)
    }

    /// Returns whether the given minor units are one of the positions from `next` to `last`.
    ///
    /// - Parameter minorUnits: The minor units to look for.
    /// - Returns: `true` if `minorUnits` lies from `next` to `last` and a whole number of steps from
    ///   `next`; otherwise, `false`.
    @inlinable
    func contains(_ minorUnits: Int64) -> Bool {
        let ascending = step.rawValue > 0

        guard ascending ? next <= minorUnits : minorUnits <= next else {
            return false
        }

        // On `last`'s side of `next`, each distance is below 2⁶⁴, so `UInt64` holds it exactly.
        let distance = UInt64(bitPattern: ascending ? minorUnits &- next : next &- minorUnits)
        let span = UInt64(bitPattern: ascending ? last &- next : next &- last)

        return distance <= span && distance % step.rawValue.magnitude == 0
    }

    /// The number of positions from `next` to `last`, or `Int.max` if that many don't fit `Int`.
    @inlinable
    var count: Int {
        let travel = UInt64(bitPattern: step.rawValue > 0 ? last &- next : next &- last)
        let (count, overflow) = (travel / step.rawValue.magnitude).addingReportingOverflow(1)

        guard !overflow, let exact = Int(exactly: count) else {
            return .max
        }

        return exact
    }
}
