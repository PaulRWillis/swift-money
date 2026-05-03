#if canImport(Foundation)
import Foundation

extension UnitRate where U: CustomStringConvertible {

    // MARK: - FormatStyle

    /// A format style that produces a localised currency string for a `UnitRate` value.
    ///
    /// The value portion is always rendered as a currency amount (e.g. `"£0.000023"`)
    /// because a `UnitRate` represents money per unit — stripping the currency
    /// context would produce a misleading output.
    ///
    /// For `Dimension` units, the unit label is localised using Foundation's CLDR
    /// data and spacing is determined by the locale. For `String` units, the literal
    /// string is used with a `"/"` separator.
    ///
    /// ```swift
    /// let rate = UnitRate<GBP, String>(Rate("23/1000000")!, per: "kWh")
    /// rate.formatted()  // "£0.000023/kWh"
    /// ```
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {

        /// The width of the unit label (applies to `Dimension` units only).
        public enum UnitWidth: String, Equatable, Hashable, Sendable, Codable {
            /// Abbreviated symbol (e.g. `"kWh"`).
            case abbreviated
            /// Full name (e.g. `"kilowatt-hours"`).
            case wide
            /// Shortest form (e.g. `"kWh"`).
            case narrow
        }

        // MARK: - Stored state

        internal var locale: Locale
        internal var unitWidth: UnitWidth

        // MARK: - Initialiser

        /// Creates a format style with the given locale and unit width.
        ///
        /// - Parameters:
        ///   - locale: The locale for currency formatting. Defaults to `.autoupdatingCurrent`.
        ///   - unitWidth: The width of the unit label for `Dimension` units. Defaults to `.abbreviated`.
        public init(
            locale: Locale = .autoupdatingCurrent,
            unitWidth: UnitWidth = .abbreviated
        ) {
            self.locale = locale
            self.unitWidth = unitWidth
        }

        // MARK: - Modifiers

        /// Returns a copy with the given locale.
        public func locale(_ locale: Locale) -> FormatStyle {
            var s = self; s.locale = locale; return s
        }

        /// Returns a copy with the given unit label width.
        ///
        /// Only affects `Dimension` units; `String` units always use their
        /// literal value regardless of this setting.
        public func unitWidth(_ width: UnitWidth) -> FormatStyle {
            var s = self; s.unitWidth = width; return s
        }

        // MARK: - Formatting

        /// Formats the unit rate value using `String(describing:)` for the unit label.
        internal func _format(_ value: UnitRate<C, U>) -> String {
            let unitLabel = String(describing: value.unit)
            return "\(_formatPrice(value.rate))/\(unitLabel)"
        }

        // MARK: - Internal helpers

        /// Converts a `Rate` to its exact `Decimal` equivalent.
        internal func _rateAsDecimal(_ rate: Rate) -> Decimal {
            let numerator = Decimal(rate.numeratorValue)
            let denominator = Decimal(rate.denominatorValue)
            return numerator / denominator
        }

        /// Formats the rate as a currency amount using the currency's format style.
        ///
        /// Produces the major-unit price per unit (e.g. "£0.000023" for a rate
        /// of 23/1000000 in GBP with minimalQuantisation 100).
        internal func _formatPrice(_ rate: Rate) -> String {
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

    /// Formats `self` as an `AttributedString` with component runs.
    public func formatted(_ format: AttributedFormatStyle) -> AttributedString {
        format.format(self)
    }
}

// MARK: - Dimension-specific formatting

extension UnitRate.FormatStyle where U: Dimension {
    /// Formats a `UnitRate` whose unit is a `Dimension`, using a localised
    /// unit label extracted from Foundation's `Measurement.FormatStyle.attributed`.
    ///
    /// Foundation's CLDR data provides locale-aware unit names and spacing.
    /// The value portion is always formatted as a currency amount.
    internal func _formatDimension(_ value: UnitRate<C, U>) -> String {
        let (spacing, unitLabel) = _localisedSpacingAndUnit(value.unit)
        let valueString = _formatPrice(value.rate)
        return "\(valueString)\(spacing)\(unitLabel)"
    }

    /// Extracts the localised spacing and unit label from Foundation's attributed output.
    ///
    /// Uses `Measurement.FormatStyle.attributed` with `.asProvided` to prevent
    /// auto-conversion to the locale's preferred unit. The attributed string
    /// has three runs: `.value`, `nil` (spacing), `.unit`.
    private func _localisedSpacingAndUnit(_ unit: U) -> (spacing: String, unit: String) {
        let measurement = Measurement(value: 1.0, unit: unit)
        let width = _foundationWidth()
        let style = Measurement<U>.FormatStyle.measurement(
            width: width,
            usage: .asProvided
        ).locale(locale)
        let attributed = measurement.formatted(style.attributed)

        var spacing = ""
        var unitText = ""

        for (component, range) in attributed.runs[\.measurement] {
            let text = String(attributed[range].characters)
            switch component {
            case .unit:
                unitText += text
            case .value:
                break
            default:
                // nil component = spacing between value and unit
                spacing += text
            }
        }

        return (spacing, unitText)
    }

    /// Maps our `UnitWidth` to Foundation's `Measurement.FormatStyle.UnitWidth`.
    private func _foundationWidth() -> Measurement<U>.FormatStyle.UnitWidth {
        switch unitWidth {
        case .abbreviated:
            return .abbreviated
        case .wide:
            return .wide
        case .narrow:
            return .narrow
        }
    }
}

// MARK: - Dimension convenience methods

extension UnitRate where U: Dimension {
    /// Formats `self` using the default `FormatStyle` with a localised unit label.
    public func formatted() -> String {
        FormatStyle()._formatDimension(self)
    }

    /// Formats `self` using the given format style with a localised unit label.
    public func formatted(_ format: FormatStyle) -> String {
        format._formatDimension(self)
    }

    /// Formats `self` as an `AttributedString` with component runs.
    public func formatted(_ format: AttributedFormatStyle) -> AttributedString {
        format.format(self)
    }
}

// MARK: - Attributed string output

/// The component of a `UnitRate` format run.
///
/// Used to tag runs in an `AttributedString` returned by
/// `UnitRate.FormatStyle.attributed`, allowing consumers to style
/// the value and unit portions independently.
public enum UnitRateFormatAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    public typealias Value = Component
    public static let name = "SwiftMoney.UnitRateFormat"

    /// Identifies which part of the formatted unit rate a run represents.
    public enum Component: String, Codable, Sendable {
        /// The formatted price/number/rate value.
        case value
        /// The unit label (e.g. "kWh", "kilowatt-hours").
        case unit
    }
}

extension AttributeScopes {
    /// Attribute scope for `UnitRate` formatting.
    public struct UnitRateFormatAttributes: AttributeScope {
        public let unitRateComponent: UnitRateFormatAttribute
    }

