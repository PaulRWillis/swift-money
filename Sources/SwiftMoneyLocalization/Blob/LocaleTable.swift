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

    /// The index of the locale `identifier` names, or of the language it belongs to when its region is
    /// not covered on its own, as CLDR inheritance resolves it (`de_DE` to `de`).
    ///
    /// - Returns: `nil` when neither the identifier nor its language is covered.
    package func index(of identifier: LocaleIdentifier) -> LocaleIndex? {
        let key = Key(identifier)

        return index(of: key) ?? key.language.flatMap(index(of:))
    }

    // Binary search over the keys, in the byte order the generator sorted them into.
    private func index(of key: Key) -> LocaleIndex? {
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
    private func order(ofKeyAt entry: Int, against key: Key) -> Order {
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

    // The bytes a locale is looked up by: the identifier's UTF-8 with `_` read as `-`, since either
    // separates a language from its region. A view over the identifier rather than a normalized copy of
    // it, so a lookup allocates nothing.
    private struct Key {
        private let utf8: String.UTF8View
        private let length: Int

        init(_ identifier: LocaleIdentifier) {
            self.init(utf8: identifier.value.utf8, length: identifier.value.utf8.count)
        }

        private init(utf8: String.UTF8View, length: Int) {
            self.utf8 = utf8
            self.length = length
        }

        // The key for the language alone, or `nil` when this key is the language already, so a lookup
        // never searches twice for the same bytes.
        var language: Key? {
            let languageLength = utf8.prefix(length).prefix { !Self.isSeparator($0) }.count

            guard languageLength < length else {
                return nil
            }

            return Key(utf8: utf8, length: languageLength)
        }

        var bytes: some Sequence<UInt8> {
            utf8.prefix(length).lazy.map { Self.isSeparator($0) ? UInt8(ascii: "-") : $0 }
        }

        private static func isSeparator(_ byte: UInt8) -> Bool {
            byte == UInt8(ascii: "-") || byte == UInt8(ascii: "_")
        }
    }
}
