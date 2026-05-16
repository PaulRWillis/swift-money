import Foundation

/// A discrete count of the smallest indivisible monetary unit.
///
/// `MinorUnit` wraps an `Int64`, rejecting `Int64.min` at construction
/// because its negation overflows — an invariant required by magnitude,
/// negate, and effective-rate computations. Valid range:
/// `Int64.min + 1 ... Int64.max`.
///
/// ```swift
/// MinorUnit(exactly: 150) // 150
/// ```
///
/// ## Parse Boundary
///
/// `MinorUnit` acts as a parse boundary: untrusted input (decoded JSON,
/// user entry, cross-module calls) is validated once at construction.
/// Downstream code can assume negation is safe without further checks.
struct MinorUnit: Sendable {

    // MARK: - Storage

    typealias Storage = Int64

    let _storage: Storage

    // MARK: - Initialisers

    /// Creates a `MinorUnit` from a `BinaryInteger`, returning `nil` if
    /// the value does not fit in `Int64` or equals `Int64.min`.
    ///
    /// ```swift
    /// MinorUnit(exactly: 42)           // MinorUnit(42)
    /// MinorUnit(exactly: Int128.max)   // nil
    /// MinorUnit(exactly: Int64.min)    // nil
    /// ```
    init?<T: BinaryInteger>(exactly value: T) {
        guard let storage = Storage(exactly: value), storage != .min else { return nil }
        self._storage = storage
    }
}

// MARK: - Static Properties

extension MinorUnit {

    /// The zero value.
    static let zero = MinorUnit(integerLiteral: 0)

    /// The minimum representable value (`Int64.min + 1`).
    static let min = MinorUnit(integerLiteral: Storage.min + 1)

    /// The maximum representable value (`Int64.max`).
    static let max = MinorUnit(integerLiteral: .max)
}

// MARK: - Equatable

extension MinorUnit: Equatable {}

// MARK: - Comparable

extension MinorUnit: Comparable {
    static func < (lhs: MinorUnit, rhs: MinorUnit) -> Bool {
        lhs._storage < rhs._storage
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension MinorUnit: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Storage) {
        guard let minorUnit = MinorUnit(exactly: value) else {
            preconditionFailure("MinorUnit cannot represent Storage.min")
        }
        self = minorUnit
    }
}

// MARK: - Int64 Conversion

extension Int64 {
    /// Creates an `Int64` from a `MinorUnit`.
    ///
    /// ```swift
    /// let minorUnit = MinorUnit(exactly: 150)!
    /// Int64(minorUnit)  // 150
    /// ```
    init(_ minorUnit: MinorUnit) {
        self = minorUnit._storage
    }
}
