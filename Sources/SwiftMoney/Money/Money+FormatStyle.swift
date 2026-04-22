import Foundation

extension Money {

    // MARK: - FormatStyle

    /// A format style that produces a localised currency string for a `Money` value.
    ///
    /// `Money.FormatStyle` mirrors the modifier API of `IntegerFormatStyle.Currency`
    /// and delegates to it internally, automatically scaling minor units to major
    /// units for display.
    ///
    /// ```swift
    /// let style = Money<GBP>.FormatStyle(locale: Locale(identifier: "en_GB"))
    ///     .sign(strategy: .always())
    ///
    /// style.format(Money<GBP>(minorUnits: 150))  // "+£1.50"
    /// ```
    ///
    /// ## Scale compounding
    ///
    /// The built-in `1 / minimalQuantisation` scaling (minor → major units) is always
    /// applied. `.scale(_:)` compounds on top of it: `.scale(2.0)` on a GBP amount
    /// doubles the displayed pound value (effective scale `2 / 100`).
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {

        public typealias Configuration = CurrencyFormatStyleConfiguration

        // MARK: - Stored state (var for copy-on-modify pattern)

        private var locale: Locale
        private var signDisplayStrategy: Configuration.SignDisplayStrategy
        private var presentation: Configuration.Presentation
        private var grouping: Configuration.Grouping?
        private var precision: Configuration.Precision?
        private var decimalSeparatorStrategy: Configuration.DecimalSeparatorDisplayStrategy?
        private var userScale: Double?
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
            self.userScale = nil
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

        public func scale(_ multiplicand: Double) -> FormatStyle {
            var s = self; s.userScale = multiplicand; return s
        }

        public func notation(_ n: Configuration.Notation) -> FormatStyle {
            var s = self; s.notation = n; return s
        }
    }
}

// MARK: - Foundation.FormatStyle conformance

extension Money.FormatStyle: Foundation.FormatStyle {
    public func format(_ value: Money) -> String {
        let minQScale = 1.0 / Double(Money<Currency>.minimalQuantisation.int64Value)
        let effectiveScale = userScale.map { minQScale * $0 } ?? minQScale

        var style = IntegerFormatStyle<Int64>.Currency(
            code: value.currency.code.stringValue,
            locale: locale
        )
        style = style.presentation(presentation)
        style = style.scale(effectiveScale)
        // Only set sign when non-automatic: explicitly setting sign-auto in the ICU skeleton
        // conflicts with group-off on macOS 15+/26, and auto is ICU's implicit default anyway.
        if signDisplayStrategy != .automatic { style = style.sign(strategy: signDisplayStrategy) }
        if let g = grouping                  { style = style.grouping(g) }
        if let p = precision                 { style = style.precision(p) }
        if let d = decimalSeparatorStrategy  { style = style.decimalSeparator(strategy: d) }
        if let r = roundedRule               { style = style.rounded(rule: r, increment: roundedIncrement) }
        if let n = notation                  { style = style.notation(n) }
        return value._storage.formatted(style)
    }
}

// MARK: - Convenience

extension Money {
    /// Formats `self` using the default `Money.FormatStyle()`.
    public func formatted() -> String {
        FormatStyle().format(self)
    }

    /// Formats `self` using the given format style.
    public func formatted(_ format: FormatStyle) -> String {
        format.format(self)
    }
}
