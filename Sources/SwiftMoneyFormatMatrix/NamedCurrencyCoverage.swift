import SwiftMoneyCore

extension FormatMatrix {
    /// How many of the currencies the library ships this locale's CLDR data names in words.
    ///
    /// A currency it does not name renders its full name through ICU instead, so this counts how much
    /// of the full-name presentation the engine carries on its own for one locale.
    package static func namedCurrencyCount(forLocale localeID: String) -> Int {
        Currency.allISO4217.count { isEngineCovered($0, localeID: localeID, presentation: .fullName) }
    }

    /// Every covered locale's named currencies added together.
    ///
    /// The golden digests say whether a locale's output changed, but not in which direction: a name
    /// that disappears and a name that is corrected both read as one digest moving. This is the
    /// number that says coverage went down, and it is committed beside them for that reason.
    package static var namedCurrencyTotal: Int {
        coveredLocaleIDs.reduce(0) { $0 + namedCurrencyCount(forLocale: $1) }
    }

    /// How many covered locales name no currency at all.
    ///
    /// Some legitimately name none: a locale that inherits from CLDR's root gets the symbols but no
    /// display names, and ICU renders it the same way, so its output is right rather than missing.
    /// Committed as a number instead of forbidden, so that a change in it has to be justified.
    package static var localesNamingNoCurrency: Int {
        coveredLocaleIDs.count { namedCurrencyCount(forLocale: $0) == 0 }
    }
}
