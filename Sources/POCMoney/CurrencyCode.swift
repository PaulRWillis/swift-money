/// The code identifying a currency, such as `GBP`.
///
/// Three to eight characters, letters `A`–`Z` and digits `0`–`9` only. Lowercase input is accepted
/// and normalized, so `"gbp"` and `"GBP"` are the same currency.
///
/// The rule is deliberately wider than ISO 4217's three letters, so that currencies outside the
/// standard — `USDT`, `SAFEMOON`, or an in-app `GEMS` — are expressible. It is not wide enough for
/// every token symbol in circulation: some contain punctuation, emoji, or non-Latin scripts, and a
/// rule permitting those would validate nothing.
public struct CurrencyCode: Equatable, Hashable, Sendable {
    fileprivate let rawValue: String

    /// Creates a currency code from a string that may not be valid.
    ///
    /// Use this for codes that come from outside the program — user input, a database, an API
    /// response.
    ///
    /// Lowercase input is normalized, so the code created is not always the string passed in.
    ///
    /// - Parameter string: The code, in any case.
    /// - Returns: `nil` unless `string` is three to eight characters of `A`–`Z`, `a`–`z` or `0`–`9`.
    public init?(string: String) {
        guard let validated = Self.validated(string) else {
            return nil
        }

        self.rawValue = validated
    }

    // No check: only for call sites that have already validated the string.
    internal init(unchecked string: String) {
        self.rawValue = string
    }

    // Validates before uppercasing, not after. `"ß".uppercased()` is `"SS"`, so uppercasing first
    // would let a two-character non-ASCII input satisfy both the character and the length rule.
    private static func validated(_ string: String) -> String? {
        guard (3...8).contains(string.count) else {
            return nil
        }

        guard string.utf8.allSatisfy(\.isASCIIAlphanumeric) else {
            return nil
        }

        return string.uppercased()
    }
}

// Deliberately byte-level rather than `Character.isLetter`/`.isNumber`, which are true for
// Arabic-Indic, Devanagari, fullwidth and other non-Latin digits. Here the permitted set is
// structural: `isASCIIDigit` cannot mean anything but `0`–`9`.
private extension UInt8 {
    var isASCIIUppercase: Bool {
        (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains(self)
    }

    var isASCIILowercase: Bool {
        (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(self)
    }

    var isASCIIDigit: Bool {
        (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(self)
    }

    var isASCIIAlphanumeric: Bool {
        isASCIIUppercase || isASCIILowercase || isASCIIDigit
    }
}

extension CurrencyCode: ExpressibleByStringLiteral {
    /// Creates a currency code from a string literal.
    ///
    /// A literal is written by a programmer rather than derived from data, so an invalid one is a
    /// mistake in the source rather than bad input — it traps instead of failing gracefully. Use
    /// ``init(string:)`` for any string that is not a literal.
    ///
    /// ```swift
    /// let gbp: CurrencyCode = "GBP"    // fine
    /// let oops: CurrencyCode = "£"     // traps
    /// ```
    ///
    /// - Parameter value: The code, in any case.
    /// - Precondition: `value` is three to eight characters of `A`–`Z`, `a`–`z` or `0`–`9`.
    public init(stringLiteral value: String) {
        guard let validated = Self.validated(value) else {
            preconditionFailure("Not a valid currency code: \(value)")
        }

        self.rawValue = validated
    }
}

extension CurrencyCode: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

public extension String {
    /// Creates a string from a currency code.
    init(_ code: CurrencyCode) {
        self = code.rawValue
    }
}
