/// The number of recipients in a monetary distribution.
///
/// `DistributionParts` wraps an `Int` that must be at least 1, encoding the
/// rule that distributing into zero or negative parts makes no sense.
/// The underlying storage is `internal` so it can be changed without a
/// public-API break; callers access the primitive value through ``intValue``
/// or the `Int` conversion initialiser:
///
/// ```swift
/// let parts = DistributionParts(3)
/// parts.intValue   // 3
/// Int(parts)       // 3
/// ```
public struct DistributionParts: Sendable {

    // MARK: - Storage (internal — not part of the public API)

    /// The underlying integer value. Internal so the representation
    /// can evolve without a public-API break.
    internal let _value: Int

    // MARK: - Initialiser

    /// Creates a `DistributionParts` from the given integer.
    ///
    /// - Parameter n: The number of recipients; must be ≥ 1.
    /// - Precondition: `n` must be at least 1.
    public init(_ n: Int) {
        precondition(n >= 1, "DistributionParts must be at least 1; got \(n)")
        _value = n
    }

    // MARK: - Public access to underlying value

    /// The number of parts as a plain `Int`.
    public var intValue: Int { _value }
}

// MARK: - Int conversion

extension Int {
    /// Creates an `Int` from a `DistributionParts`.
    ///
    /// ```swift
    /// let parts = DistributionParts(3)
    /// Int(parts)  // 3
    /// ```
    public init(_ parts: DistributionParts) {
        self = parts._value
    }
}
