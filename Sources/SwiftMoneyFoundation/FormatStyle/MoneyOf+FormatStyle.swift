import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization

public extension MoneyOf {
    /// A style that renders an amount for people, in the digits and symbols of a locale.
    ///
    /// The locale-aware counterpart to `description`, which stays locale-invariant so it can
    /// round-trip. The style holds no currency and no amount: the currency always comes from
    /// the amount being formatted, so a style can never disagree with the value it is handed.
    /// That is the state this type forbids.
    ///
    /// By default the style shows the exact amount: precision comes from the currency's
    /// own scale, never from ICU's defaults. It rounds the displayed digits only when the
    /// caller asks it to, through `precision(_:)` or `rounded(rule:increment:)`.
    struct FormatStyle: Codable, Equatable, Hashable, Sendable {
        /// The options a currency style is built from, named as Foundation names them.
        ///
        /// The same vocabulary `Decimal.FormatStyle.Currency` takes, so a reader who knows one
        /// knows the other.
        public typealias Configuration = CurrencyFormatStyleConfiguration

        // `internal` rather than `private`: read and written from the Codable, Engine, Rounding and
        // Attributed splits, which needs at least module visibility now that they no longer share a
        // file with this struct. Still no wider than before the split — `FormatStyle`'s public surface
        // is only its methods, none of which expose these directly.
        var locale: Locale
        var presentation: Configuration.Presentation
        var grouping: Configuration.Grouping
        var sign: Configuration.SignDisplayStrategy
        var decimalSeparator: Configuration.DecimalSeparatorDisplayStrategy
        var roundingRule: Configuration.RoundingRule

        // `nil` means the currency decides, which is the whole point of the default: the style
        // shows every unit the currency divides into and no more, so nothing is rounded away.
        var precision: Configuration.Precision?

        // `nil` leaves the amount alone.
        var roundingIncrement: RoundingIncrement?

        // The locale's numbering system, resolved once here rather than on every `format`, because
        // `Locale.numberingSystem` is an ICU call and the same style renders a column of amounts. `nil`
        // means the locale's system is one the engine cannot model, so the ICU fallback renders it.
        // Derived from `locale`, so it is recomputed whenever the locale changes and left off the wire.
        var resolvedNumberingSystem: NumberingSystem?

        /// Creates a style for the given locale.
        ///
        /// - Parameter locale: The locale to render in. Follows the user's setting by default.
        public init(locale: Locale = .autoupdatingCurrent) {
            self.locale = locale
            self.presentation = .standard
            self.grouping = .automatic
            self.sign = .automatic
            self.decimalSeparator = .automatic
            self.roundingRule = .toNearestOrEven
            self.precision = nil
            self.roundingIncrement = nil
            self.resolvedNumberingSystem = NumberingSystem(locale.numberingSystem)
        }

        /// Returns a copy of this style that renders in the given locale.
        ///
        /// - Parameter locale: The locale to render in.
        public func locale(_ locale: Locale) -> Self {
            var copy = self
            copy.locale = locale
            copy.resolvedNumberingSystem = NumberingSystem(locale.numberingSystem)
            return copy
        }

        /// Returns a copy of this style that names the currency in the given way.
        ///
        /// ```swift
        /// style.presentation(.isoCode).format(USD(minorUnits: 4_99))   // "USD 4.99"
        /// ```
        ///
        /// - Parameter presentation: How to name the currency. `.standard` by default.
        public func presentation(_ presentation: Configuration.Presentation) -> Self {
            var copy = self
            copy.presentation = presentation
            return copy
        }

        /// Returns a copy of this style that groups the digits in the given way.
        ///
        /// - Parameter grouping: Whether to separate thousands. `.automatic` by default.
        public func grouping(_ grouping: Configuration.Grouping) -> Self {
            var copy = self
            copy.grouping = grouping
            return copy
        }