    /// The `UnitRate` formatting attributes.
    public var unitRateFormat: UnitRateFormatAttributes.Type { UnitRateFormatAttributes.self }
}

extension AttributeDynamicLookup {
    public subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.UnitRateFormatAttributes, T>
    ) -> T {
        self[T.self]
    }
}

// MARK: - Attributed formatting

extension UnitRate.FormatStyle where U: CustomStringConvertible {
    /// Returns an `AttributedString` with runs tagged by `UnitRateFormatAttribute`.
    ///
    /// The output has two runs:
    /// - `.value` — the formatted price, number, or rate fraction
    /// - `.unit` — the unit label (including separator/spacing)
    ///
    /// For `String` units, a `"/"` separator prefixes the unit run.
    /// For `Dimension` units, Foundation-localised spacing is used instead.
    public var attributed: UnitRate<C, U>.AttributedFormatStyle {
        UnitRate<C, U>.AttributedFormatStyle(base: self)
    }
}

extension UnitRate where U: CustomStringConvertible {

    /// A format style that produces `AttributedString` output for a `UnitRate`.
    public struct AttributedFormatStyle: Foundation.FormatStyle, Sendable {
        internal let base: FormatStyle

        public func format(_ value: UnitRate<C, U>) -> AttributedString {
            let valueString = base._formatPrice(value.rate)

            var valueAttr = AttributedString(valueString)
            valueAttr[UnitRateFormatAttribute.self] = .value

            let unitPart: String
            if let dimension = value.unit as? Dimension {
                unitPart = Self._dimensionUnitPart(
                    dimension: dimension,
                    unitWidth: base.unitWidth,
                    locale: base.locale
                )
            } else {
                unitPart = "/\(value.unit)"
            }

            var unitAttr = AttributedString(unitPart)
            unitAttr[UnitRateFormatAttribute.self] = .unit

            return valueAttr + unitAttr
        }

        /// Extracts spacing + unit label from Foundation's attributed output using type-erased Dimension.
        private static func _dimensionUnitPart(
            dimension: Dimension,
            unitWidth: UnitRate<C, U>.FormatStyle.UnitWidth,
            locale: Locale
        ) -> String {
            let measurement = Measurement<Dimension>(value: 1.0, unit: dimension)
            let width: Measurement<Dimension>.FormatStyle.UnitWidth
            switch unitWidth {
            case .abbreviated: width = .abbreviated
            case .wide: width = .wide
            case .narrow: width = .narrow
            }
            let style = Measurement<Dimension>.FormatStyle.measurement(
                width: width,
                usage: .asProvided
            ).locale(locale)
            let attributed = measurement.formatted(style.attributed)

            var spacing = ""
            var unitText = ""
            for (component, range) in attributed.runs[\.measurement] {
                let text = String(attributed[range].characters)
                switch component {
                case .unit:
                    unitText += text
                case .value:
                    break
                default:
                    spacing += text
                }
            }
            return "\(spacing)\(unitText)"
        }
    }
}

#endif
