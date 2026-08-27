import Foundation
import SwiftMoneyCore

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

        private var locale: Locale
        private var presentation: Configuration.Presentation
        private var grouping: Configuration.Grouping
        private var sign: Configuration.SignDisplayStrategy
        private var decimalSeparator: Configuration.DecimalSeparatorDisplayStrategy
        private var roundingRule: Configuration.RoundingRule

        // `nil` means the currency decides, which is the whole point of the default: the style
        // shows every unit the currency divides into and no more, so nothing is rounded away.
        private var precision: Configuration.Precision?

        // `nil` leaves the amount alone.
        private var roundingIncrement: RoundingIncrement?

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

extension MoneyOf.FormatStyle {
    // Both Codable halves are the compiler's: `RoundingIncrement` refuses a below-one value on
    // decode itself. The keys stay declared so a property rename cannot silently change the wire.
    private enum CodingKeys: String, CodingKey {
        case locale
        case presentation
        case grouping
        case sign
        case decimalSeparator
        case roundingRule
        case precision
        case roundingIncrement
    }
}

extension MoneyOf.FormatStyle: Foundation.FormatStyle {
    /// The amount, rendered for the locale this style holds.
    ///
    /// - Parameter value: The amount to render. Its currency decides the symbol and the digits.
    public func format(_ value: MoneyOf<C>) -> String {
        decimalStyle(for: value.currency).format(majorUnits(of: value))
    }
}

extension MoneyOf.FormatStyle {
    // The style this one renders and parses through, settled for one currency.
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
            .precision(precision ?? .fractionLength(currency.unitScale.decimalPlaces))

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

        if roundingRule != .toNearestOrEven {
            style = style.rounded(rule: roundingRule)
        }

        return style
    }
}

private extension MoneyOf.FormatStyle {
    // The major units to render, after any increment rounding the caller asked for. A step of one
    // is left to fall through, an amount already being a whole count of the smallest units.
    //
    // Rounded here in whole smallest units rather than by ICU, which counts an increment in major
    // units and drops the currency symbol when one is set beside a fraction length. Counting in
    // smallest units is also exact, where a fractional step would not be.
    func majorUnits(of value: MoneyOf<C>) -> Decimal {
        guard let increment = roundingIncrement else {
            return Decimal(majorUnitsOf: value)
        }

        let step = Money.MinorUnits(increment)

        guard step > 1 else {
            return Decimal(majorUnitsOf: value)
        }

        let remainder = value.minorUnits % step

        guard remainder != 0 else {
            return Decimal(majorUnitsOf: value)
        }

        let quotient = value.minorUnits / step

        // Built from the quotient rather than from the amount, so that rounding an amount near
        // the end of the range produces the text it should instead of overflowing. The quotient
        // is at most half the range once the step is two or more, so the carry always fits.
        return Decimal(quotient + carry(remainder: remainder, over: step, from: quotient))
            * exactMajorUnits(step, in: value.currency)
    }

    // Which way the quotient moves: one step away from zero, one step down, or nowhere.
    //
    // The remainder carries the amount's sign, Swift's `%` truncating toward zero, so "away from
    // zero" is the direction the remainder already points in.
    func carry(
        remainder: Money.MinorUnits,
        over step: Money.MinorUnits,
        from quotient: Money.MinorUnits
    ) -> Money.MinorUnits {
        let away: Money.MinorUnits = remainder < 0 ? -1 : 1

        // Doubled in magnitude rather than halving the step, so an odd step still compares
        // exactly, and in unsigned arithmetic so the doubling cannot overflow.
        let doubledRemainder = remainder.magnitude * 2
        let reachesHalfway = doubledRemainder >= step.magnitude
        let passesHalfway = doubledRemainder > step.magnitude

        switch roundingRule {
        case .down:
            return remainder < 0 ? -1 : 0
        case .up:
            return remainder > 0 ? 1 : 0
        case .towardZero:
            return 0
        case .awayFromZero:
            return away
        case .toNearestOrAwayFromZero:
            return reachesHalfway ? away : 0
        case .toNearestOrEven:
            guard reachesHalfway else {
                return 0
            }

            return passesHalfway || !quotient.isMultiple(of: 2) ? away : 0
        @unknown default:
            return reachesHalfway ? away : 0
        }
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
