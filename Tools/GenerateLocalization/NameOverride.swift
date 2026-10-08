import SwiftMoneyLocalization

/// A currency's name for one plural category, where it differs from the name CLDR always publishes.
struct NameOverride: Equatable, Hashable, Sendable {
    /// The plural category the name is for.
    let category: PluralCategory

    /// The currency's name in that category.
    let name: String
}
