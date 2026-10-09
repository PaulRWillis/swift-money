/// The locale section of the packed blob: every covered locale's identifier, one ``StringRef`` each,
/// sorted by their UTF-8 bytes so an identifier is found by binary search rather than by a dictionary
/// keyed on strings. An entry's position is the ``LocaleIndex`` every other per-locale section is read
/// with.
package struct LocaleTable: Sendable {
    let reader: BlobReader
    let entriesOffset: Int

    /// How many locales the tables cover, which bounds every per-locale section.
    package let localeCount: Int

    private enum Entry {
        static let key = 0
        static let stride = key + BlobDigits.stringRef
    }

    package init(reader: BlobReader, entriesOffset: Int, localeCount: Int) {
        self.reader = reader
        self.entriesOffset = entriesOffset
        self.localeCount = localeCount
    }

    /// Every covered locale's identifier, in the blob's sorted order. The identifiers are the ones the
    /// data ships (`en`, `en-GB`, …), not region variants that inherit from them.
    package func identifiers() -> [String] {
        (0 ..< localeCount).map {
            reader.string(reader.stringRef(at: entriesOffset + $0 * Entry.stride + Entry.key))
        }
    }

    /// The index of the locale `identifier` names, or of the language it belongs to when its region is
    /// not covered on its own, as CLDR inheritance resolves it (`de_DE` to `de`).
    ///
    /// - Returns: `nil` when neither the identifier nor its language is covered.
    package func index(of identifier: LocaleIdentifier) -> LocaleIndex? {
        var keys = LocaleFallbackChain(identifier).makeIterator()

        // The chain yields the identifier first and, when anything follows it, the language last.
        return keys.next().flatMap(index(of:))
            ?? IteratorSequence(keys).reduce(nil) { _, key in Optional(key) }.flatMap(index(of:))
    }

    // Binary search over the keys, in the byte order the generator sorted them into. Forced inline:
    // left to the optimizer, every lookup calls out to this search and to each probe.
    @inline(__always)
    private func index(of key: LocaleKey) -> LocaleIndex? {
        var low = 0
        var high = localeCount

        while low < high {
            let middle = (low + high) / 2
            switch order(ofKeyAt: middle, against: key) {
            case .equal: return LocaleIndex(position: middle)
            case .before: low = middle + 1
            case .after: high = middle
            }
        }

        return nil
    }

    // Where the stored key at `entry` sorts against the key being looked up. Compared byte by byte out
    // of the pool, so neither side is copied into a string to compare it.
    @inline(__always)
    private func order(ofKeyAt entry: Int, against key: LocaleKey) -> Order {
        let stored = reader.stringRef(at: entriesOffset + entry * Entry.stride + Entry.key)
        var position = 0

        for wanted in key.bytes {
            guard position < Int(stored.length) else {
                return .before  // the stored key is a prefix of the one wanted
            }

            let byte = reader.byte(at: Int(stored.offset) + position)
            guard byte == wanted else {
                return byte < wanted ? .before : .after
            }

            position += 1
        }

        return position == Int(stored.length) ? .equal : .after
    }

    // Where a stored key sorts against the key being looked up.
    private enum Order {
        case before
        case equal
        case after
    }
}
