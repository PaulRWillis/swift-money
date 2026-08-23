import Foundation
import SwiftMoney

public extension Decimal {
    /// Creates a decimal number of major units from a monetary amount.
    ///
    /// ```swift
    /// Decimal(exactly: GBP(minorUnits: 4_99))   // 4.99
    /// Decimal(exactly: JPY(minorUnits: 499))    // 499
    /// ```
    ///
    /// The conversion loses nothing. Every amount the currency can hold converts, and
    /// ``MoneyOf/init(majorUnits:)`` or ``MoneyOf/init(majorUnits:currency:)`` turns the result
    /// back into the amount it came from.
    ///
    /// A currency has an exact decimal form only where its scale is `2 ^ a * 5 ^ b` and reaches no
    /// further than eighteen decimal places. Every ISO 4217 currency qualifies. A pound of 240 pence
    /// does not, one penny of it being 0.0041666…, and this returns `nil` for any amount in it.
    ///
    /// - Parameter money: The amount to convert.
    /// - Returns: `nil` unless the amount's currency has an exact decimal form.
    @inlinable
    init?<C: CurrencyRepresentation>(exactly money: MoneyOf<C>) {
        guard let majorUnits = exactMajorUnits(money.minorUnits, in: money.currency) else {
            return nil
        }

        self = majorUnits
    }
}

// The major units an amount holds, as a decimal number. `nil` where the currency has no exact
// decimal form.
@usableFromInline
func exactMajorUnits(
    _ minorUnits: Money.MinorUnits,
    in currency: Currency
) -> Decimal? {
    let scale = UInt64(Int64(currency.unitScale))

    guard let places = scale.exactDecimalPlaces else {
        return nil
    }

    // The scale divides `10 ^ places` exactly, that being what `exactDecimalPlaces` reports, so the
    // multiplier is whole. Eighteen places is as far as it goes, which keeps `10 ^ places` inside a
    // `UInt64`.
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
