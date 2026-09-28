import Foundation
import SwiftMoneyCore

public extension JSONDecoder {
    /// The field names and the units that money is read with.
    ///
    /// A payload's own shape decides how it reads, so this supplies only the keys of a two-field
    /// object and the units that a number, or a string's digits without a point, count. A `.` in a
    /// string always means major units.
    ///
    /// Nothing has to set one. Until this changes, `"GBP 15"` and `15` count the currency's
    /// smallest units.
    ///
    /// ```swift
    /// let decoder = JSONDecoder()
    /// decoder.moneyCodingFormat = .fields(currencyKey: "ccy", amountKey: "value")
    /// ```
    var moneyCodingFormat: MoneyCodingFormat {
        get { userInfo[.moneyCodingFormat] as? MoneyCodingFormat ?? .codedString }
        set { userInfo[.moneyCodingFormat] = newValue }
    }
}
