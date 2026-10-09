/// A value that is never zero.
@usableFromInline
struct NonZero<Value: ZeroRepresentable & Hashable & Sendable>: Equatable, Hashable, Sendable {
    /// The value, never zero.
    @usableFromInline
    let rawValue: Value

    /// Creates a non-zero value, or `nil` if the value is zero.
    ///
    /// - Parameter value: The value, which may be zero.
    /// - Returns: `nil` if `value` is zero.
    @inlinable
    init?(_ value: Value) {
        guard value != .zero else {
            return nil
        }

        self.rawValue = value
    }

    /// Creates a non-zero value without checking it.
    ///
    /// - Parameter value: The value, which the caller already knows is not zero.
    @inlinable
    init(unchecked value: Value) {
        self.rawValue = value
    }

    /// Returns whether two non-zero values are equal.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: `true` if the values are equal; otherwise, `false`.
    @inlinable
    static func == (lhs: Self, rhs: Self) -> Bool {
        // Hand-written, with `hash(into:)`, because the synthesized ones don't specialize across
        // modules.
        lhs.rawValue == rhs.rawValue
    }

    /// Hashes the value into a hasher.
    ///
    /// - Parameter hasher: The hasher to feed the value into.
    @inlinable
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension NonZero where Value: SignedInteger {
    /// `-1` if this value is negative and `1` if it's positive.
    @inlinable
    var signum: Value {
        rawValue < 0 ? -1 : 1
    }
}
