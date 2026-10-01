/// How rounding to the nearest value breaks an exact tie between the two either side.
///
/// A rounding that only ever takes the nearer neighbor can't fail, so it takes a tie-break rather
/// than a ``RoundingRule``:
///
/// ```swift
/// steps.index(approximating: saved, tiesTo: .awayFromZero)
/// ```
public enum TieBreakingRule: Equatable, Hashable, Sendable {
    /// Toward the neighbor at an even position, as ``RoundingRule/toNearestOrEven`` does.
    case even

    /// Toward the neighbor larger in size, or the positive one when both are the same size, as
    /// ``RoundingRule/toNearestOrAwayFromZero`` does.
    case awayFromZero
}

public extension TieBreakingRule {
    /// Creates the tie-break a nearest rounding rule uses, or `nil` for a rule that names a
    /// direction.
    ///
    /// ```swift
    /// TieBreakingRule(RoundingRule.toNearestOrEven)   // .even
    /// TieBreakingRule(RoundingRule.down)              // nil
    /// ```
    ///
    /// - Parameter rule: The rounding rule to convert.
    /// - Returns: The tie-break `rule` uses, or `nil` if `rule` isn't a nearest rule.
    init?(_ rule: RoundingRule) {
        switch rule {
        case .toNearestOrEven: self = .even
        case .toNearestOrAwayFromZero: self = .awayFromZero
        case .down, .up, .towardZero, .awayFromZero: return nil
        }
    }
}

public extension RoundingRule {
    /// Creates the nearest rounding rule that breaks a tie as given.
    ///
    /// ```swift
    /// RoundingRule(TieBreakingRule.even)   // .toNearestOrEven
    /// ```
    ///
    /// - Parameter rule: The tie-break to convert.
    init(_ rule: TieBreakingRule) {
        switch rule {
        case .even: self = .toNearestOrEven
        case .awayFromZero: self = .toNearestOrAwayFromZero
        }
    }
}
