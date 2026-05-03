#if canImport(Foundation)
import Foundation

extension Money {

    // MARK: - FormatStyle

    /// A format style that produces a localised currency string for a `Money` value.
    ///
    /// `Money.FormatStyle` mirrors the modifier API of `IntegerFormatStyle.Currency`
    /// and delegates to it internally, automatically scaling minor units to major
    /// units for display via the currency's `minimalQuantisation`.
    ///
    /// ```swift
    /// let style = Money<GBP>.FormatStyle(locale: Locale(identifier: "en_GB"))
    ///     .sign(strategy: .always())
    ///
    /// style.format(Money<GBP>(minorUnits: 150))  // "+£1.50"
    /// ```
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {

        public typealias Configuration = CurrencyFormatStyleConfiguration

        // MARK: - Stored state (var for copy-on-modify pattern)

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

// MARK: - Internal style builders

extension Money.FormatStyle {
    /// Builds the `IntegerFormatStyle<Int64>.Currency` that `format(_:)` uses.
    internal func _integerFormatStyle() -> IntegerFormatStyle<Int64>.Currency {
        let minQScale = 1.0 / Double(Money<Currency>.minimalQuantisation.int64Value)

        var style = IntegerFormatStyle<Int64>.Currency(
            code: Currency.code.stringValue,
            locale: locale
        )
        style = style.presentation(presentation)
        style = style.scale(minQScale)
        // Only set sign when non-automatic: explicitly setting sign-auto in the ICU skeleton
        // conflicts with group-off on macOS 15+/26, and auto is ICU's implicit default anyway.
        if signDisplayStrategy != .automatic { style = style.sign(strategy: signDisplayStrategy) }
        if let grouping                 { style = style.grouping(grouping) }
        if let precision                { style = style.precision(precision) }
        if let decimalSeparatorStrategy { style = style.decimalSeparator(strategy: decimalSeparatorStrategy) }
        if let roundedRule              { style = style.rounded(rule: roundedRule, increment: roundedIncrement) }
        if let notation                 { style = style.notation(notation) }
        return style
    }

    /// Builds a `Decimal.FormatStyle.Currency` with the same display parameters
    /// as `_integerFormatStyle()` but **without** the minor-unit scale.
    ///
    /// Used by `Money.ParseStrategy` to convert a formatted currency string back
    /// to a major-unit `Decimal` before manually inverting the scale.
    ///
    /// `IntegerFormatStyle<Int64>.Currency.parseStrategy` cannot be used for this
    /// because it does not invert the scale; it truncates the displayed value to
    /// an integer directly. Parsing via `Decimal.FormatStyle.Currency` (same ICU
    /// locale data, same display modifiers, no scale) gives us the exact
    /// displayed decimal value, from which scale inversion is straightforward.
    internal func _decimalFormatStyle() -> Decimal.FormatStyle.Currency {
        var style = Decimal.FormatStyle.Currency(
            code: Currency.code.stringValue,
            locale: locale
        )
        style = style.presentation(presentation)
        // Mirror the sign-auto guard from _integerFormatStyle().
        if signDisplayStrategy != .automatic { style = style.sign(strategy: signDisplayStrategy) }
        if let grouping                 { style = style.grouping(grouping) }
        if let precision                { style = style.precision(precision) }
        if let decimalSeparatorStrategy { style = style.decimalSeparator(strategy: decimalSeparatorStrategy) }
        if let roundedRule              { style = style.rounded(rule: roundedRule, increment: roundedIncrement) }
        if let notation                 { style = style.notation(notation) }
        // scale is intentionally NOT applied — the caller inverts scale manually.
        return style
    }

    /// Parses a formatted currency string back to a `Money` value.
    ///
    /// Algorithm:
    /// 1. Parse the string via `_decimalFormatStyle()` → displayed major-unit `Decimal`.
    /// 2. Convert: `minor_units = displayed × minQ`.
    /// 3. Round half-up and convert to `Int64`.
    internal func _parse(_ value: String) throws -> Money<Currency> {
        let minQ = Decimal(Money<Currency>.minimalQuantisation.int64Value)

        let displayed = try _decimalFormatStyle().parseStrategy.parse(value)

        var product = displayed * minQ
        var rounded = Decimal()
        NSDecimalRound(&rounded, &product, 0, .plain)   // round half-up

        let int64 = (rounded as NSDecimalNumber).int64Value
        guard Decimal(int64) == rounded else { throw Money<Currency>.ParseStrategy.ParseError.overflow }
        guard int64 != .min             else { throw Money<Currency>.ParseStrategy.ParseError.overflow }
        return Money<Currency>(_unchecked: int64)
    }
}

// MARK: - Foundation.FormatStyle conformance

extension Money.FormatStyle: Foundation.FormatStyle {
    public func format(_ value: Money) -> String {
        value._storage.formatted(_integerFormatStyle())
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

// MARK: - Static factory shorthand
//
// Enables dot-syntax at call sites where the argument type is known:
//   money.formatted(.grouping(.never))
//   money.formatted(.precision(.fractionLength(0)).locale(enGB))

extension Money.FormatStyle {
    /// Returns a style with the given locale.
    ///
    /// Equivalent to `Money<C>.FormatStyle(locale: locale)`.
    ///
    /// ```swift
    /// money.formatted(.locale(Locale(identifier: "en_GB")))
    /// ```
    public static func locale(_ locale: Locale) -> Self {
        Self(locale: locale)
    }

    /// Returns a style with the given sign strategy.
    ///
    /// ```swift
    /// money.formatted(.sign(strategy: .always()))
    /// ```
    public static func sign(strategy: Configuration.SignDisplayStrategy) -> Self {
        Self().sign(strategy: strategy)
    }

    /// Returns a style with the given presentation.
    ///
    /// ```swift
    /// money.formatted(.presentation(.isoCode))
    /// ```
    public static func presentation(_ p: Configuration.Presentation) -> Self {
        Self().presentation(p)
    }

    /// Returns a style with the given grouping.
    ///
    /// ```swift
    /// money.formatted(.grouping(.never))
    /// ```
    public static func grouping(_ g: Configuration.Grouping) -> Self {
        Self().grouping(g)
    }

    /// Returns a style with the given precision.
    ///
    /// ```swift
    /// money.formatted(.precision(.fractionLength(0)))
    /// ```
    public static func precision(_ p: Configuration.Precision) -> Self {
        Self().precision(p)
    }

    /// Returns a style with the given decimal separator strategy.
    ///
    /// ```swift
    /// money.formatted(.decimalSeparator(strategy: .always))
    /// ```
    public static func decimalSeparator(strategy: Configuration.DecimalSeparatorDisplayStrategy) -> Self {
        Self().decimalSeparator(strategy: strategy)
    }

    /// Returns a style with the given rounding rule and optional increment.
    ///
    /// ```swift
    /// money.formatted(.rounded(rule: .up))
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
    /// money.formatted(.notation(.compactName))
    /// ```
    public static func notation(_ n: Configuration.Notation) -> Self {
        Self().notation(n)
    }
}
#endif
