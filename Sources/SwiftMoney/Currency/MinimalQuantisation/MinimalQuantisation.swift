/// The number of minor units per major unit for a currency.
///
/// `MinimalQuantisation` wraps an `Int64` that must be strictly positive,
/// encoding the rule that a zero or negative quantisation makes no sense
/// as a monetary denomination. The underlying storage is `internal` so it
/// can be changed without a public-API break; callers access the primitive
/// value through ``int64Value`` or the `Int64` conversion initialiser:
///
/// ```swift
/// let q = MinimalQuantisation(100)
/// q.int64Value          // 100
/// Int64(q)              // 100
/// ```
///
/// ## Meaning
///
/// The value represents how many minimal units make one major unit. For
/// example:
///
/// | Currency | Value | Meaning |
/// |----------|-------|---------|
/// | GBP      | 100   | 100 pence = £1 |
/// | JPY      | 1     | 1 yen = ¥1 (no minor units) |
/// | BTC      | 100_000_000 | 10⁸ satoshis = 1 BTC |
///
/// A value of `0` is rejected at initialisation time, preventing the
/// division-by-zero crash that would otherwise occur in Decimal conversions.
///
/// ## Integer literals
///
/// `MinimalQuantisation` may be created from an integer literal wherever
/// the type is unambiguous, allowing clean currency declarations:
///
/// ```swift
/// static var minimalQuantisation: MinimalQuantisation { 100 }
/// ```
public struct MinimalQuantisation: Equatable, Hashable, Sendable {
    private typealias Storage = Int64

    /// The underlying integer value. Internal so the representation
    /// can evolve without a public-API break.
    private let _storage: Storage

    var int64Value: Int64 {
        _storage
    }

    // MARK: - Initializer

    /// Creates a `MinimalQuantisation` from the given integer.
    ///
    /// - Parameter value: A strictly positive integer (> 0).
    /// - Precondition: `value` must be greater than zero.
    public init(_ int64: Int64) {
        guard let s = Self.parse(int64) else {
            preconditionFailure("MinimalQuantisation must be > 0 (got \(int64))")
        }
        self = s
    }

    private init(unsafeValue: Storage) {
        self._storage = unsafeValue
    }

    private static func parse(_ value: Storage) -> Self? {
        guard value > 0 else { return nil }

        return Self(unsafeValue: value)
    }
}

// MARK: - Codable

extension MinimalQuantisation: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int64.self)

        guard let s = Self.parse(value) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "MinimalQuantisation must be > 0 (decoded \(value))"
            )
        }
        self = s
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_storage)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension MinimalQuantisation: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) {
        self.init(value)
    }
}

// MARK: - CustomStringConvertible

extension MinimalQuantisation: CustomStringConvertible {
    /// The quantisation as a string integer, e.g. `"100"`.
    public var description: String { String(_storage) }
}

// MARK: - Int64 conversion

extension Int64 {
    /// Creates an `Int64` from a `MinimalQuantisation`.
    ///
    /// ```swift
    /// let q = MinimalQuantisation(100)
    /// Int64(q)  // 100
    /// ```
    public init(_ quantisation: MinimalQuantisation) {
        self = quantisation.int64Value
    }
}
