import Foundation
import SwiftMoneyCore

public extension JSONEncoder {
    /// The shape money takes on the wire.
    ///
    /// Nothing has to set one. An amount writes `"GBP 499"` until this changes.
    ///
    /// ```swift
    /// let encoder = JSONEncoder()
    /// encoder.moneyCodingFormat = .fields
    /// ```
    var moneyCodingFormat: MoneyCodingFormat {
        get { userInfo[.moneyCodingFormat] as? MoneyCodingFormat ?? .codedString }
        set { userInfo[.moneyCodingFormat] = newValue }
    }
}
