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

/// Returns the least of three or more runtime amounts.
///
/// Every amount's currency is checked, including those that aren't the least.
///
/// ```swift
/// let postage = Money(minorUnits: 3_20, currency: .gbp)
/// let courier = Money(minorUnits: 6_50, currency: .gbp)
/// let collection = Money(minorUnits: 0, currency: .gbp)
/// try min(postage, courier, collection)   // £0.00
/// ```
///
/// - Parameters:
///   - x: A value to compare.
///   - y: Another value to compare.
///   - z: A third value to compare.
///   - rest: Zero or more additional values.
/// - Returns: The least of all the arguments. If there are several equal least values, returns the
///   first.
/// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the amounts are not all in the same
///   currency. `lhs` is `x`'s currency, and `rhs` is the currency of the first argument that differs
///   from it.
/// - Complexity: O(*n*), where *n* is the number of arguments.
@inlinable
public func min(_ x: Money, _ y: Money, _ z: Money, _ rest: Money...) throws(MoneyError) -> Money {
    var least = try min(min(x, y), z)
    for amount in rest {
        least = try min(least, amount)
    }
    return least
}

/// Returns the greatest of three or more runtime amounts.
///
/// Every amount's currency is checked, including those that aren't the greatest.
///
/// ```swift
/// let first = Money(minorUnits: 10_00, currency: .gbp)
/// let second = Money(minorUnits: 12_50, currency: .gbp)
/// let third = Money(minorUnits: 11_00, currency: .gbp)
/// try max(first, second, third)   // £12.50
/// ```
///
/// - Parameters:
///   - x: A value to compare.
///   - y: Another value to compare.
///   - z: A third value to compare.
///   - rest: Zero or more additional values.
/// - Returns: The greatest of all the arguments. If there are several equal greatest values, returns
///   the last.
/// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the amounts are not all in the same
///   currency. `lhs` is `x`'s currency, and `rhs` is the currency of the first argument that differs
///   from it.
/// - Complexity: O(*n*), where *n* is the number of arguments.
@inlinable
public func max(_ x: Money, _ y: Money, _ z: Money, _ rest: Money...) throws(MoneyError) -> Money {
    var greatest = try max(max(x, y), z)
    for amount in rest {
        greatest = try max(greatest, amount)
    }
    return greatest
}
