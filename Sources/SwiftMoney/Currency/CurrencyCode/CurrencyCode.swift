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
public struct CurrencyCode: Equatable, Hashable, Sendable {
    private let _storage: String

    // MARK: - Initializer

    /// Creates a `CurrencyCode` from the given string.
    ///
    /// - Parameter string: A non-empty currency-code string.
    /// - Precondition: `string` must not be empty.
    public init(_ string: String) {
        guard string.isValidCurrencyCode else {
            preconditionFailure("CurrencyCode cannot be empty")
        }
        self._storage = string
    }

    // MARK: - Public access to underlying value

    #warning("Remove `CurrencyCode.stringValue`")
    /// The currency code as a plain `String`.
    ///
    /// Use this when a raw `String` is required, for example when calling
    /// Foundation formatting APIs:
    ///
    /// ```swift
    /// let code = CurrencyCode("GBP")
    /// amount.formatted(.currency(code: code.stringValue))
    /// ```
    public var stringValue: String { _storage }
}

private extension String {
    var isValidCurrencyCode: Bool {
        !self.isEmpty
    }
}

// MARK: - Comparable

extension CurrencyCode: Comparable {
    /// Compares two currency codes lexicographically by their string values.
    public static func < (lhs: CurrencyCode, rhs: CurrencyCode) -> Bool {
        lhs._storage < rhs._storage
    }
}

// MARK: - Codable

extension CurrencyCode: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard string.isValidCurrencyCode else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "CurrencyCode cannot be empty"
            )
        }
        self._storage = string
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_storage)
    }
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

// MARK: - CustomStringConvertible

extension CurrencyCode: CustomStringConvertible {
    /// The currency code string, e.g. `"GBP"`.
    public var description: String { _storage }
}
