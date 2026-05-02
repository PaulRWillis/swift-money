#if canImport(Foundation)
import Foundation

extension UnitRate where U: CustomStringConvertible {

    // MARK: - FormatStyle

    /// A format style that produces a localised string for a `UnitRate` value.
    ///
    /// `UnitRate.FormatStyle` supports three output modes:
    /// - `.rate` — the raw fraction followed by the unit (e.g. `"23/1000000 / kWh"`)
    /// - `.number` — a locale-aware decimal followed by the unit (e.g. `"0.000023 / kWh"`)
    /// - `.price` — a locale-aware currency amount followed by the unit (e.g. `"£0.000023/kWh"`)
    ///
    /// The separator between the value and unit is configurable (default `"/"`).
    ///
    /// ```swift
    /// let rate = UnitRate<GBP, String>(Rate("23/1000000")!, per: "kWh")
    /// rate.formatted(.price)              // "£0.000023/kWh"
    /// rate.formatted(.number.locale(de))  // "0,000023/kWh"
    /// rate.formatted(.rate)               // "23/1000000 / kWh"
    /// ```
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {

        /// The output mode determining how the rate value is rendered.
        public enum Mode: String, Equatable, Hashable, Sendable, Codable {
            /// Raw fraction: `"23/1000000 / kWh"`.
            case rate
            /// Locale-aware decimal: `"0.000023 / kWh"`.
            case number
            /// Locale-aware currency: `"£0.000023/kWh"`.
            case price
        }

        // MARK: - Stored state

        private var mode: Mode
        private var locale: Locale
        private var separator: String

        // MARK: - Initialiser

        /// Creates a format style with the given mode, locale, and separator.
        ///
        /// - Parameters:
        ///   - mode: The output mode. Defaults to `.rate`.
        ///   - locale: The locale for number/currency formatting. Defaults to `.autoupdatingCurrent`.
        ///   - separator: The string placed between the value and unit. Defaults to `"/"`.
        public init(
            _ mode: Mode = .rate,
            locale: Locale = .autoupdatingCurrent,
            separator: String = "/"
        ) {
            self.mode = mode
            self.locale = locale
            self.separator = separator
        }

        // MARK: - Modifiers

        /// Returns a copy with the given locale.
        public func locale(_ locale: Locale) -> FormatStyle {
            var s = self; s.locale = locale; return s
        }

        /// Returns a copy with the given separator between value and unit.
        public func separator(_ separator: String) -> FormatStyle {
            var s = self; s.separator = separator; return s
        }

        // MARK: - Formatting

        /// Formats the unit rate value.
        internal func _format(_ value: UnitRate<C, U>) -> String {
            let unitLabel = String(describing: value.unit)
            let valueString: String

            switch mode {
            case .rate:
                valueString = value.rate.description

            case .number:
                let decimal = _rateAsDecimal(value.rate)
                valueString = decimal.formatted(.number.locale(locale))

            case .price:
                valueString = _formatPrice(value.rate)
            }

            return "\(valueString)\(separator)\(unitLabel)"
        }

        // MARK: - Private helpers

        /// Converts a `Rate` to its exact `Decimal` equivalent.
        private func _rateAsDecimal(_ rate: Rate) -> Decimal {
            let numerator = Decimal(rate.numeratorValue)
            let denominator = Decimal(rate.denominatorValue)
            return numerator / denominator
        }

        /// Formats the rate as a currency amount using the currency's format style.
        ///
        /// Produces the major-unit price per unit (e.g. "£0.000023" for a rate
        /// of 23/1000000 in GBP with minimalQuantisation 100).
        private func _formatPrice(_ rate: Rate) -> String {
            // Convert rate to minor units: rate represents major units per unit,
            // so minor units = numerator * minimalQuantisation / denominator.
            // But for display we want the major-unit decimal value:
            // majorUnits = numerator / denominator (already the rate's meaning).
            let decimal = _rateAsDecimal(rate)
            var style = Decimal.FormatStyle.Currency(
                code: C.code.stringValue,
                locale: locale
            )
            // Use maximum fraction digits to avoid truncating small rates.
            let significandDigits = _significantFractionDigits(decimal)
            let fractionDigits = max(C.minimalQuantisation.int64Value > 1 ? 2 : 0, significandDigits)
            style = style.precision(.fractionLength(fractionDigits))
            return style.format(decimal)
        }

        /// Returns the number of fraction digits needed to represent the decimal
        /// without trailing zeros beyond what's significant.
        private func _significantFractionDigits(_ value: Decimal) -> Int {
            let absolute = value < 0 ? -value : value
            guard absolute != 0 else { return 0 }
            let string = "\(absolute)"
            guard let dotIndex = string.firstIndex(of: ".") else { return 0 }
            return string.distance(from: string.index(after: dotIndex), to: string.endIndex)
        }
    }
}

// MARK: - Foundation.FormatStyle conformance

extension UnitRate.FormatStyle: Foundation.FormatStyle where U: CustomStringConvertible {
    public func format(_ value: UnitRate<C, U>) -> String {
        _format(value)
    }
}

// MARK: - Convenience

extension UnitRate where U: CustomStringConvertible {
    /// Formats `self` using the default `UnitRate.FormatStyle()`.
    public func formatted() -> String {
        FormatStyle().format(self)
    }

    /// Formats `self` using the given format style.
    public func formatted(_ format: FormatStyle) -> String {
        format.format(self)
    }
}

// MARK: - Static factory shorthand

extension UnitRate.FormatStyle where U: CustomStringConvertible {
    /// A format style showing the raw rate fraction and unit.
    ///
    /// ```swift
    /// unitRate.formatted(.rate)  // "23/1000000 / kWh"
    /// ```
    public static var rate: Self { .init(.rate) }

    /// A format style showing a locale-aware decimal and unit.
    ///
    /// ```swift
    /// unitRate.formatted(.number)  // "0.000023/kWh"
    /// ```
    public static var number: Self { .init(.number) }

    /// A format style showing a locale-aware currency price and unit.
    ///
    /// ```swift
    /// unitRate.formatted(.price)  // "£0.000023/kWh"
    /// ```
    public static var price: Self { .init(.price) }
}

#endif
