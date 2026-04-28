import Foundation

extension ExchangeRate {

    /// A `FormatStyle` that converts an `ExchangeRate` to a human-readable string.
    public struct FormatStyle: Foundation.FormatStyle, Equatable, Hashable, Sendable {

        /// The aspect of the exchange rate to present.
        public enum Mode: Codable, Equatable, Hashable, Sendable {
            /// The major-unit rate as a decimal, e.g. `"1.25"`.
            case rate
        }

        public var mode: Mode
        public var locale: Locale

        public init(_ mode: Mode = .rate, locale: Locale = .autoupdatingCurrent) {
            self.mode = mode
            self.locale = locale
        }

        public func format(_ value: ExchangeRate<From, To>) -> String {
            switch mode {
            case .rate:
                return _formatRate(value)
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

    /// Format the major-unit rate as a decimal using the given locale.
    public static func rate(locale: Locale) -> Self { .init(.rate, locale: locale) }
}
