/// A validated currency code string.
///
/// `CurrencyCode` wraps a `String` to guarantee it is never empty. The
/// underlying storage is intentionally `internal` so it can be changed
/// in a future version without a public-API break. Callers access the
/// primitive value exclusively through ``stringValue`` or the `String`
/// conversion initialiser:
///
/// ```swift
/// let code = CurrencyCode("GBP")
/// code.stringValue          // "GBP"
/// String(code)              // "GBP"
/// ```
///
/// ## Custom currencies
///
/// Any non-empty string is a valid currency code, enabling ISO 4217 codes
/// (`GBP`, `EUR`, `USD`), crypto codes (`BTC`, `SAT`), and in-app
/// currencies (`GEMS`, `TOKENS`, `TST_100`).
///
/// ## String literals
///
/// `CurrencyCode` may be created from a string literal wherever the
/// type is unambiguous:
///
/// ```swift
/// let code: CurrencyCode = "GBP"
/// ```
///
/// The same empty-string precondition applies when literals are used at
/// runtime; an empty literal is caught at compile time by the Swift type
/// checker.
public struct CurrencyCode: Sendable {

    // MARK: - Storage (internal — not part of the public API)

    /// The underlying string value. Internal so the representation
    /// can evolve without a public-API break.
    internal let _value: String

    // MARK: - Initialiser

    /// Creates a `CurrencyCode` from the given string.
    ///
    /// - Parameter string: A non-empty currency code string.
    /// - Precondition: `string` must not be empty.
    public init(_ string: String) {
        precondition(!string.isEmpty, "CurrencyCode cannot be empty")
        self._value = string
    }

    // MARK: - Public access to underlying value

    /// The currency code as a plain `String`.
    ///
    /// Use this when a raw `String` is required, for example when calling
    /// Foundation formatting APIs:
    ///
    /// ```swift
    /// let code = CurrencyCode("GBP")
    /// amount.formatted(.currency(code: code.stringValue))
    /// ```
    public var stringValue: String { _value }
}

// MARK: - Equatable

extension CurrencyCode: Equatable {
    public static func == (lhs: CurrencyCode, rhs: CurrencyCode) -> Bool {
        lhs._value == rhs._value
    }
}

// MARK: - Hashable

extension CurrencyCode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_value)
    }
}

// MARK: - Comparable

extension CurrencyCode: Comparable {
    /// Compares two currency codes lexicographically by their string values.
    public static func < (lhs: CurrencyCode, rhs: CurrencyCode) -> Bool {
        lhs._value < rhs._value
    }
}

// MARK: - Codable

extension CurrencyCode: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard !string.isEmpty else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "CurrencyCode cannot be empty"
            )
        }
        self._value = string
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_value)
    }
}

// MARK: - CustomStringConvertible

extension CurrencyCode: CustomStringConvertible {
    /// The currency code string, e.g. `"GBP"`.
    public var description: String { _value }
}

// MARK: - ExpressibleByStringLiteral

extension CurrencyCode: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - String conversion

extension String {
    /// Creates a `String` from a `CurrencyCode`.
    ///
    /// ```swift
    /// let code = CurrencyCode("GBP")
    /// String(code)  // "GBP"
    /// ```
    public init(_ code: CurrencyCode) {
        self = code.stringValue
    }
}
