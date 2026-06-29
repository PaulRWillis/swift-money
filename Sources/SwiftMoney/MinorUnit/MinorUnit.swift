import Foundation

/// A discrete count of the smallest indivisible monetary unit.
struct MinorUnit: Equatable, Hashable, Sendable {
    fileprivate let _storage: Int

    // MARK: - Initializers

    /// Creates a `MinorUnit` from a `BinaryInteger`.
    ///
    /// ```swift
    /// MinorUnit(exactly: 42)           // MinorUnit(42)
    /// MinorUnit(exactly: Int128.max)   // nil
    /// ```
    init?<T: BinaryInteger>(exactly value: T) {
        guard let storage = Int(exactly: value), storage != .min else { return nil }
        self._storage = storage
    }
}

// MARK: - Static Properties

extension MinorUnit {
    /// The zero value.
    static let zero = MinorUnit(integerLiteral: 0)

    /// The minimum representable value (`Int64.min + 1`).
    static let min = MinorUnit(integerLiteral: Int.min + 1)

    /// The maximum representable value (`Int64.max`).
    static let max = MinorUnit(integerLiteral: .max)
}

// MARK: - Comparable

extension MinorUnit: Comparable {
    static func < (lhs: MinorUnit, rhs: MinorUnit) -> Bool {
        lhs._storage < rhs._storage
    }
}

// MARK: - CustomStringConvertible

extension MinorUnit: CustomStringConvertible {
    var description: String { String(_storage) }
}

// MARK: - CustomDebugStringConvertible

extension MinorUnit: CustomDebugStringConvertible {
    var debugDescription: String { "\(Self.self)(\(_storage))" }
}

// MARK: - Codable

extension MinorUnit: Codable {
    init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        guard let minorUnit = MinorUnit(exactly: value) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath,
                      debugDescription: "MinorUnit cannot represent \(value)")
            )
        }
        self = minorUnit
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_storage)
    }
}

// MARK: - AdditiveArithmetic

extension MinorUnit: AdditiveArithmetic {
    static func + (lhs: MinorUnit, rhs: MinorUnit) -> MinorUnit {
        MinorUnit(integerLiteral: lhs._storage + rhs._storage)
    }

    static func - (lhs: MinorUnit, rhs: MinorUnit) -> MinorUnit {
        MinorUnit(integerLiteral: lhs._storage - rhs._storage)
    }
}

// MARK: - Negation

extension MinorUnit {
    static prefix func - (operand: MinorUnit) -> MinorUnit {
        MinorUnit(integerLiteral: -operand._storage)
    }

    mutating func negate() {
        self = -self
    }
}

// MARK: - Scalar Multiplication

extension MinorUnit {
    static func * (lhs: MinorUnit, rhs: Int) -> MinorUnit {
        MinorUnit(integerLiteral: lhs._storage * rhs)
    }

    static func * (lhs: Int, rhs: MinorUnit) -> MinorUnit {
        rhs * lhs
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension MinorUnit: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        guard let minorUnit = MinorUnit(exactly: value) else {
            preconditionFailure("MinorUnit cannot represent Int.min")
        }
        self = minorUnit
    }
}

// MARK: - Int Conversion

extension Int {
    /// Creates an `Int` from a `MinorUnit`.
    ///
    /// ```swift
    /// let minorUnit = MinorUnit(exactly: 150)!
    /// Int(minorUnit)  // 150
    /// ```
    init(_ minorUnit: MinorUnit) {
        self = minorUnit._storage
    }
}

extension Int64 {
    /// Creates an `Int64` from a `MinorUnit`.
    ///
    /// ```swift
    /// let minorUnit = MinorUnit(exactly: 150)!
    /// Int64(minorUnit)  // 150
    /// ```
    init(_ minorUnit: MinorUnit) {
        self = Int64(minorUnit._storage)
    }
}
