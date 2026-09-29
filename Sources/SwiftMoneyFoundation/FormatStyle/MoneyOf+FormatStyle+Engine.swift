import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization

// `internal` rather than `private`: these are called from sibling files (the Attributed and
// Rounding splits, and the main FormatStyle file's `format(_:)`), which needs at least module
// visibility now that they no longer share a file. Still no wider than before the split — none
// of this was ever part of the public API.
extension MoneyOf.FormatStyle {
    // The engine descriptor and options for this style, or nil to fall back to the ICU path. Non-nil
    // only when the style maps exactly onto the engine — default (currency-scale) precision, no
    // increment rounding, a sign and presentation the engine can express, and the amount's locale one
    // our CLDR data covers. Shared by the string and attributed renderers so both cover the same cells.
    func engineRenderInputs(for value: MoneyOf<C>) -> (descriptor: MoneyFormat, options: MoneyFormatOptions)? {
        guard
            roundingIncrement == nil,
            let precision = enginePrecision,
            let sign = engineSign,
            let format = engineFormat(for: value)
        else {
            return nil
        }

        // A full name's plural form follows the digits shown, which the engine reads from the currency
        // scale; an explicit fraction length changes the digits without changing the scale, so it stays
        // on ICU.
        if presentation == .fullName, self.precision != nil {
            return nil
        }

        let options = MoneyFormatOptions(
            sign: sign,
            grouping: engineGrouping,
            decimalSeparator: engineDecimalSeparator,
            precision: precision
        )
        return (format, options)
    }

    // Foundation's precision as the engine's, or nil to fall back. The default is the currency scale;
    // a fixed fraction length passes through with the style's rounding rule, parsed into the engine's.
    // Significant-digit and range forms, and a rule the engine doesn't have, fall back.
    var enginePrecision: MoneyFormatOptions.Precision? {
        guard let precision else {
            return .currencyScale
        }
        guard let length = Self.fractionLength(of: precision) else {
            return nil
        }
        return RoundingRule(roundingRule).map { .fixed(length, rounding: $0) }
    }

    // The fixed fraction length a precision asks for, or nil for any other form. `Precision` is opaque
    // but `Equatable`, so it is matched by comparison; the bound spans every length an `Int64` holds.
    static func fractionLength(of precision: Configuration.Precision) -> FractionLength? {
        for length in 0...19 where precision == .fractionLength(length) {
            return FractionLength(exactly: length)
        }
        return nil
    }

    // The amount rendered by the Foundation-free engine, or nil to fall back to ICU. Output matches
    // ICU except where CLDR is the agreed source of truth.
    func engineFormatted(_ value: MoneyOf<C>) -> String? {
        engineRenderInputs(for: value).map { $0.descriptor.format(value, options: $0.options) }
    }

    // The amount as an AttributedString built from the engine's runs, or nil to fall back to ICU. The
    // text is identical to `engineFormatted`; each run carries Foundation's number attribute.
    func engineAttributed(_ value: MoneyOf<C>) -> AttributedString? {
        engineRenderInputs(for: value).map { inputs in
            var result = AttributedString()
            for run in inputs.descriptor.runs(value, options: inputs.options) {
                if let attribute = Self.attribute(for: run) {
                    result.append(AttributedString(run.text, attributes: attribute))
                } else {
                    result.append(AttributedString(run.text))
                }
            }
            return result
        }
    }

    // Foundation's attribute for a run, or nil for a run it leaves untagged (spacing and literals).
    static func attribute(for run: MoneyFormatRun) -> AttributeContainer? {
        var container = AttributeContainer()
        switch run {
        case .sign: container.numberSymbol = .sign
        case .currency: container.numberSymbol = .currency
        case .groupingSeparator:
            // A grouping separator sits inside the integer, so ICU tags it as both, and this matches.
            container.numberSymbol = .groupingSeparator
            container.numberPart = .integer
        case .decimalSeparator: container.numberSymbol = .decimalSeparator
        case .integerDigits: container.numberPart = .integer
        case .fractionDigits: container.numberPart = .fraction
        case .currencySpacing, .literal, .directionalMark: return nil
        }
        return container
    }

    // The descriptor for this style's presentation, or nil for one the CLDR data cannot name. A full
    // name depends on the amount, since a locale may name one unit differently from two, so it is
    // resolved from the amount rather than from a presentation.
    func engineFormat(for value: MoneyOf<C>) -> MoneyFormat? {
        // Strip any `@`-keyword suffix (e.g. `@numbers=arab`) so the base identifier resolves in the blob.
        let identifier = LocaleIdentifier(String(locale.identifier.prefix { $0 != "@" }))

        // `Locale.numberingSystem` always resolves to a concrete system, so an unmodelled resolution (a
        // `nil` cache) means the caller asked for one we cannot render (e.g. hanidec), not that they
        // expressed no preference. Fall back to ICU rather than silently render the locale's default digits.
        // The engine is told the concrete system explicitly; the bridge never leaves the choice automatic.
        guard let numberingSystem = resolvedNumberingSystem else {
            return nil
        }
        let numberingSelection = NumberingSystemSelection.explicit(numberingSystem)

        // A custom currency renders from the display on its type. When that yields nothing (the currency
        // is not custom, the locale is uncovered, or it supplies no display), fall through to the CLDR
        // path, which for a custom currency renders the raw code and for a shipped one its own data.
        if let custom = customFormat(
            for: value, locale: identifier, presentation: presentation,
            enginePresentation: enginePresentation, numberingSystem: numberingSelection
        ) {
            return custom
        }

        guard presentation != .fullName else {
            return MoneyLocalization.fullNameMoneyFormat(
                for: value.currency,
                minorUnits: value.minorUnits,
                locale: identifier,
                numberingSystem: numberingSelection
            )
        }

        return enginePresentation.flatMap {
            MoneyLocalization.moneyFormat(
                for: value.currency, locale: identifier, presentation: $0, numberingSystem: numberingSelection
            )
        }
    }

    // Foundation's presentation as the engine's, or nil for one the engine names another way.
    var enginePresentation: CurrencyPresentation? {
        if presentation == .standard { .standard }
        else if presentation == .isoCode { .isoCode }
        else if presentation == .narrow { .narrow }
        else { nil }
    }

    // Foundation's sign strategy as the engine's, or nil for a variant the engine cannot express exactly,
    // e.g. `.always(includeZero: false)`.
    var engineSign: MoneyFormatOptions.Sign? {
        if sign == .automatic { .automatic }
        else if sign == .never { .never }
        else if sign == .always() { .always }
        else if sign == .accounting { .accounting }
        else { nil }
    }

    var engineGrouping: MoneyFormatOptions.Grouping {
        grouping == .never ? .never : .automatic
    }

    var engineDecimalSeparator: MoneyFormatOptions.DecimalSeparator {
        decimalSeparator == .always ? .always : .automatic
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
    //
    // `package` rather than `internal`: lets other code in the package build the same ICU-equivalent
    // style instead of reimplementing the only-if-non-default rule above.
    package func decimalStyle(for currency: Currency) -> Decimal.FormatStyle.Currency {
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
