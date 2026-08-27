/// A price for one unit of some measure, finer than the currency's smallest unit.
///
/// Some prices sit below a minor unit — an energy tariff of £0.023 per kWh, a data rate of £0.00000231
/// per KB. Such a price cannot be a ``MoneyOf`` (a whole number of minor units), so a `UnitPrice` holds
/// it unsettled and resolves a quantity to an amount that is rounded once, at the end.
///
/// ```swift
/// let tariff = UnitPrice<Currencies.GBP, String>(GBP.Unrounded(majorUnits: "0.023"), per: "kWh")
/// let bill = tariff.total(for: 1_000).rounded(.toNearestOrEven)   // £23.00
/// ```
///
/// The unit is part of the type, so a price per kWh and a price per litre are different types. The unit
/// is otherwise a label: this type does not check that a quantity is measured in the same unit — pairing
/// a quantity's dimension with the price's is the job of the `Measurement` support in
/// `SwiftMoneyFoundation`.
public struct UnitPrice<C: CurrencyType, Unit: Hashable & Sendable>: Sendable, Equatable {
    /// The price of one unit, held exact below the currency's smallest unit until it is settled.
    public let amountPerUnit: MoneyOf<C>.Unrounded

    /// The unit the price is per.
    public let unit: Unit

    /// Creates a price per one unit of a measure.
    ///
    /// - Parameters:
    ///   - amountPerUnit: The price of a single unit, which may be finer than a minor unit.
    ///   - unit: The unit the price is per.
    public init(
        _ amountPerUnit: MoneyOf<C>.Unrounded,
        per unit: Unit
    ) {
        self.amountPerUnit = amountPerUnit
        self.unit = unit
    }
}

public extension UnitPrice {
    /// Returns the total for a fractional quantity, kept exact until it is settled.
    ///
    /// The whole calculation stays unsettled, so a bill built from several sub-unit prices rounds once
    /// rather than at each line.
    ///
    /// - Parameter quantity: How many units, as a rate for a fractional amount (`"350.5"`).
    /// - Precondition: the total is representable.
    func total(for quantity: Rate) -> MoneyOf<C>.Unrounded {
        amountPerUnit * quantity
    }

    /// Returns the total for a whole quantity, kept exact until it is settled.
    ///
    /// - Parameter quantity: How many units.
    /// - Precondition: the total is representable.
    func total(for quantity: some BinaryInteger) -> MoneyOf<C>.Unrounded {
        amountPerUnit * quantity
    }
}
