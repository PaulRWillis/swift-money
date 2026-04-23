#if canImport(Foundation)
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

// MARK: - Static factory shorthand
//
// Enables dot-syntax at call sites where the argument type is known:
//   anyMoney.formatted(.grouping(.never))
//   anyMoney.formatted(.precision(.fractionLength(0)).locale(enGB))

extension AnyMoney.FormatStyle {
    /// Returns a style with the given locale.
    ///
    /// ```swift
    /// anyMoney.formatted(.locale(Locale(identifier: "en_GB")))
    /// ```
    public static func locale(_ locale: Locale) -> Self {
        Self(locale: locale)
    }

    /// Returns a style with the given sign strategy.
    ///
    /// ```swift
    /// anyMoney.formatted(.sign(strategy: .always()))
    /// ```
    public static func sign(strategy: Configuration.SignDisplayStrategy) -> Self {
        Self().sign(strategy: strategy)
    }

    /// Returns a style with the given presentation.
    ///
    /// ```swift
    /// anyMoney.formatted(.presentation(.isoCode))
    /// ```
    public static func presentation(_ p: Configuration.Presentation) -> Self {
        Self().presentation(p)
    }

    /// Returns a style with the given grouping.
    ///
    /// ```swift
    /// anyMoney.formatted(.grouping(.never))
    /// ```
    public static func grouping(_ g: Configuration.Grouping) -> Self {
        Self().grouping(g)
    }

    /// Returns a style with the given precision.
    ///
    /// ```swift
    /// anyMoney.formatted(.precision(.fractionLength(0)))
    /// ```
    public static func precision(_ p: Configuration.Precision) -> Self {
        Self().precision(p)
    }

    /// Returns a style with the given decimal separator strategy.
    ///
    /// ```swift
    /// anyMoney.formatted(.decimalSeparator(strategy: .always))
    /// ```
    public static func decimalSeparator(strategy: Configuration.DecimalSeparatorDisplayStrategy) -> Self {
        Self().decimalSeparator(strategy: strategy)
    }

    /// Returns a style with the given rounding rule and optional increment.
    ///
    /// ```swift
    /// anyMoney.formatted(.rounded(rule: .up))
    /// ```
    public static func rounded(
        rule: Configuration.RoundingRule = .toNearestOrEven,
        increment: Int? = nil
    ) -> Self {
        Self().rounded(rule: rule, increment: increment)
    }

    /// Returns a style with the given notation.
    ///
    /// ```swift
    /// anyMoney.formatted(.notation(.compactName))
    /// ```
    public static func notation(_ n: Configuration.Notation) -> Self {
        Self().notation(n)
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
#endif
