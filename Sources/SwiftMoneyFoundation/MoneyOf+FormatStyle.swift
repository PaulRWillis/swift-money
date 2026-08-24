import Foundation
import SwiftMoney

public extension MoneyOf {
    /// A style that renders an amount for people, in the digits and symbols of a locale.
    ///
    /// The locale-aware counterpart to `description`, which stays locale-invariant so it can
    /// round-trip. The style holds no currency and no amount: the currency always comes from
    /// the amount being formatted, so a style can never disagree with the value it is handed.
    /// That is the state this type forbids.
    ///
    /// By default the style shows the exact amount: precision comes from the currency's
    /// own scale, never from ICU's defaults.
    struct FormatStyle: Codable, Equatable, Hashable, Sendable {
        /// The options a currency style is built from, named as Foundation names them.
        ///
        /// The same vocabulary `Decimal.FormatStyle.Currency` takes, so a reader who knows one
        /// knows the other.
        public typealias Configuration = CurrencyFormatStyleConfiguration

        private var locale: Locale
        private var presentation: Configuration.Presentation
        private var grouping: Configuration.Grouping
        private var sign: Configuration.SignDisplayStrategy
        private var decimalSeparator: Configuration.DecimalSeparatorDisplayStrategy

        /// Creates a style for the given locale.
        ///
        /// - Parameter locale: The locale to render in. Follows the user's setting by default.
        public init(locale: Locale = .autoupdatingCurrent) {
            self.locale = locale
            self.presentation = .standard
            self.grouping = .automatic
            self.sign = .automatic
            self.decimalSeparator = .automatic
        }

        /// Returns a copy of this style that renders in the given locale.
        ///
        /// - Parameter locale: The locale to render in.
        public func locale(_ locale: Locale) -> Self {
            var copy = self
            copy.locale = locale
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
    }
}

// MARK: - Foundation.FormatStyle

extension MoneyOf.FormatStyle: Foundation.FormatStyle {
    /// The amount, rendered for the locale this style holds.
    ///
    /// - Parameter value: The amount to render. Its currency decides the symbol and the digits.
    public func format(_ value: MoneyOf<C>) -> String {
        decimalStyle(for: value.currency).format(Decimal(value))
    }
}

// MARK: - The Foundation style underneath

extension MoneyOf.FormatStyle {
    // The style this one renders through, settled for one currency.
    //
    // Precision is pinned rather than left to ICU, whose per-currency defaults round: a yen
    // style shows 1234.56 as "1,235". A money amount must never lose a unit to display.
    //
    // Everything else is passed on only where the caller changed it, because setting an option
    // to its own default is not free: Foundation drops the currency symbol from a style that has
    // grouping turned off and a sign, a separator or a rounding rule set beside it. Verified on
    // Swift 6.3.2, against `Decimal.FormatStyle.Currency` itself.
    func decimalStyle(for currency: Currency) -> Decimal.FormatStyle.Currency {
        var style = Decimal.FormatStyle.Currency(code: String(currency.code), locale: locale)
            .precision(.fractionLength(currency.unitScale.decimalPlaces))

        if presentation != .standard {
            style = style.presentation(presentation)
        }

        if grouping != .automatic {
            style = style.grouping(grouping)
        }

        if sign != .automatic {
            style = style.sign(strategy: sign)
        }

        if decimalSeparator != .automatic {
            style = style.decimalSeparator(strategy: decimalSeparator)
        }

        return style
    }
}

// MARK: - Style accessors

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

// MARK: - Dot syntax

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
