#if canImport(Foundation)
import Foundation

// MARK: - ParseStrategy

extension FractionalRate {

    /// A parse strategy that reconstructs a `FractionalRate` from a formatted string.
    ///
    /// The strategy auto-detects the input format:
    /// - Strings containing `"/"` are parsed as fractions (`"3/4"` → 3/4).
    /// - Strings containing `"%"` are parsed as percentages (`"75%"` → 3/4).
    /// - Otherwise the string is parsed as a decimal number (`"0.75"` → 3/4).
    ///
    /// ```swift
    /// let style = FractionalRate.FormatStyle(.fraction)
    /// let rate  = try style.parseStrategy.parse("3/4")
    /// // rate == FractionalRate(numerator: 3, denominator: 4)!
    /// ```
    public struct ParseStrategy: Foundation.ParseStrategy, Codable, Hashable, Sendable {

        public typealias ParseInput  = String
        public typealias ParseOutput = FractionalRate

        private var locale: Locale

        /// Creates a parse strategy with the given locale.
        ///
        /// The locale is used when parsing decimal and percentage strings.
        /// Fraction strings (`"3/4"`) are always parsed locale-independently.
        ///
        /// - Parameter locale: The locale for number parsing. Defaults to
        ///   `.autoupdatingCurrent`.
        public init(locale: Locale = .autoupdatingCurrent) {
            self.locale = locale
        }

        /// Parses `value` and returns the corresponding `FractionalRate`.
        ///
        /// - Parameter value: A string in one of the supported formats.
        /// - Returns: The parsed `FractionalRate`.
        /// - Throws: ``ParseError`` if the string cannot be parsed.
        public func parse(_ value: String) throws -> FractionalRate {
            let trimmed = value.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { throw ParseError.invalidInput }

            if trimmed.contains("/") {
                return try _parseFraction(trimmed)
            }

            if trimmed.contains("%") {
                return try _parsePercentage(trimmed)
            }

            return try _parseDecimal(trimmed)
        }

        // MARK: - Fraction parsing

        private func _parseFraction(_ value: String) throws -> FractionalRate {
            let parts = value.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { throw ParseError.invalidInput }

            let numeratorString = parts[0].trimmingCharacters(in: .whitespaces)
            let denominatorString = parts[1].trimmingCharacters(in: .whitespaces)

            guard !numeratorString.isEmpty, !denominatorString.isEmpty else {
                throw ParseError.invalidInput
            }

            guard let numerator = Int64(numeratorString),
                  let denominator = Int64(denominatorString) else {
                throw ParseError.invalidInput
            }

            guard let rate = FractionalRate(numerator: numerator, denominator: denominator) else {
                throw ParseError.invalidFraction
            }

            return rate
        }

        // MARK: - Decimal parsing

        private func _parseDecimal(_ value: String) throws -> FractionalRate {
            guard let decimal = Decimal(string: value, locale: locale) else {
                throw ParseError.invalidInput
            }
            guard let rate = FractionalRate(decimal) else {
                throw ParseError.invalidInput
            }
            return rate
        }

        // MARK: - Percentage parsing

        private func _parsePercentage(_ value: String) throws -> FractionalRate {
            let stripped = value
                .replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespaces)
            guard !stripped.isEmpty else { throw ParseError.invalidInput }
            guard let decimal = Decimal(string: stripped, locale: locale) else {
                throw ParseError.invalidInput
            }
            let rate = decimal / Decimal(100)
            guard let result = FractionalRate(rate) else {
                throw ParseError.invalidInput
            }
            return result
        }
    }
}

// MARK: - ParseError

extension FractionalRate.ParseStrategy {

    /// Errors thrown when a `FractionalRate.ParseStrategy` cannot parse an input string.
    public enum ParseError: Error, LocalizedError, Sendable {

        /// The input string is empty or does not match any recognised format.
        case invalidInput

        /// The input was parsed as a fraction but the denominator was zero or
        /// the numerator was `Int64.min`.
        case invalidFraction

        public var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "The input string is not a valid FractionalRate representation."
            case .invalidFraction:
                return "The fraction has an invalid denominator (zero or negative) or numerator (Int64.min)."
            }
        }
    }
}

// MARK: - Convenience initialiser

extension FractionalRate {

    /// Creates a `FractionalRate` by parsing a formatted string.
    ///
    /// ```swift
    /// let rate = try FractionalRate("3/4", format: .fraction)
    /// // rate == FractionalRate(numerator: 3, denominator: 4)!
    /// ```
    ///
    /// - Parameters:
    ///   - string: A string in the format produced by `format`.
    ///   - format: The `FractionalRate.FormatStyle` used to interpret the string.
    /// - Throws: A parse error if `string` does not match `format`.
    public init(_ string: String, format: FractionalRate.FormatStyle) throws {
        self = try format.parseStrategy.parse(string)
    }
}
#endif
