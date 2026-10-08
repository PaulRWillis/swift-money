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

    /// A generator of two runtime-currency amounts whose minor units fall in `range`, both in one
    /// currency drawn from `currency`.
    static func runtimeMoneyPair(
        minorUnitsIn range: ClosedRange<Int64>,
        currency: Gen<Currency>
    ) -> Gen<(Money, Money)> {
        zip(currency, zip(Gen<Int64>.int(in: range), Gen<Int64>.int(in: range))).map { currency, units in
            (Money(minorUnits: units.0, currency: currency), Money(minorUnits: units.1, currency: currency))
        }
    }
}
