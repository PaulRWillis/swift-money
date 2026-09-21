/// Where one locale's data sits in each per-locale section of the packed tables.
///
/// The sections are indexed by position rather than by a locale's text, and this names that position, so
/// a count or an offset cannot be passed where an index belongs. ``LocaleTable`` resolves an identifier
/// to one, and every other section is read with it.
package struct LocaleIndex: Equatable, Sendable {
    /// Which locale, counting from the first in the tables' own order.
    package let position: Int

    package init(position: Int) {
        self.position = position
    }
}
