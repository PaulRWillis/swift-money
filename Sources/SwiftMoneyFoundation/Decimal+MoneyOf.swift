import Foundation
import SwiftMoney

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
    let scale = UInt64(Int64(currency.unitScale))
    let places = currency.unitScale.decimalPlaces

    // The scale divides `10 ^ places` exactly, that being what a unit scale guarantees, so the
    // multiplier is whole. A scale stops at eighteen places, so `10 ^ places` reaches `10 ^ 18` and
    // stays inside a `UInt64`, which holds up to `10 ^ 19`.
    let multiplier = UInt64.powerOfTen(places) / scale

    // Multiplied in `Decimal` because the product can pass `UInt64`: a scale of 2 with an amount
    // near `Int64.max` needs twenty digits. It cannot trap `Decimal`'s `*`: the multiplier peaks
    // at `5 ^ 18`, thirteen digits, for a scale of `2 ^ 18`, so the product holds at most
    // thirty-two digits of the thirty-eight `Decimal` can, and the exponent of `-places` is at
    // worst -18 against a floor of -128.
    let scaled = Decimal(minorUnits.magnitude) * Decimal(multiplier)

    // Signed last, the magnitude having carried the digits, so that `Int64.min` never needs an
    // `Int64` of its own to sit in.
    return Decimal(
        sign: minorUnits < 0 ? .minus : .plus,
        exponent: -places,
        significand: scaled
    )
}
