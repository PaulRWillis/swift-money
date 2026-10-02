import SwiftMoneyCore

/// A currency code CLDR names that the packed tables can't hold, with the reason.
package enum UnusableCurrencyCode: Hashable, Sendable {
    /// Text that isn't a currency code, spelled as CLDR gives it.
    case notACurrencyCode(String)

    /// A currency code with more characters than the tables' code field holds.
    case longerThanTheTablesHold(CurrencyCode)
}
