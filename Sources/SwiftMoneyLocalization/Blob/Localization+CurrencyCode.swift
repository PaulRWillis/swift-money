import SwiftMoneyCore

extension Localization {
    /// A currency code the packed tables can hold: one of exactly three characters.
    ///
    /// The tables key their currency records on this, sorted in its order. To read one from text,
    /// parse Core's code first.
    ///
    /// ```swift
    /// let currencyCode: CurrencyCode = "GBP"
    /// Localization.CurrencyCode(currencyCode)?.value   // 28816
    ///
    /// let tooLong: CurrencyCode = "USDT"
    /// Localization.CurrencyCode(tooLong)               // nil
    /// ```
    package struct CurrencyCode: Equatable, Hashable, Sendable {
        /// The code's three characters, packed into the 18 bits a record's code field holds.
        package let value: UInt64

        /// How many ``BlobDigits`` a record's code field takes: 3, one per character.
        package static let digitCount = 3

        /// Creates the code the tables file a currency under, or `nil` if they can't hold it.
        ///
        /// ```swift
        /// let gbp: CurrencyCode = "GBP"
        /// let usdt: CurrencyCode = "USDT"
        /// Localization.CurrencyCode(gbp)?.value   // 28816
        /// Localization.CurrencyCode(usdt)         // nil
        /// ```
        ///
        /// - Parameter code: The currency code.
        /// - Returns: `nil` unless `code` is three characters long.
        package init?(_ code: SwiftMoneyCore.CurrencyCode) {
            guard let value = code.threeCharacterValue else {
                return nil
            }

            self.value = value
        }
    }
}

extension Localization.CurrencyCode: Comparable {
    /// Returns whether the first code comes before the second in the tables' record order.
    ///
    /// - Parameters:
    ///   - lhs: A code to compare.
    ///   - rhs: Another code to compare.
    /// - Returns: `true` if `lhs` sorts before `rhs`; otherwise, `false`.
    package static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}
