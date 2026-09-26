/// A currency's symbol, such as a gem glyph (`💎`) or a letters code (`GEM`).
///
/// Never empty: a symbol with no text would render a currency as nothing, so that value cannot be
/// built. A string literal is the programmer's own input, so an empty one traps; ``init(_:)`` takes a
/// string from outside the program and returns `nil` instead.
///
/// ```swift
/// let gem: CurrencySymbol = "💎"        // fine
/// CurrencySymbol("")                    // nil
/// ```
public struct CurrencySymbol: Equatable, Hashable, Sendable, ExpressibleByStringLiteral {
    // The symbol's text, read by the builder that renders it. Not public: a caller passes a symbol in
    // and never needs to read one back.
    package let rawValue: String

    /// Creates a symbol from a string, or `nil` if it is empty.
    ///
    /// Use this for a symbol from outside the program, where an empty one is bad input rather than a
    /// mistake in the source.
    ///
    /// - Parameter text: The symbol's text.
    /// - Returns: `nil` if `text` is empty.
    public init?(_ text: String) {
        guard !text.isEmpty else {
            return nil
        }

        self.rawValue = text
    }

    /// Creates a symbol from a string literal, trapping on an empty literal.
    ///
    /// - Parameter value: The symbol's text.
    /// - Precondition: `value` is not empty.
    public init(stringLiteral value: String) {
        guard let symbol = Self(value) else {
            preconditionFailure("A currency symbol must not be empty.")  // coverage:ignore
        }

        self = symbol
    }
}
