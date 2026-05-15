/// A discrete count of the smallest indivisible monetary unit.
///
/// `MinorUnit` wraps an `Int64`, rejecting `Int64.min` at construction
/// because its negation overflows — an invariant required by magnitude,
/// negate, and effective-rate computations. Valid range:
/// `Int64.min + 1 ... Int64.max`.
///
/// ```swift
/// let mu: MinorUnit = 150
/// Int64(mu)  // 150
/// ```
///
/// ## Parse Boundary
///
/// `MinorUnit` acts as a parse boundary: untrusted input (decoded JSON,
/// user entry, cross-module calls) is validated once at construction.
/// Downstream code can assume negation is safe without further checks.
///
/// ## Integer Literals
///
/// `MinorUnit` may be created from an integer literal wherever the type
/// is unambiguous:
///
/// ```swift
/// let price = Money<GBP>(minorUnits: 150)
/// ```
public struct MinorUnit: Sendable {

    // MARK: - Storage

    @usableFromInline
    internal typealias Storage = Int64

    @usableFromInline
    internal let _storage: Storage

    // MARK: - Initialisers

    /// Creates a `MinorUnit` from a `BinaryInteger`, returning `nil` if
    /// the value does not fit in `Int64` or equals `Int64.min`.
    ///
    /// ```swift
    /// MinorUnit(exactly: 42)           // MinorUnit(42)
    /// MinorUnit(exactly: Int128.max)   // nil
    /// MinorUnit(exactly: Int64.min)    // nil
    /// ```
    @inlinable
    public init?<T: BinaryInteger>(exactly value: T) {
        guard let storage = Storage(exactly: value), storage != .min else { return nil }
        self._storage = storage
    }

}

// MARK: - Static Properties

extension MinorUnit {

    /// The zero value.
    public static let zero = MinorUnit(integerLiteral: 0)

    /// The maximum representable value (`Int64.max`).
    public static let max = MinorUnit(integerLiteral: Storage.max)

    /// The minimum representable value (`Int64.min + 1`).
    public static let min = MinorUnit(integerLiteral: Storage.min + 1)
}

// MARK: - Equatable

extension MinorUnit: Equatable {
    @inlinable
    public static func == (lhs: MinorUnit, rhs: MinorUnit) -> Bool {
        lhs._storage == rhs._storage
    }
}

// MARK: - Comparable

extension MinorUnit: Comparable {
    @inlinable
    public static func < (lhs: MinorUnit, rhs: MinorUnit) -> Bool {
        lhs._storage < rhs._storage
    }
}

// MARK: - Hashable

extension MinorUnit: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_storage)
    }
}

// MARK: - CustomStringConvertible

extension MinorUnit: CustomStringConvertible {
    public var description: String { _storage.description }
}

// MARK: - CustomDebugStringConvertible

extension MinorUnit: CustomDebugStringConvertible {
    public var debugDescription: String { "MinorUnit(\(_storage))" }
}

// MARK: - Codable

extension MinorUnit: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Storage.self)
        guard let minorUnit = MinorUnit(exactly: value) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "MinorUnit cannot represent Int64.min (decoded \(value))"
            )
        }
        self = minorUnit
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_storage)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension MinorUnit: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: Int64) {
        guard let minorUnit = MinorUnit(exactly: value) else {
            preconditionFailure("MinorUnit cannot represent Int64.min")
        }
        self = minorUnit
    }
}

// MARK: - Int64 Conversion

extension Int64 {
    /// Creates an `Int64` from a `MinorUnit`.
    ///
    /// ```swift
    /// let minorUnit = MinorUnit(150)
    /// Int64(minorUnit)  // 150
    /// ```
    @inlinable
    public init(_ minorUnit: MinorUnit) {
        self = minorUnit._storage
    }
}
