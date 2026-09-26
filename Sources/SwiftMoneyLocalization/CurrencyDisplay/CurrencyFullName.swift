/// What one locale calls a currency, by plural category, as in "British pound" and "British pounds".
package struct CurrencyFullName: Equatable, Sendable {
    private let other: String
    private let byCategory: [PluralCategory: String]

    /// Creates the names of a currency.
    ///
    /// - Parameters:
    ///   - other: The name for the `other` category, which every locale that names a currency at all
    ///     publishes, and which stands in for any category with no name of its own.
    ///   - byCategory: The names for the categories that have one.
    package init(other: String, byCategory: [PluralCategory: String] = [:]) {
        self.other = other
        self.byCategory = byCategory
    }

    /// The name to use for an amount in a plural category.
    package func name(for category: PluralCategory) -> String {
        byCategory[category] ?? other
    }
}
