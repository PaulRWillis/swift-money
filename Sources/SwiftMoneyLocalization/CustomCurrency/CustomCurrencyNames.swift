/// How a custom currency names itself in full in one locale, per plural category, with any override of
/// the gap between the amount and the name.
///
/// Built once and returned from ``CustomCurrencyFormattable/names(for:)``. Only the `other` name is
/// required, because every locale that names a currency at all has one, and it stands in for any
/// category with no name of its own. The caller chooses the width of the set: a long name ("points") or
/// a short one ("pts") is just a different value passed here.
///
/// ```swift
/// CustomCurrencyNames(other: "points", byCategory: [.one: "point"])   // "1.00 points", "0.01 point"
/// CustomCurrencyNames(other: "pts", spacing: .fixed(.none))           // "500.00pts"
/// ```
public struct CustomCurrencyNames: Equatable, Hashable, Sendable {
    package let other: CurrencyName
    package let byCategory: [PluralCategory: CurrencyName]
    package let spacing: CurrencySpacing

    /// Creates the full names of a custom currency.
    ///
    /// - Parameters:
    ///   - other: The name for the `other` category, which stands in for any category with no name of
    ///     its own.
    ///   - byCategory: The names for the categories that have a distinct one.
    ///   - spacing: The gap between the amount and the name. Follows the locale by default.
    public init(
        other: CurrencyName,
        byCategory: [PluralCategory: CurrencyName] = [:],
        spacing: CurrencySpacing = .automatic
    ) {
        self.other = other
        self.byCategory = byCategory
        self.spacing = spacing
    }

    // The name for an amount in a plural category, falling back to `other`.
    package func name(for category: PluralCategory) -> CurrencyName {
        byCategory[category] ?? other
    }
}
