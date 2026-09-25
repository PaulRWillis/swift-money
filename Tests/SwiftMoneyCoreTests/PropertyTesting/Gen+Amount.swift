import SwiftMoneyCore

extension Gen where Value == GBP {
    /// A generator of sterling amounts whose minor units fall in `range`.
    ///
    /// The range is the caller's overflow budget: every suite passes a bound proved to keep the
    /// operations it exercises inside `Int64`. `GBP(minorUnits:)` traps only outside `Int64`, which a
    /// range of `Int64` bounds can never ask for, so no draw fails.
    static func typedMoney(minorUnitsIn range: ClosedRange<Int64>) -> Gen<GBP> {
        Gen<Int64>.int(in: range).map { GBP(minorUnits: $0) }
    }
}

extension Gen where Value == Money {
    /// A generator of runtime-currency amounts whose minor units fall in `range`, in a currency drawn
    /// from `currency`.
    static func runtimeMoney(
        minorUnitsIn range: ClosedRange<Int64>,
        currency: Gen<Currency>
    ) -> Gen<Money> {
        zip(Gen<Int64>.int(in: range), currency).map { units, currency in
            Money(minorUnits: units, currency: currency)
        }
    }
}
