import Foundation
import SwiftMoney

public extension JSONDecoder {
    /// The field names and the number units that money is read with.
    ///
    /// A payload's own shape decides how it reads, so this supplies only the keys of a two-field
    /// object and the units that a bare number counts.
    ///
    /// Nothing has to set one. A bare number counts the currency's smallest units until this
    /// changes.
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
