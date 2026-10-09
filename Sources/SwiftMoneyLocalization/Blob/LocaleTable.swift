/// The locale section of the packed blob: every covered locale's identifier, one ``StringRef`` each,
/// sorted by their bytes with ASCII letters compared as small letters, so an identifier is found by
/// binary search rather than by a dictionary keyed on strings. An entry's position is the
/// ``LocaleIndex`` every other per-locale section is read with.
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

    /// Returns every covered locale's identifier, in the blob's sorted order.
    ///
    /// These are the identifiers the data ships (`en`, `en-GB`, …), including regions CLDR has no
    /// folder for, such as `zh-TW`.
    ///
    /// ```swift
    /// table.identifiers().contains("zh-TW")  // true
    /// ```
    ///
    /// - Returns: The identifiers, in the order the lookup searches them.
    /// - Complexity: O(*n*), where *n* is the number of locales.
    package func identifiers() -> [String] {
        (0 ..< localeCount).map {
            reader.string(reader.stringRef(at: entriesOffset + $0 * Entry.stride + Entry.key))
        }
    }

    /// Returns the index of the locale an identifier names, or of the nearest locale the data covers.
    ///
    /// Tries the identifier, then its language and script, then its language and region, then its
    /// language. Either `-` or `_` separates subtags, and ASCII letter case is ignored.
    ///
    /// ```swift
    /// table.index(of: "zh_TW")       // the index of zh-TW
    /// table.index(of: "sr-Latn-RS")  // the index of sr-Latn
    /// table.index(of: "EN_gb")       // the index of en-GB
    /// table.index(of: "zz")          // nil
    /// ```
    ///
    /// - Parameter identifier: The locale identifier to look up.
    /// - Returns: The index of the first of those the data covers, or `nil` when none is.
    /// - Complexity: O(*m* + log *n*), where *m* is the length of the language subtag of `identifier`
    ///   and *n* is the number of locales.
    package func index(of identifier: LocaleIdentifier) -> LocaleIndex? {
        var keys = LocaleFallbackChain(identifier).makeIterator()

        // A loop, not `lazy.compactMap(_:).first`: measured in release, the lazy form makes an exact
        // match cost about half as much again.
        while let key = keys.nextKey() {
            if let index = index(of: key) {
                return index
            }
        }

        return nil
    }

    /// Returns the index of the locale stored under a key.
    ///
    /// - Parameter key: The key to look up.
    /// - Returns: The index of the entry whose key matches `key`, or `nil` when none does.
    /// - Complexity: O(log *n*), where *n* is the number of locales.
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

    /// Returns where the stored key at an entry sorts against the key being looked up, comparing their
    /// bytes in place.
    ///
    /// - Parameters:
    ///   - entry: The position of the stored key.
    ///   - key: The key being looked up.
    /// - Returns: Whether the stored key sorts before `key`, equals it, or sorts after it.
    /// - Complexity: O(*k*), where *k* is the length of the stored key.
    @inline(__always)
    private func order(ofKeyAt entry: Int, against key: LocaleKey) -> Order {
        let stored = reader.stringRef(at: entriesOffset + entry * Entry.stride + Entry.key)
        var position = 0

        var bytes = key.bytes.makeIterator()

        while let unfolded = bytes.nextUnfolded() {
            guard position < Int(stored.length) else {
                return .before  // the stored key is a prefix of the one wanted
            }

            // Equal bytes fold equal, so only a mismatch pays for folding both sides; most bytes match
            // as spelled.
            let raw = reader.byte(at: Int(stored.offset) + position)

            if raw != unfolded {
                let byte = LocaleKey.folded(raw)
                let wanted = LocaleKey.folded(unfolded)

                guard byte == wanted else {
                    return byte < wanted ? .before : .after
                }
            }

            position += 1
        }

        return position == Int(stored.length) ? .equal : .after
    }

    /// Where a stored key sorts against the key being looked up.
    private enum Order {
        /// The stored key sorts before the one looked up.
        case before

        /// The keys are equal.
        case equal

        /// The stored key sorts after the one looked up.
        case after
    }
}
