// Extraction runs through an initializer on the target type, so that the width an amount is stored
// in never has to become public. The extension sits on `BinaryInteger` rather than on each integer
// type, so one declaration serves `Int`, `Int32`, `UInt64` and every other conformer.
//
// The member reads one operand and passes no storage anywhere, so no currency can mismatch. One
// unconditional extension therefore serves both seams, and `Money` needs no throwing twin.
public extension BinaryInteger {
    /// Creates the count of the currency's smallest (minor) units in an amount, if this type holds
    /// that count.
    ///
    /// ```swift
    /// Int(minorUnitsOf: GBP(minorUnits: 4_99))   // 499
    /// Int(minorUnitsOf: JPY(minorUnits: 499))    // 499
    /// ```
    ///
    /// The count alone does not say what the amount is worth, because how many minor units make
    /// one major unit depends on the currency. ``MoneyOf/currency`` reports which currency the
    /// amount is in, and ``MoneyOf/init(minorUnits:)`` or ``MoneyOf/init(minorUnits:currency:)``
    /// turns the count back into the amount it came from. For major units, convert to `Decimal`
    /// through `SwiftMoneyFoundation`.
    ///
    /// There is no trapping form. Whether a count fits depends on the width an amount is stored
    /// in, and that width is deliberately private, so no conversion out of an amount can promise
    /// to succeed. `Int` holds 32 bits on watchOS and 64 bits on every other Apple platform, so
    /// even `Int` is not always wide enough.
    ///
    /// - Parameter money: The amount to read.
    /// - Returns: `nil` if the count is outside the range this type holds.
    @inlinable
    init?<C: CurrencyRepresentation>(minorUnitsOf money: MoneyOf<C>) {
        self.init(exactly: money.minorUnits)
    }
}
