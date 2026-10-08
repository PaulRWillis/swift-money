/// Returns the lesser of two runtime amounts.
///
/// ``Money`` isn't `Comparable`, so the standard library's `min(_:_:)` doesn't apply. Inside an
/// extension of ``MoneyOf`` or `Sequence`, call it as `SwiftMoneyCore.min`.
///
/// ```swift
/// let offer = Money(minorUnits: 120_00, currency: .gbp)
/// let limit = Money(minorUnits: 100_00, currency: .gbp)
/// try min(offer, limit)   // £100.00
/// ```
///
/// - Parameters:
///   - x: A value to compare.
///   - y: Another value to compare.
/// - Returns: The lesser of `x` and `y`. If they are equal, returns `x`.
/// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `y` is in a different currency from `x`,
///   with `x`'s currency as `lhs`.
@inlinable
public func min(_ x: Money, _ y: Money) throws(MoneyError) -> Money {
    try AnyCurrency.requireMatch(x.storage, y.storage)

    return y.minorUnits < x.minorUnits ? y : x
}

/// Returns the greater of two runtime amounts.
///
/// ``Money`` isn't `Comparable`, so the standard library's `max(_:_:)` doesn't apply. Inside an
/// extension of ``MoneyOf`` or `Sequence`, call it as `SwiftMoneyCore.max`.
///
/// ```swift
/// let offer = Money(minorUnits: 120_00, currency: .gbp)
/// let limit = Money(minorUnits: 100_00, currency: .gbp)
/// try max(offer, limit)   // £120.00
/// ```
///
/// - Parameters:
///   - x: A value to compare.
///   - y: Another value to compare.
/// - Returns: The greater of `x` and `y`. If they are equal, returns `y`.
/// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `y` is in a different currency from `x`,
///   with `x`'s currency as `lhs`.
@inlinable
public func max(_ x: Money, _ y: Money) throws(MoneyError) -> Money {
    try AnyCurrency.requireMatch(x.storage, y.storage)

    return y.minorUnits >= x.minorUnits ? y : x
}
