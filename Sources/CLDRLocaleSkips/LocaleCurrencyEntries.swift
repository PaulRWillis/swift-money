import SwiftMoneyCore
import SwiftMoneyLocalization

/// One locale's currency entries from CLDR, split by whether the packed tables can hold each code.
///
/// ```swift
/// let published = [(code: "GBP", fields: "£"), (code: "USDT", fields: "₮")]
/// let entries = LocaleCurrencyEntries(parsing: published)
/// entries.held.map(\.fields)   // ["£"]
/// entries.unusableCodes        // [.longerThanTheTablesHold("USDT")]
/// ```
package struct LocaleCurrencyEntries<Fields> {
    /// The entries whose code the tables can hold, in the order they were given.
    package let held: [Entry]

    /// The codes the tables can't hold, each with the reason.
    package let unusableCodes: Set<UnusableCurrencyCode>

    /// One currency the tables can hold: the code they file it under, and what CLDR publishes for it.
    package struct Entry {
        /// The code the tables file the currency under.
        package let code: Localization.CurrencyCode

        /// What CLDR publishes for the currency.
        package let fields: Fields

        /// Creates an entry from a code the split has already narrowed.
        ///
        /// - Parameters:
        ///   - code: The code the tables file the currency under.
        ///   - fields: What CLDR publishes for the currency.
        fileprivate init(code: Localization.CurrencyCode, fields: Fields) {
            self.code = code
            self.fields = fields
        }
    }

    /// Creates the split of a locale's entries from Core's currency codes.
    ///
    /// A code is held only if it has three characters.
    ///
    /// ```swift
    /// let usdt: CurrencyCode = "USDT"
    /// let entries = LocaleCurrencyEntries([(code: usdt, fields: "₮")])
    /// entries.unusableCodes   // [.longerThanTheTablesHold("USDT")]
    /// ```
    ///
    /// - Parameter published: Each currency's code with its fields, in the order to keep.
    package init(_ published: some Sequence<(code: CurrencyCode, fields: Fields)>) {
        var held: [Entry] = []
        var unusableCodes: Set<UnusableCurrencyCode> = []

        for (currencyCode, fields) in published {
            guard let tableCode = Localization.CurrencyCode(currencyCode) else {
                unusableCodes.insert(.longerThanTheTablesHold(currencyCode))
                continue
            }

            held.append(Entry(code: tableCode, fields: fields))
        }

        self.init(held: held, unusableCodes: unusableCodes)
    }

    /// Creates the split of a locale's entries from codes as CLDR spells them.
    ///
    /// Each code is read as `CurrencyCode(string:)` reads it, so lowercase is accepted, and is held
    /// only if it has three characters.
    ///
    /// ```swift
    /// let entries = LocaleCurrencyEntries(parsing: [(code: "G-P", fields: "?")])
    /// entries.unusableCodes   // [.notACurrencyCode("G-P")]
    /// ```
    ///
    /// - Parameter published: Each currency's code as CLDR spells it, with its fields, in the order
    ///   to keep.
    package init(parsing published: some Sequence<(code: String, fields: Fields)>) {
        var parsed: [(code: CurrencyCode, fields: Fields)] = []
        var notCurrencyCodes: Set<UnusableCurrencyCode> = []

        for (text, fields) in published {
            guard let currencyCode = CurrencyCode(string: text) else {
                notCurrencyCodes.insert(.notACurrencyCode(text))
                continue
            }

            parsed.append((currencyCode, fields))
        }

        let narrowed = Self(parsed)
        self.init(held: narrowed.held, unusableCodes: narrowed.unusableCodes.union(notCurrencyCodes))
    }

    /// Creates a split from its parts.
    ///
    /// - Parameters:
    ///   - held: The entries whose code the tables can hold.
    ///   - unusableCodes: The codes the tables can't hold.
    private init(held: [Entry], unusableCodes: Set<UnusableCurrencyCode>) {
        self.held = held
        self.unusableCodes = unusableCodes
    }

    /// Returns the split with each held entry's fields transformed, keeping its codes and its
    /// unusable codes.
    ///
    /// ```swift
    /// let published = [(code: "GBP", fields: 1), (code: "USDT", fields: 2)]
    /// let entries = LocaleCurrencyEntries(parsing: published)
    /// let scaled = entries.map { $0 * 10 }
    /// scaled.held.map(\.fields)   // [10]
    /// scaled.unusableCodes        // [.longerThanTheTablesHold("USDT")]
    /// ```
    ///
    /// - Parameter transform: The transform applied to each held entry's fields, in order.
    /// - Returns: The split with the transformed fields.
    /// - Throws: The first error `transform` throws.
    /// - Complexity: O(*n*), where *n* is the number of held entries.
    package func map<T, E: Error>(
        _ transform: (Fields) throws(E) -> T
    ) throws(E) -> LocaleCurrencyEntries<T> {
        let mapped = try held.map { entry throws(E) in
            LocaleCurrencyEntries<T>.Entry(code: entry.code, fields: try transform(entry.fields))
        }

        return LocaleCurrencyEntries<T>(held: mapped, unusableCodes: unusableCodes)
    }
}

extension LocaleCurrencyEntries: Equatable where Fields: Equatable {}
extension LocaleCurrencyEntries: Hashable where Fields: Hashable {}
extension LocaleCurrencyEntries: Sendable where Fields: Sendable {}
extension LocaleCurrencyEntries.Entry: Equatable where Fields: Equatable {}
extension LocaleCurrencyEntries.Entry: Hashable where Fields: Hashable {}
extension LocaleCurrencyEntries.Entry: Sendable where Fields: Sendable {}
