/// A count of fraction digits to show, from `0` to `19`.
///
/// ```swift
/// let length: FractionLength = 2    // fine
/// let bad: FractionLength = -1      // traps
/// ```
public struct FractionLength: Equatable, Hashable, Sendable {
    @usableFromInline
    let rawValue: Int

    /// The most fraction digits a length can hold. Nineteen is the ceiling the display engine works
    /// to: padding a fraction multiplies by a power of ten held in a `UInt64`, and `10^19` is the
    /// largest power of ten that still fits — `10^20` overflows. A length beyond this could never be
    /// rendered, so it is unrepresentable rather than caught later as a formatting-time trap.
    private static let maxFractionDigits = 19

    /// Creates a fraction length, or `nil` unless `value` is `0` to `19`.
    public init?(exactly value: Int) {
        guard (0 ... Self.maxFractionDigits).contains(value) else {
            return nil
        }

        self.rawValue = value
    }
}

extension FractionLength: ExpressibleByIntegerLiteral {
    /// Creates a fraction length from an integer literal.
    ///
    /// - Precondition: `value` is `0` to `19`.
    public init(integerLiteral value: Int) {
        guard let length = Self(exactly: value) else {
            preconditionFailure("A fraction length must be 0 to 19. Value: \(value)")  // coverage:ignore
        }

        self = length
    }
}

public extension Int {
    /// The number of fraction digits.
    init(_ length: FractionLength) {
        self = length.rawValue
    }
}
