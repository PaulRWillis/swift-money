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
        private var locale: Locale

        /// Creates a style for the given locale.
        ///
        /// - Parameter locale: The locale to render in. Follows the user's setting by default.
        public init(locale: Locale = .autoupdatingCurrent) {
            self.locale = locale
        }

        /// Returns a copy of this style that renders in the given locale.
        ///
        /// - Parameter locale: The locale to render in.
        public func locale(_ locale: Locale) -> Self {
            var copy = self
            copy.locale = locale
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
    func decimalStyle(for currency: Currency) -> Decimal.FormatStyle.Currency {
        Decimal.FormatStyle.Currency(code: String(currency.code), locale: locale)
            .precision(.fractionLength(currency.unitScale.decimalPlaces))
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
