import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization

extension MoneyOf.FormatStyle {
    // The engine descriptor for a custom currency, or nil when `C` is not a custom currency, the locale
    // is uncovered, or the currency supplies nothing for the presentation. It opens the currency type's
    // existential to read the type's display or names, then calls the same package builders the Embedded
    // path uses, so both render identically. The presentation mapping is passed in rather than recomputed
    // here, since the caller already resolves it.
    func customFormat(
        for value: MoneyOf<C>,
        locale: LocaleIdentifier,
        presentation: Configuration.Presentation,
        enginePresentation: CurrencyPresentation?,
        numberingSystem: NumberingSystemSelection
    ) -> MoneyFormat? {
        guard let type = C.self as? any CustomCurrencyFormattable.Type else {
            return nil
        }

        return customFormat(
            type,
            currency: value.currency,
            minorUnits: value.minorUnits,
            locale: locale,
            presentation: presentation,
            enginePresentation: enginePresentation,
            numberingSystem: numberingSystem
        )
    }

    // Opens the `any CustomCurrencyFormattable.Type` existential to read the type's display or names,
    // then dispatches on presentation to the matching package builder.
    private func customFormat<Custom: CustomCurrencyFormattable>(
        _ type: Custom.Type,
        currency: Currency,
        minorUnits: Int64,
        locale: LocaleIdentifier,
        presentation: Configuration.Presentation,
        enginePresentation: CurrencyPresentation?,
        numberingSystem: NumberingSystemSelection
    ) -> MoneyFormat? {
        if presentation == .fullName {
            return type.names(for: locale).flatMap {
                MoneyLocalization.fullNameMoneyFormat(
                    for: currency, names: $0, minorUnits: minorUnits, locale: locale,
                    numberingSystem: numberingSystem
                )
            }
        }

        return enginePresentation.flatMap { resolved in
            type.display(for: locale).flatMap {
                MoneyLocalization.moneyFormat(
                    for: currency, display: $0, locale: locale, presentation: resolved,
                    numberingSystem: numberingSystem
                )
            }
        }
    }
}
