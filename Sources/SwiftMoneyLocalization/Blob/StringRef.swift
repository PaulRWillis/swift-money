/// A pooled string, as a byte offset and length. A typed wrapper so pool offsets never travel as a
/// bare pair of integers.
@usableFromInline
package struct StringRef: Equatable, Hashable, Sendable {
    @usableFromInline let offset: UInt32
    @usableFromInline let length: UInt32

    @usableFromInline
    package init(offset: UInt32, length: UInt32) {
        self.offset = offset
        self.length = length
    }

    /// The empty string, resolved without reading the pool.
    @usableFromInline
    package static let empty = StringRef(offset: 0, length: 0)
}
