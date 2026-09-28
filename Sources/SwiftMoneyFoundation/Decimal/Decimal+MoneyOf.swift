import Foundation
import SwiftMoneyCore

public extension Decimal {
    /// Creates the exact count of the currency's major units in an amount.
    ///
    /// ```swift
    /// Decimal(majorUnitsOf: GBP(minorUnits: 4_99))   // 4.99
    /// Decimal(majorUnitsOf: JPY(minorUnits: 499))    // 499
    /// ```
    ///
    /// The conversion keeps the value. It cannot fail and it cannot round, because every currency
    /// divides into an exact decimal, so every amount of every currency has one.
    /// ``MoneyOf/init(majorUnits:)`` or ``MoneyOf/init(majorUnits:currency:)`` turns the result
    /// back into the amount it came from.
    ///
    /// The label names the units, because the same amount reads as two different numbers. This
    /// gives 4.99 where `Int(minorUnitsOf:)` gives 499, and the two differ by the currency's
    /// scale, which is a hundred for sterling and one for yen.
    ///
    /// - Parameter money: The amount to convert.
    @inlinable
    init<C: CurrencyRepresentation>(majorUnitsOf money: MoneyOf<C>) {
        self = exactMajorUnits(money.minorUnits, in: money.currency)
    }
}

// The major units an amount holds, as a decimal number.
@usableFromInline
func exactMajorUnits(
    _ minorUnits: Money.MinorUnits,
    in currency: Currency
) -> Decimal {
    // A unit scale is a power of ten, so the minor units are the significand as they stand. Signed
    // last, the magnitude carrying the digits, so that `Int64.min` never needs an `Int64` of its own.
    Decimal(
        sign: minorUnits < 0 ? .minus : .plus,
        exponent: -currency.unitScale.decimalPlaces,
        significand: Decimal(minorUnits.magnitude)
    )
}
