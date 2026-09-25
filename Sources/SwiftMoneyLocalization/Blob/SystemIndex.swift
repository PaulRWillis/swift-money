/// Where one numbering system's data sits in the numbering-system section of the packed tables.
///
/// The section is indexed by position rather than by a system's name, and this names that position, so a
/// count, a locale index or a bare integer cannot be passed where a system index belongs.
/// ``NumberingSystemTable`` resolves a name to one.
package struct SystemIndex: Equatable, Hashable, Sendable {
    /// Which system, counting from the first in the section's own (name-sorted) order.
    package let position: Int

    package init(position: Int) {
        self.position = position
    }
}
