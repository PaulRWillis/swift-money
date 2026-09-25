/// A custom currency's name in full, such as "point" or "coins".
///
/// Never empty: a name with no text would name a currency as nothing, so that value cannot be built. A
/// string literal is the programmer's own input, so an empty one traps; ``init(_:)`` takes a string
/// from outside the program and returns `nil` instead.
///
/// ```swift
/// let coins: CurrencyName = "coins"     // fine
/// CurrencyName("")                      // nil
/// ```
public struct CurrencyName: Equatable, Hashable, Sendable, ExpressibleByStringLiteral {
    // The name's text, read by the builder that renders it. Not public: a caller passes a name in and
    // never needs to read one back.
    package let rawValue: String

    /// Creates a name from a string, or `nil` if it is empty.
    ///
    /// Use this for a name from outside the program, where an empty one is bad input rather than a
    /// mistake in the source.
    ///
    /// - Parameter text: The name's text.
    /// - Returns: `nil` if `text` is empty.
    public init?(_ text: String) {
        guard !text.isEmpty else {
            return nil
        }

        self.rawValue = text
    }

    /// Creates a name from a string literal, trapping on an empty literal.
    ///
    /// - Parameter value: The name's text.
    /// - Precondition: `value` is not empty.
    public init(stringLiteral value: String) {
        guard let name = Self(value) else {
            preconditionFailure("A currency name must not be empty.")  // coverage:ignore
        }

        self = name
    }
}
