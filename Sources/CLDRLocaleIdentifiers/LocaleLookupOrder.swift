import SwiftMoneyLocalization

/// The order the runtime's binary search expects locale names in: by their bytes as ``LocaleKey``
/// reads them.
///
/// ```swift
/// ["en-SI", "en-Shaw"].sorted(by: LocaleLookupOrder.precedes)  // ["en-Shaw", "en-SI"]
/// ```
package enum LocaleLookupOrder {
    /// Returns whether one name sorts strictly before another in the order the runtime searches them.
    ///
    /// ```swift
    /// LocaleLookupOrder.precedes("en-Shaw", "en-SI")  // true
    /// LocaleLookupOrder.precedes("en-gb", "en-GB")    // false
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: A name to compare.
    ///   - rhs: Another name to compare.
    /// - Returns: `true` if `lhs` sorts strictly before `rhs`; otherwise, `false`.
    /// - Complexity: O(*m*), where *m* is the length of the shorter name.
    package static func precedes(_ lhs: String, _ rhs: String) -> Bool {
        LocaleKey(LocaleIdentifier(lhs)).bytes.lexicographicallyPrecedes(LocaleKey(LocaleIdentifier(rhs)).bytes)
    }

    /// Returns the first two neighboring names that aren't strictly in the order the runtime searches
    /// them, so a repeated name or two names the runtime can't tell apart are caught.
    ///
    /// ```swift
    /// LocaleLookupOrder.firstPairOutOfOrder(in: ["en", "en-GB"])     // nil
    /// LocaleLookupOrder.firstPairOutOfOrder(in: ["en-gb", "en-GB"])  // ("en-gb", "en-GB")
    /// ```
    ///
    /// - Parameter names: The locale names, meant to be in strictly increasing order.
    /// - Returns: The first neighboring pair whose earlier name doesn't sort strictly before its later
    ///   one, or `nil` when every pair does.
    /// - Complexity: O(*n*) comparisons, where *n* is the number of names.
    package static func firstPairOutOfOrder(in names: [String]) -> (earlier: String, later: String)? {
        zip(names, names.dropFirst())
            .first { !precedes($0, $1) }
            .map { (earlier: $0, later: $1) }
    }
}
