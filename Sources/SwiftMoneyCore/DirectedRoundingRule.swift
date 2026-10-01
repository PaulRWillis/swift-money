/// One of the four rounding rules that name a direction, IEEE 754's directed roundings.
///
/// A directed rule takes the neighbor on one side whatever the distance, so it can find none, such
/// as `.up` for an amount above the highest step. A rounding that can fail that way takes a
/// directed rule rather than a ``RoundingRule``:
///
/// ```swift
/// try steps.index(approximating: saved, rounding: .down)
/// ```
///
/// - Note: `down` and `up` name a direction on the number line, not a size. On a negative amount
///   `down` moves *away* from zero and `up` moves toward it, which is the reverse of what "round
///   down" and "round up" mean in everyday speech.
public enum DirectedRoundingRule: Equatable, Hashable, Sendable {
    /// Toward negative infinity, as ``RoundingRule/down`` does.
    case down

    /// Toward positive infinity, as ``RoundingRule/up`` does.
    case up

    /// Toward the neighbor smaller in size, as ``RoundingRule/towardZero`` does.
    case towardZero

    /// Toward the neighbor larger in size, as ``RoundingRule/awayFromZero`` does.
    case awayFromZero
}

public extension DirectedRoundingRule {
    /// Creates the directed rule of the same name, or `nil` for a nearest rounding rule.
    ///
    /// ```swift
    /// DirectedRoundingRule(RoundingRule.down)              // .down
    /// DirectedRoundingRule(RoundingRule.toNearestOrEven)   // nil
    /// ```
    ///
    /// - Parameter rule: The rounding rule to convert.
    /// - Returns: The directed rule `rule` names, or `nil` if `rule` is a nearest rule.
    init?(_ rule: RoundingRule) {
        switch rule {
        case .down: self = .down
        case .up: self = .up
        case .towardZero: self = .towardZero
        case .awayFromZero: self = .awayFromZero
        case .toNearestOrEven, .toNearestOrAwayFromZero: return nil
        }
    }
}

public extension RoundingRule {
    /// Creates the rounding rule of the same name as a directed rule.
    ///
    /// ```swift
    /// RoundingRule(DirectedRoundingRule.down)   // .down
    /// ```
    ///
    /// - Parameter rule: The directed rule to convert.
    init(_ rule: DirectedRoundingRule) {
        switch rule {
        case .down: self = .down
        case .up: self = .up
        case .towardZero: self = .towardZero
        case .awayFromZero: self = .awayFromZero
        }
    }
}
