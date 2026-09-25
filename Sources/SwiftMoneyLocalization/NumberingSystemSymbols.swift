import SwiftMoneyCore

// The separators a numbering system brings with it, for a system that imposes its own rather than
// keeping the locale's. Carried only by ``SeparatorProvenance/imposesOwn(_:)``, so a system that reuses
// the locale's separators can never surface phantom ones.
package struct NumberingSystemSymbols: Equatable, Hashable, Sendable {
    // The decimal separator the system writes, e.g. Arabic-Indic `٫`.
    package let decimalSeparator: String
    // The digit-group separator, e.g. Arabic-Indic `٬`.
    package let groupingSeparator: GroupingSeparator
    // The minus sign, which for these systems carries its own directional marks.
    package let minusSign: String

    package init(decimalSeparator: String, groupingSeparator: GroupingSeparator, minusSign: String) {
        self.decimalSeparator = decimalSeparator
        self.groupingSeparator = groupingSeparator
        self.minusSign = minusSign
    }
}
