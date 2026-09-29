/// How to resolve part of a unit into a whole one.
///
/// The four rules that name a direction ignore how large the leftover part is; the two that name a
/// nearest choose by it, and differ only in how they break an exact tie.
///
/// - Note: `down` and `up` name a direction on the number line, not a size. On a negative amount
///   `down` moves *away* from zero and `up` moves toward it, which is the reverse of what "round
///   down" and "round up" mean in everyday speech.
///
/// - Note: The vocabulary **inverts** against the decimal arithmetic test suite this library's
///   rounding is validated with. Their `ROUND_DOWN` truncates toward zero, where `down` here moves
///   toward negative infinity:
///
///   | This library | decTest |
///   |---|---|
///   | `towardZero` | `ROUND_DOWN` |
///   | `awayFromZero` | `ROUND_UP` |
///   | `down` | `ROUND_FLOOR` |
///   | `up` | `ROUND_CEILING` |
///   | `toNearestOrEven` | `ROUND_HALF_EVEN` |
///   | `toNearestOrAwayFromZero` | `ROUND_HALF_UP` |
public enum RoundingRule: Equatable, Hashable, Sendable {
    case towardZero
    case awayFromZero
    case down
    case up
    case toNearestOrEven
    case toNearestOrAwayFromZero
}

public extension RoundingRule {
    /// The rule a standard-library rounding rule names, or `nil` for one this library doesn't have.
    ///
    /// ```swift
    /// RoundingRule(FloatingPointRoundingRule.toNearestOrEven)   // .toNearestOrEven
    /// ```
    init?(_ rule: FloatingPointRoundingRule) {
        switch rule {
        case .towardZero: self = .towardZero
        case .awayFromZero: self = .awayFromZero
        case .down: self = .down
        case .up: self = .up
        case .toNearestOrEven: self = .toNearestOrEven
        case .toNearestOrAwayFromZero: self = .toNearestOrAwayFromZero
        @unknown default: return nil   // coverage:ignore — only a future standard-library rule
        }
    }
}

public extension FloatingPointRoundingRule {
    /// The standard-library rule of the same name, for `Double.rounded(_:)` and Foundation's formatters.
    ///
    /// ```swift
    /// 2.5.rounded(FloatingPointRoundingRule(RoundingRule.toNearestOrEven))   // 2.0
    /// ```
    init(_ rule: RoundingRule) {
        switch rule {
        case .towardZero: self = .towardZero
        case .awayFromZero: self = .awayFromZero
        case .down: self = .down
        case .up: self = .up
        case .toNearestOrEven: self = .toNearestOrEven
        case .toNearestOrAwayFromZero: self = .toNearestOrAwayFromZero
        }
    }
}

#if !hasFeature(Embedded)

extension RoundingRule: Codable {
    /// Writes the rule as the integer Foundation writes for the same `FloatingPointRoundingRule`, so data
    /// written before this type was the library's own still reads.
    ///
    /// ```swift
    /// try encoder.encode(RoundingRule.toNearestOrEven)   // 1
    /// ```
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(codedValue)
    }

    /// Reads a rule from the integer Foundation writes for it.
    ///
    /// - Throws: `DecodingError.dataCorrupted` for an integer that names no rule.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)

        guard let rule = RoundingRule(codedValue: value) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Not a rounding rule: \(value). A rule is written as 0 to 5."
            )
        }

        self = rule
    }
}

private extension RoundingRule {
    // Foundation's numbering, which follows the standard library's declaration order, not this type's.
    var codedValue: Int {
        switch self {
        case .toNearestOrAwayFromZero: 0
        case .toNearestOrEven: 1
        case .up: 2
        case .down: 3
        case .towardZero: 4
        case .awayFromZero: 5
        }
    }

    init?(codedValue: Int) {
        switch codedValue {
        case 0: self = .toNearestOrAwayFromZero
        case 1: self = .toNearestOrEven
        case 2: self = .up
        case 3: self = .down
        case 4: self = .towardZero
        case 5: self = .awayFromZero
        default: return nil
        }
    }
}

#endif
