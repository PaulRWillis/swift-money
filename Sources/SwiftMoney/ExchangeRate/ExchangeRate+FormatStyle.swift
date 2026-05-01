import Foundation

extension ExchangeRate {

    /// A `FormatStyle` that converts an `ExchangeRate` to a human-readable string.
    public struct FormatStyle: Foundation.FormatStyle, Equatable, Hashable, Sendable {

        /// The separator used between the two sides of a `.pair` format.
        public struct Separator: Codable, Equatable, Hashable, Sendable {
            /// The raw separator string.
            internal let rawValue: String

            internal init(_ rawValue: String) { self.rawValue = rawValue }

            /// `" = "` — equals sign surrounded by spaces.
            public static var equals: Separator { Separator(" = ") }

            /// `" : "` — colon surrounded by spaces.
            public static var colon: Separator { Separator(" : ") }

            /// A custom separator string.
            public static func custom(_ separator: String) -> Separator { Separator(separator) }
        }

        /// The aspect of the exchange rate to present.
        public enum Mode: Codable, Equatable, Hashable, Sendable {
            /// The major-unit rate as a decimal, e.g. `"1.25"`.
            case rate
            /// The major-unit rate as a reduced fraction, e.g. `"5/4"`.
            case fraction
            /// A currency pair showing 1 major unit converted, e.g. `"£1.00 = US$1.25"`.
            case pair(separator: Separator = .equals)
        }

        private var mode: Mode
        private var locale: Locale

        public init(_ mode: Mode = .rate, locale: Locale = .autoupdatingCurrent) {
            self.mode = mode
            self.locale = locale
        }

        // MARK: - Modifiers

        /// Returns a style with the given locale.
        public func locale(_ locale: Locale) -> FormatStyle {
            var s = self; s.locale = locale; return s
        }

        public func format(_ value: ExchangeRate<From, To>) -> String {
            switch mode {
            case .rate:
                return _formatRate(value)
            case .fraction:
                return _formatFraction(value)
            case .pair(let separator):
                return _formatPair(value, separator: separator)
            }
        }

        // MARK: - Private

        private func _formatRate(_ value: ExchangeRate<From, To>) -> String {
            let numerator = Decimal(value.rate.numeratorValue)
                * Decimal(From.minimalQuantisation.int64Value)
            let denominator = Decimal(value.rate.denominatorValue)
                * Decimal(To.minimalQuantisation.int64Value)
            let majorUnitRate = numerator / denominator
            return majorUnitRate.formatted(Decimal.FormatStyle().locale(locale))
        }

        private func _formatFraction(_ value: ExchangeRate<From, To>) -> String {
            let majorNumerator = value.rate.numeratorValue
                * From.minimalQuantisation.int64Value
            let majorDenominator = value.rate.denominatorValue
                * To.minimalQuantisation.int64Value
            let majorRate = Rate(
                _unchecked: majorNumerator, denominator: majorDenominator
            )
            return majorRate.formatted(.fraction)
        }

        private func _formatPair(
            _ value: ExchangeRate<From, To>,
            separator: Separator
        ) -> String {
            let oneMajorUnit = Money<From>(
                minorUnits: From.minimalQuantisation.int64Value
            )
            let converted = value.convert(oneMajorUnit)
            let fromStyle = Money<From>.FormatStyle(locale: locale)
            let toStyle = Money<To>.FormatStyle(locale: locale)
            return fromStyle.format(oneMajorUnit)
                + separator.rawValue
                + toStyle.format(converted)
        }
    }

    /// Formats this exchange rate using the given style.
    public func formatted(_ style: FormatStyle) -> String {
        style.format(self)
    }

    /// Formats this exchange rate using the default `.rate` style.
    public func formatted() -> String {
        formatted(.rate)
    }
}

// MARK: - Static factories

extension ExchangeRate.FormatStyle {

    /// Format the major-unit rate as a decimal using the current locale.
    public static var rate: Self { .init(.rate) }

    /// Format the major-unit rate as a reduced fraction, e.g. `"5/4"`.
    public static var fraction: Self { .init(.fraction) }

    /// Format as a currency pair, e.g. `"£1.00 = US$1.25"`.
    public static var pair: Self { .init(.pair()) }

    /// Format as a currency pair with a custom separator, e.g. `"£1.00 : US$1.25"`.
    public static func pair(separator: Separator) -> Self { .init(.pair(separator: separator)) }
}
