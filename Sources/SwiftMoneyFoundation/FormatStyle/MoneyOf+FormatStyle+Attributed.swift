import Foundation
import SwiftMoneyCore

public extension MoneyOf.FormatStyle {
    /// This style, rendering an `AttributedString` whose runs carry Foundation's number attributes
    /// (`numberPart` and `numberSymbol`), the same tagging `Decimal.FormatStyle.Currency.attributed`
    /// applies.
    ///
    /// ```swift
    /// let attributed = GBP(minorUnits: 4_99).formatted(.currency().attributed)
    /// ```
    var attributed: Attributed { Attributed(base: self) }

    /// A currency style whose output is an `AttributedString`.
    ///
    /// A covered locale renders through the engine, so the text matches ``format(_:)`` exactly; an
    /// uncovered one falls back to `Decimal.FormatStyle.Currency`'s own attributed output.
    struct Attributed: Foundation.FormatStyle {
        var base: MoneyOf.FormatStyle

        /// The amount, rendered as an attributed string for the locale this style holds.
        public func format(_ value: MoneyOf<C>) -> AttributedString {
            base.engineAttributed(value)
                ?? base.decimalStyle(for: value.currency).attributed.format(base.majorUnits(of: value))
        }

        /// The same style rendering in `locale` instead.
        public func locale(_ locale: Locale) -> Self {
            Attributed(base: base.locale(locale))
        }
    }
}
