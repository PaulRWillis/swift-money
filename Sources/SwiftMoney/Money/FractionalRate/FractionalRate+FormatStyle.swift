#if canImport(Foundation)
import Foundation

extension FractionalRate {

    // MARK: - FormatStyle

    /// A format style that produces a string representation of a `FractionalRate`.
    ///
    /// Supports multiple output modes:
    ///
    /// ```swift
    /// let rate = FractionalRate(numerator: 3, denominator: 4)!
    /// rate.formatted(.fraction)    // "3/4"
    /// rate.formatted(.decimal)     // "0.75"
    /// ```
    ///
    /// The default mode is `.fraction`.
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {

        /// The output representation for a formatted `FractionalRate`.
        public enum Mode: String, Equatable, Hashable, Sendable, Codable {
            /// Displays the rate as an integer fraction, e.g. `"3/4"`.
            case fraction
            /// Displays the rate as a decimal number, e.g. `"0.75"`.
            case decimal
        }

        // MARK: - Stored state

        private var mode: Mode
        private var locale: Locale

        // MARK: - Initialiser

        /// Creates a format style with the given mode.
        ///
        /// - Parameter mode: The output representation. Defaults to `.fraction`.
        public init(_ mode: Mode = .fraction, locale: Locale = .autoupdatingCurrent) {
            self.mode = mode
            self.locale = locale
        }

        // MARK: - Modifiers

        /// Returns a style with the given mode.
        public func mode(_ mode: Mode) -> FormatStyle {
            var s = self; s.mode = mode; return s
        }

        /// Returns a style with the given locale.
        public func locale(_ locale: Locale) -> FormatStyle {
            var s = self; s.locale = locale; return s
        }
    }
}

// MARK: - Foundation.FormatStyle conformance

extension FractionalRate.FormatStyle: Foundation.FormatStyle {

    /// Formats the given `FractionalRate` as a string.
    ///
    /// - Parameter value: The rate to format.
    /// - Returns: A string representation according to the current ``Mode``.
    public func format(_ value: FractionalRate) -> String {
        switch mode {
        case .fraction:
            return "\(value._numerator)/\(value._denominator)"
        case .decimal:
            let decimal = Decimal(value._numerator) / Decimal(value._denominator)
            return decimal.formatted(.number.locale(locale))
        }
    }
}

// MARK: - ParseableFormatStyle conformance

extension FractionalRate.FormatStyle: ParseableFormatStyle {
    /// The parse strategy derived from this format style.
    public var parseStrategy: FractionalRate.ParseStrategy {
        FractionalRate.ParseStrategy()
    }
}

// MARK: - Convenience

extension FractionalRate {

    /// Formats `self` using the default `FractionalRate.FormatStyle()`.
    public func formatted() -> String {
        FormatStyle().format(self)
    }

    /// Formats `self` using the given format style.
    public func formatted(_ format: FormatStyle) -> String {
        format.format(self)
    }
}

// MARK: - Static factory shorthand

extension FractionalRate.FormatStyle {

    /// A style that formats the rate as an integer fraction, e.g. `"3/4"`.
    ///
    /// ```swift
    /// rate.formatted(.fraction)  // "3/4"
    /// ```
    public static var fraction: Self { Self(.fraction) }

    /// A style that formats the rate as a decimal number, e.g. `"0.75"`.
    ///
    /// ```swift
    /// rate.formatted(.decimal)  // "0.75"
    /// ```
    public static var decimal: Self { Self(.decimal) }

    /// A decimal style with the given locale.
    ///
    /// ```swift
    /// rate.formatted(.decimal(locale: Locale(identifier: "de_DE")))  // "0,75"
    /// ```
    public static func decimal(locale: Locale) -> Self { Self(.decimal, locale: locale) }
}
#endif
