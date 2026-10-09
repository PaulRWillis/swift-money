extension LocaleInheritance {
    /// Why CLDR's folders and parent locales don't make a lookup that always ends.
    package enum InheritanceError: Error, Equatable, Sendable {
        /// No `und` folder, so there is no root for a lookup to end at.
        case noRoot

        /// A lookup from a parent locale key comes back to a name it already passed, with that name.
        case cycle(through: String)
    }
}
