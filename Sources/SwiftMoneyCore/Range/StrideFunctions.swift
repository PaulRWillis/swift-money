/// Returns the amounts from a start up to, but not including, an end, one stride apart.
///
/// Behaves as the standard library's `stride(from:to:by:)` does for integers:
///
/// ```swift
/// stride(from: GBP(minorUnits: 10_00), to: GBP(minorUnits: 250_00), by: .majorUnits(100))
/// // £10, £110, £210
/// ```
///
/// A negative stride counts down. A stride that points away from `end` gives no amounts, and a step
/// beyond the largest or smallest amount ends the sequence rather than trapping.
///
/// - Parameters:
///   - start: The first amount, unless it is already at or past `end`.
///   - end: The amount the sequence stops before.
///   - stride: The amount each step moves by.
/// - Returns: The amounts, in `start`'s currency.
@inlinable
public func stride<C: CurrencyType>(
    from start: MoneyOf<C>,
    to end: MoneyOf<C>,
    by stride: MoneyOf<C>.Stride
) -> MoneyStrideTo<C> {
    MoneyStrideTo(from: start, to: end, by: stride)
}

/// Returns the amounts from a start up to an end, one stride apart, including the end only if a step
/// lands on it.
///
/// Behaves as the standard library's `stride(from:through:by:)` does for integers, so an end between
/// two steps is left out:
///
/// ```swift
/// stride(from: GBP(minorUnits: 10_00), through: GBP(minorUnits: 250_00), by: .majorUnits(100))
/// // £10, £110, £210: no £250, since no step lands on it
/// ```
///
/// A negative stride counts down. A stride that points away from `end` gives no amounts, and a step
/// beyond the largest or smallest amount ends the sequence rather than trapping.
///
/// - Parameters:
///   - start: The first amount, unless it is already past `end`.
///   - end: The last amount, if a step lands on it.
///   - stride: The amount each step moves by.
/// - Returns: The amounts, in `start`'s currency.
@inlinable
public func stride<C: CurrencyType>(
    from start: MoneyOf<C>,
    through end: MoneyOf<C>,
    by stride: MoneyOf<C>.Stride
) -> MoneyStrideThrough<C> {
    MoneyStrideThrough(from: start, through: end, by: stride)
}

/// Returns the runtime amounts from a start up to, but not including, an end, one stride apart.
///
/// The currencies are checked once, here, so iterating never throws:
///
/// ```swift
/// for amount in try stride(from: minimum, to: maximum, by: .majorUnit(of: minimum)) { … }
/// ```
///
/// Behaves as the standard library's `stride(from:to:by:)` does for integers.
///
/// - Parameters:
///   - start: The first amount, unless it is already at or past `end`.
///   - end: The amount the sequence stops before.
///   - stride: The amount each step moves by.
/// - Returns: The amounts, in `start`'s currency.
/// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `end` or `stride` is in another currency
///   from `start`. `end` is checked first, then `stride`. `lhs` is `start`'s currency, and `rhs` is
///   the first currency that differs.
@inlinable
public func stride(
    from start: Money,
    to end: Money,
    by stride: Money.Stride
) throws(MoneyError) -> MoneyStrideTo<AnyCurrency> {
    try AnyCurrency.requireMatch(start.storage, end.storage)
    try AnyCurrency.requireMatch(start.storage, stride.amount.storage)

    return MoneyStrideTo(from: start, to: end, by: stride)
}

/// Returns the runtime amounts from a start up to an end, one stride apart, including the end only if
/// a step lands on it.
///
/// The currencies are checked once, here, so iterating never throws. Behaves as the standard
/// library's `stride(from:through:by:)` does for integers.
///
/// - Parameters:
///   - start: The first amount, unless it is already past `end`.
///   - end: The last amount, if a step lands on it.
///   - stride: The amount each step moves by.
/// - Returns: The amounts, in `start`'s currency.
/// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `end` or `stride` is in another currency
///   from `start`. `end` is checked first, then `stride`. `lhs` is `start`'s currency, and `rhs` is
///   the first currency that differs.
@inlinable
public func stride(
    from start: Money,
    through end: Money,
    by stride: Money.Stride
) throws(MoneyError) -> MoneyStrideThrough<AnyCurrency> {
    try AnyCurrency.requireMatch(start.storage, end.storage)
    try AnyCurrency.requireMatch(start.storage, stride.amount.storage)

    return MoneyStrideThrough(from: start, through: end, by: stride)
}
