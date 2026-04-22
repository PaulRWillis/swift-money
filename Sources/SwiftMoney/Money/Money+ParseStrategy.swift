#if canImport(Foundation)
import Foundation

// MARK: - ParseStrategy

extension Money {

    /// A parse strategy that reconstructs a `Money` value from a formatted
    /// currency string produced by `Money.FormatStyle`.
    ///
    /// Obtain a strategy through `Money<C>.FormatStyle.parseStrategy` or the
    /// `ParseableFormatStyle` conformance; do not initialise directly.
    ///
    /// ```swift
    /// let style = Money<GBP>.FormatStyle(locale: Locale(identifier: "en_GB"))
    /// let pounds = try style.parseStrategy.parse("£1.50")
    /// // pounds == Money<GBP>(minorUnits: 150)
    /// ```
    ///
    /// ## Round-trip guarantee
    ///
    /// Any string produced by the corresponding `FormatStyle.format(_:)` will
    /// parse back to the original value:
    ///
    /// ```swift
    /// let style = Money<GBP>.FormatStyle(locale: Locale(identifier: "en_GB"))
    /// let original = Money<GBP>(minorUnits: 1234)
    /// let string   = style.format(original)           // "£12.34"
    /// let parsed   = try style.parseStrategy.parse(string)
    /// // parsed == original
    /// ```
    public struct ParseStrategy: Foundation.ParseStrategy, Codable, Hashable, Sendable {

        public typealias ParseInput  = String
        public typealias ParseOutput = Money<Currency>

        internal let formatStyle: Money<Currency>.FormatStyle

        internal init(formatStyle: Money<Currency>.FormatStyle) {
            self.formatStyle = formatStyle
        }

        /// Parses `value` and returns the corresponding `Money`.
        ///
        /// Delegates all arithmetic to `FormatStyle._parse(_:)`, which has
        /// direct access to the private stored `userScale` property.
        ///
        /// - Parameter value: A string in the format produced by the associated
        ///   `Money.FormatStyle`.
        /// - Returns: The `Money` value whose `format()` output matches `value`.
        /// - Throws: A Foundation `ParseError` if `value` does not match the
        ///   expected format, or ``ParseError/overflow`` if the result is
        ///   outside the `Int64` representable range.
        public func parse(_ value: String) throws -> Money<Currency> {
            try formatStyle._parse(value)
        }
    }
}

// MARK: - ParseError

extension Money.ParseStrategy {

    /// Errors thrown when a `Money.ParseStrategy` cannot parse an input string.
    public enum ParseError: Error, LocalizedError, Sendable {

        /// The parsed integer value is outside the `Int64` representable range,
        /// or equals the internal NaN sentinel (`Int64.min`).
        case overflow

        public var errorDescription: String? {
            switch self {
            case .overflow:
                return "The parsed value cannot be represented as a Money amount (Int64 overflow or NaN sentinel)."
            }
        }
    }
}

// MARK: - ParseableFormatStyle conformance

extension Money.FormatStyle: ParseableFormatStyle {
    /// The parse strategy derived from this format style.
    ///
    /// The returned strategy uses the same ICU skeleton parameters as
    /// `format(_:)`, guaranteeing a correct format ↔ parse round-trip.
    public var parseStrategy: Money<Currency>.ParseStrategy {
        Money<Currency>.ParseStrategy(formatStyle: self)
    }
}

// MARK: - Convenience initialiser

extension Money {

    /// Creates a `Money` value by parsing a formatted currency string.
    ///
    /// ```swift
    /// let style = Money<GBP>.FormatStyle(locale: Locale(identifier: "en_GB"))
    /// let money = try Money<GBP>("£12.34", format: style)
    /// money.minorUnits  // 1234
    /// ```
    ///
    /// - Parameters:
    ///   - string: A string in the format produced by `format`.
    ///   - format: The `Money.FormatStyle` used to interpret the string.
    /// - Throws: A parse error if `string` does not match `format`.
    public init(_ string: String, format: Money<Currency>.FormatStyle) throws {
        self = try format.parseStrategy.parse(string)
    }
}
#endif