        /// Returns a copy of this style that shows the sign in the given way.
        ///
        /// - Parameter strategy: When to write a sign. `.automatic` by default, which writes one
        ///   only for a negative amount.
        public func sign(strategy: Configuration.SignDisplayStrategy) -> Self {
            var copy = self
            copy.sign = strategy
            return copy
        }

        /// Returns a copy of this style that shows the decimal separator in the given way.
        ///
        /// - Parameter strategy: When to write the separator. `.automatic` by default, which
        ///   writes one only where digits follow it.
        public func decimalSeparator(
            strategy: Configuration.DecimalSeparatorDisplayStrategy
        ) -> Self {
            var copy = self
            copy.decimalSeparator = strategy
            return copy
        }

        /// Returns a copy of this style that shows the given number of digits.
        ///
        /// This is the opt-in to display rounding. The default shows every unit the currency
        /// divides into, so `4.99` in sterling stays `4.99`; asking for fewer digits than that
        /// rounds what is shown, and the text no longer parses back to the amount it came from.
        ///
        /// - Parameter precision: How many digits to show.
        public func precision(_ precision: Configuration.Precision) -> Self {
            var copy = self
            copy.precision = precision
            return copy
        }

        /// Returns a copy of this style that rounds the amount to a multiple of the given step.
        ///
        /// The step counts the currency's smallest units, so Swiss cash rounding to the nearest
        /// five centimes is `increment: 5`. What the style then shows is a real amount of the
        /// currency, so it still parses back exactly as shown, but it is no longer the amount
        /// the style was handed.
        ///
        /// ```swift
        /// style.rounded(increment: 5).format(CHF(minorUnits: 4_98))   // "CHF 5.00"
        /// ```
        ///
        /// - Parameters:
        ///   - rule: Which way to round a value between two steps. Rounds to the nearest even
        ///     step by default.
        ///   - increment: The step to round to, counted in the currency's smallest units. `nil`
        ///     by default, which rounds nothing. A step of one rounds nothing either, an amount
        ///     already being a whole count of the currency's smallest units.
        public func rounded(
            rule: Configuration.RoundingRule = .toNearestOrEven,
            increment: RoundingIncrement? = nil
        ) -> Self {
            var copy = self
            copy.roundingRule = rule
            copy.roundingIncrement = increment
            return copy
        }
    }
}

extension MoneyOf.FormatStyle: Foundation.FormatStyle {
    /// The amount, rendered for the locale this style holds.
    ///
    /// - Parameter value: The amount to render. Its currency decides the symbol and the digits.
    public func format(_ value: MoneyOf<C>) -> String {
        engineFormatted(value) ?? decimalStyle(for: value.currency).format(majorUnits(of: value))
    }
}

public extension MoneyOf {
    /// The amount, rendered by the given style.
    ///
    /// - Parameter format: The style to render with.
    func formatted<F: Foundation.FormatStyle>(
        _ format: F
    ) -> F.FormatOutput where F.FormatInput == Self {
        format.format(self)
    }

    /// The amount, rendered for the locale the user has set.
    ///
    /// ```swift
    /// GBP(minorUnits: 4_99).formatted()   // "£4.99" for a reader in Britain
    /// ```
    func formatted() -> String {
        FormatStyle().format(self)
    }
}

public extension Foundation.FormatStyle {
    /// A style that renders an amount for people, in the digits and symbols of a locale.
    ///
    /// ```swift
    /// GBP(minorUnits: 4_99).formatted(.currency())
    /// ```
    ///
    /// No currency code to pass, unlike the `Decimal` and `BinaryInteger` styles beside it: the
    /// amount carries its own currency, so naming a second one here could only disagree with it.
    ///
    /// - Parameter locale: The locale to render in. Follows the user's setting by default.
    static func currency<C: CurrencyRepresentation>(
        locale: Locale = .autoupdatingCurrent
    ) -> Self where Self == MoneyOf<C>.FormatStyle {
        MoneyOf<C>.FormatStyle(locale: locale)
    }
}
