import SwiftMoneyCore
import SwiftMoneyLocalization

/// One locale's currency entries from CLDR, split by whether the packed tables can hold each code.
///
/// ```swift
/// let entries = LocaleCurrencyEntries([(code: "GBP", fields: "£"), (code: "USDT", fields: "₮")])
/// entries.held.map(\.fields)   // ["£"]
/// entries.unusableCodes        // ["USDT"]
/// ```
package struct LocaleCurrencyEntries<Fields> {
    /// The entries whose code the tables can hold, in the order they were given.
    package let held: [Entry]

    /// The codes, as CLDR spells them, that the tables can't hold.
    package let unusableCodes: Set<String>

    /// One currency the tables can hold: the code they file it under, and what CLDR publishes for it.
    package struct Entry {
        /// The code the tables file the currency under.
        package let code: Localization.CurrencyCode

        /// What CLDR publishes for the currency.
        package let fields: Fields

        /// Creates an entry from a code the split has already parsed.
        ///
        /// - Parameters:
        ///   - code: The code the tables file the currency under.
        ///   - fields: What CLDR publishes for the currency.
        fileprivate init(code: Localization.CurrencyCode, fields: Fields) {
            self.code = code
            self.fields = fields
        }
    }

    /// Creates the split of a locale's entries.
    ///
    /// Each code is read as `CurrencyCode(string:)` reads it, so lowercase is accepted, and is held
    /// only if it has three characters.
    ///
    /// ```swift
    /// LocaleCurrencyEntries([(code: "USDT", fields: "₮")]).unusableCodes   // ["USDT"]
    /// ```
    ///
    /// - Parameter published: Each currency's code as CLDR spells it, with its fields, in the order
    ///   to keep.
    package init(_ published: some Sequence<(code: String, fields: Fields)>) {
        var held: [Entry] = []
        var unusableCodes: Set<String> = []

        for (code, fields) in published {
            guard
                let currencyCode = CurrencyCode(string: code),
                let tableCode = Localization.CurrencyCode(currencyCode)
            else {
                unusableCodes.insert(code)
                continue
            }

            held.append(Entry(code: tableCode, fields: fields))
        }

        self.held = held
        self.unusableCodes = unusableCodes
    }
}

extension LocaleCurrencyEntries: Equatable where Fields: Equatable {}
extension LocaleCurrencyEntries: Hashable where Fields: Hashable {}
extension LocaleCurrencyEntries: Sendable where Fields: Sendable {}
extension LocaleCurrencyEntries.Entry: Equatable where Fields: Equatable {}
extension LocaleCurrencyEntries.Entry: Hashable where Fields: Hashable {}
extension LocaleCurrencyEntries.Entry: Sendable where Fields: Sendable {}
