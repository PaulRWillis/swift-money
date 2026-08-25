// Extraction runs through an initializer on the target type, so that the width an amount is stored
// in never has to become public. The extension sits on `BinaryInteger` rather than on each integer
// type, so one declaration serves `Int`, `Int32`, `UInt64` and every other conformer.
//
// The member reads one operand and passes no storage anywhere, so no currency can mismatch. One
// unconditional extension therefore serves both seams, and `Money` needs no throwing twin.
public extension BinaryInteger {
    /// Creates the number of the currency's smallest (minor) units an amount holds.
    ///
    /// ```swift
    /// Int(minorUnits: GBP(minorUnits: 4_99))   // 499
    /// Int(minorUnits: JPY(minorUnits: 499))    // 499
    /// ```
    ///
    /// The number alone does not say what the amount is worth, because how many minor units make
    /// one major unit depends on the currency. ``MoneyOf/currency`` reports which currency the
    /// amount is in, and ``MoneyOf/init(minorUnits:)`` turns the number back into the amount it
    /// came from. For major units, convert to `Decimal` through `SwiftMoneyFoundation`.
    ///
    /// - Parameter money: The amount to read.
    /// - Precondition: This type can hold the number. A number outside its range traps, as
    ///   `Int8(3_000)` does.
    @inlinable
    init<C: CurrencyRepresentation>(minorUnits money: MoneyOf<C>) {
        self.init(money.minorUnits)
    }

    /// Creates the number of the currency's smallest (minor) units an amount holds, if this type
    /// is wide enough.
    ///
    /// Use this where the amount can outgrow the target type on some platform. `Int` holds 32 bits
    /// on watchOS and 64 elsewhere, so a large amount reads back there and not here.
    ///
    /// ```swift
    /// Int8(exactly: GBP(minorUnits: 99))     // 99
    /// Int8(exactly: GBP(minorUnits: 4_99))   // nil
    /// ```
    ///
    /// - Parameter money: The amount to read.
    /// - Returns: `nil` if the number is outside the range this type holds.
    @inlinable
    init?<C: CurrencyRepresentation>(exactly money: MoneyOf<C>) {
        self.init(exactly: money.minorUnits)
    }
}
