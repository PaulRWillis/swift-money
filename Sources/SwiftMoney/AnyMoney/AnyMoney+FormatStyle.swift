import Foundation

extension AnyMoney {

    // MARK: - FormatStyle

    /// A format style that produces a localised currency string for an `AnyMoney` value.
    ///
    /// Mirrors the modifier API of `Money.FormatStyle`. Because `AnyMoney` carries its
    /// own `minimalQuantisation` at runtime, the minor-to-major-unit scaling is derived
    /// from the value rather than a static type parameter.
    ///
    /// ```swift
    /// Money<GBP>(minorUnits: 150).erased
    ///     .formatted(AnyMoney.FormatStyle(locale: Locale(identifier: "en_GB")))
    /// // "£1.50"
    /// ```
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {

        public typealias Configuration = CurrencyFormatStyleConfiguration

        // MARK: - Stored state

        private var locale: Locale
        private var signDisplayStrategy: Configuration.SignDisplayStrategy
        private var presentation: Configuration.Presentation
        private var grouping: Configuration.Grouping?
        private var precision: Configuration.Precision?
        private var decimalSeparatorStrategy: Configuration.DecimalSeparatorDisplayStrategy?
        private var roundedRule: Configuration.RoundingRule?
        private var roundedIncrement: Int?
        private var notation: Configuration.Notation?

        // MARK: - Initialiser

        public init(locale: Locale = .autoupdatingCurrent) {
            self.locale = locale
            self.signDisplayStrategy = .automatic
            self.presentation = .standard
            self.grouping = nil
            self.precision = nil
            self.decimalSeparatorStrategy = nil
            self.roundedRule = nil
            self.roundedIncrement = nil
            self.notation = nil
        }

        // MARK: - Modifiers

        public func locale(_ locale: Locale) -> FormatStyle {
            var s = self; s.locale = locale; return s
        }

        public func sign(strategy: Configuration.SignDisplayStrategy) -> FormatStyle {
            var s = self; s.signDisplayStrategy = strategy; return s
        }

        public func presentation(_ p: Configuration.Presentation) -> FormatStyle {
            var s = self; s.presentation = p; return s
        }

        public func grouping(_ g: Configuration.Grouping) -> FormatStyle {
            var s = self; s.grouping = g; return s
        }

        public func precision(_ p: Configuration.Precision) -> FormatStyle {
            var s = self; s.precision = p; return s
        }

        public func decimalSeparator(
            strategy: Configuration.DecimalSeparatorDisplayStrategy
        ) -> FormatStyle {
            var s = self; s.decimalSeparatorStrategy = strategy; return s
        }

        public func rounded(
            rule: Configuration.RoundingRule = .toNearestOrEven,
            increment: Int? = nil
        ) -> FormatStyle {
            var s = self; s.roundedRule = rule; s.roundedIncrement = increment; return s
        }

        public func notation(_ n: Configuration.Notation) -> FormatStyle {
            var s = self; s.notation = n; return s
        }
    }
}

// MARK: - Foundation.FormatStyle conformance

extension AnyMoney.FormatStyle: Foundation.FormatStyle {
    public func format(_ value: AnyMoney) -> String {
        let minQScale = 1.0 / Double(value.minimalQuantisation.int64Value)

        var style = IntegerFormatStyle<Int64>.Currency(
            code: value.currencyCode.stringValue,
            locale: locale
        )
        style = style.presentation(presentation)
        style = style.scale(minQScale)
        // Only set sign when non-automatic: explicitly setting sign-auto in the ICU skeleton
        // conflicts with group-off on macOS 15+/26, and auto is ICU's implicit default anyway.
        if signDisplayStrategy != .automatic { style = style.sign(strategy: signDisplayStrategy) }
        if let g = grouping                  { style = style.grouping(g) }
        if let p = precision                 { style = style.precision(p) }
        if let d = decimalSeparatorStrategy  { style = style.decimalSeparator(strategy: d) }
        if let r = roundedRule               { style = style.rounded(rule: r, increment: roundedIncrement) }
        if let n = notation                  { style = style.notation(n) }
        return value.minorUnits.formatted(style)
    }
}

// MARK: - Convenience

extension AnyMoney {
    /// Formats this value using the default `AnyMoney.FormatStyle()`.
    public func formatted() -> String {
        FormatStyle().format(self)
    }

    /// Formats this value using the given format style.
    public func formatted(_ format: FormatStyle) -> String {
        format.format(self)
    }
}

extension AnyMoney: CustomStringConvertible {
    /// A human-readable currency string for this value.
    ///
    /// Equivalent to ``formatted()``.
    public var description: String {
        formatted()
    }
}

extension AnyMoney: CustomDebugStringConvertible {
    /// A debug-friendly representation showing the currency code, raw minor
    /// units, and formatted value.
    ///
    /// ```swift
    /// Money<GBP>(minorUnits: 150).erased.debugDescription
    /// // "AnyMoney(GBP, minorUnits: 150) — \"£1.50\""
    /// ```
    public var debugDescription: String {
        if minorUnits == .min {
            return "AnyMoney(\(currencyCode), NaN)"
        }
        return "AnyMoney(\(currencyCode), minorUnits: \(minorUnits)) — \"\(formatted())\""
    }
}
