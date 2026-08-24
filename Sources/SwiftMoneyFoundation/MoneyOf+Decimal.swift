import Foundation
import SwiftMoney

public extension MoneyOf where C: CurrencyType {
    /// Creates an amount from a decimal number of major units, in the currency this type names.
    ///
    /// ```swift
    /// // `listed` holds 4.99, decoded from a supplier's price feed.
    /// GBP(majorUnits: listed)   // £4.99
    /// JPY(majorUnits: listed)   // nil: yen have no subunit, so 4.99 of them is not an amount
    /// ```
    ///
    /// Nothing is rounded. A number finer than the currency divides is refused, so `4.999` in
    /// sterling is `nil` rather than a penny either way.
    ///
    /// - Parameter majorUnits: The amount, counted in the currency's major units.
    /// - Returns: `nil` unless the currency can hold this amount exactly.
    @inlinable
    init?(majorUnits: Decimal) {
        guard let minorUnits = exactMinorUnits(majorUnits, in: C.currency) else {
            return nil
        }

        self.init(exactly: minorUnits)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Creates an amount from a decimal number of major units, in a currency the caller names.
    ///
    /// ```swift
    /// // `listed` holds 4.99, decoded from a supplier's price feed.
    /// Money(majorUnits: listed, currency: .gbp)   // £4.99
    /// ```
    ///
    /// Nothing is rounded. A number finer than the currency divides is refused, so `4.999` in
    /// sterling is `nil` rather than a penny either way.
    ///
    /// - Parameters:
    ///   - majorUnits: The amount, counted in the currency's major units.
    ///   - currency: The currency to denominate the amount in.
    /// - Returns: `nil` unless the currency can hold this amount exactly.
    init?(
        majorUnits: Decimal,
        currency: Currency
    ) {
        guard let minorUnits = exactMinorUnits(majorUnits, in: currency) else {
            return nil
        }

        self.init(exactly: minorUnits, currency: currency)
    }
}

// The smallest units a decimal number of major units holds, in a currency the caller already knows.
// `nil` where the number is finer than the currency divides, and where the count is too large to
// store.
@usableFromInline
func exactMinorUnits(
    _ majorUnits: Decimal,
    in currency: Currency
) -> Money.MinorUnits? {
    guard majorUnits.isFinite else {
        return nil
    }

    var value = majorUnits
    var multiplier = Decimal(UInt64(Int64(currency.unitScale)))
    var product = Decimal()

    // Through `NSDecimalMultiply` rather than `*`, because the operator traps on overflow and this
    // has to answer `nil` for a number no currency can hold.
    guard NSDecimalMultiply(&product, &value, &multiplier, .plain) == .noError else {
        return nil
    }

    var whole = Decimal()
    NSDecimalRound(&whole, &product, 0, .plain)

    // The rounded value is compared, never used: what the currency cannot hold exactly is refused
    // here, because rounding it away would be losing money quietly.
    guard whole == product else {
        return nil
    }

    // Read through the digits rather than `NSDecimalNumber.int64Value`, which wraps silently and
    // hands back `Int64.min` for `9223372036854775808`. `Decimal` writes the same digits in every
    // locale, so `Int64(_:)` converts and range checks in one step.
    return Money.MinorUnits(whole.description)
}
