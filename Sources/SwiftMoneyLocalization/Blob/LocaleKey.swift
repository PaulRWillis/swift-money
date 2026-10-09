/// The bytes a locale identifier, or part of one, is looked up by.
///
/// ```swift
/// var bytes = LocaleKey("EN_gb").bytes.makeIterator()
/// bytes.next()  // UInt8(ascii: "e")
/// ```
package struct LocaleKey: Sendable {
    /// The identifier's UTF-8.
    private let utf8: String.UTF8View

    /// Which of the identifier's bytes the key reads.
    private let extent: Extent

    /// Creates the key for a whole identifier.
    ///
    /// ```swift
    /// LocaleKey("de_DE")  // de-DE
    /// ```
    ///
    /// - Parameter identifier: The identifier to look up.
    package init(_ identifier: LocaleIdentifier) {
        utf8 = identifier.value.utf8
        extent = .prefix(length: utf8.count)
    }

    /// Creates the key for an identifier's first bytes.
    ///
    /// - Parameters:
    ///   - utf8: The identifier's UTF-8.
    ///   - length: How many of its bytes the key reads.
    init(_ utf8: String.UTF8View, prefixLength length: Int) {
        self.utf8 = utf8
        extent = .prefix(length: length)
    }

    /// Creates the key for an identifier's language and region, leaving out what lies between them.
    ///
    /// - Parameters:
    ///   - utf8: The identifier's UTF-8.
    ///   - language: The length of the language subtag, which starts the identifier.
    ///   - region: The byte offsets of the region subtag.
    /// - Precondition: `region.lowerBound` must not be less than `language`.
    init(_ utf8: String.UTF8View, language: Int, region: Range<Int>) {
        self.utf8 = utf8
        extent = .languageAndRegion(language: language, region: region)
    }

    /// The key's bytes, each read through ``folded(_:)``.
    package var bytes: Bytes {
        Bytes(utf8: utf8, extent: extent)
    }

    /// Returns a byte as the lookup compares it: `_` as `-`, `A` to `Z` as `a` to `z`, and every other
    /// byte unchanged.
    ///
    /// This alone defines the order keys are sorted and searched in.
    ///
    /// ```swift
    /// LocaleKey.folded(UInt8(ascii: "_"))  // UInt8(ascii: "-")
    /// LocaleKey.folded(UInt8(ascii: "G"))  // UInt8(ascii: "g")
    /// LocaleKey.folded(UInt8(ascii: "a"))  // UInt8(ascii: "a")
    /// ```
    ///
    /// - Parameter byte: A byte of an identifier.
    /// - Returns: The byte the lookup compares in its place.
    // Forced inline: left to the optimizer, a binary search calls out twice for every probe.
    @inline(__always)
    package static func folded(_ byte: UInt8) -> UInt8 {
        // One unsigned compare tests the whole capital range: bytes below `A` wrap past 25.
        if byte &- UInt8(ascii: "A") < letterCount {
            return byte | asciiCaseBit
        }

        return byte == UInt8(ascii: "_") ? separator : byte
    }

    /// The separator a key's bytes use between subtags.
    static var separator: UInt8 { UInt8(ascii: "-") }

    /// How many letters the ASCII alphabet has.
    private static var letterCount: UInt8 { 26 }

    /// The bit that tells an ASCII capital letter from its small letter.
    private static var asciiCaseBit: UInt8 { 0x20 }
}

extension LocaleKey {
    /// Which of an identifier's bytes a key reads.
    fileprivate enum Extent: Sendable {
        /// The identifier's first bytes.
        case prefix(length: Int)

        /// The language subtag, a separator, then the region subtag.
        case languageAndRegion(language: Int, region: Range<Int>)
    }

    /// A key's bytes, each read through ``LocaleKey/folded(_:)``.
    package struct Bytes: Sendable {
        /// The identifier's UTF-8.
        fileprivate let utf8: String.UTF8View

        /// Which of the identifier's bytes to read.
        fileprivate let extent: Extent

        /// Returns an iterator over the key's bytes.
        ///
        /// - Returns: An iterator that starts at the key's first byte.
        // Forced inline: left to the optimizer, a binary search calls out for every probe.
        @inline(__always)
        package func makeIterator() -> Iterator {
            switch extent {
            case .prefix(let length):
                Iterator(utf8: utf8, length: length, region: nil)
            case .languageAndRegion(let language, let region):
                Iterator(
                    utf8: utf8,
                    length: language,
                    region: (skip: region.lowerBound - language, length: region.count)
                )
            }
        }
    }

    /// An iterator over a key's bytes.
    package struct Iterator: IteratorProtocol {
        /// The identifier's bytes, from the next one to read.
        private var utf8: String.UTF8View.Iterator

        /// How many bytes of the current run are still to read.
        private var remaining: Int

        /// The region still to read after a separator: how many bytes to skip to reach it, and its
        /// length. `nil` when nothing follows the current run.
        private var region: (skip: Int, length: Int)?

        /// Creates an iterator over an identifier's first bytes and an optional region after them.
        ///
        /// - Parameters:
        ///   - utf8: The identifier's UTF-8.
        ///   - length: How many of its first bytes to read.
        ///   - region: How many bytes to skip after those to reach the region, and its length.
        fileprivate init(utf8: String.UTF8View, length: Int, region: (skip: Int, length: Int)?) {
            self.utf8 = utf8.makeIterator()
            remaining = length
            self.region = region
        }

        /// Returns the key's next byte.
        ///
        /// - Returns: The next byte, folded, or `nil` after the last.
        package mutating func next() -> UInt8? {
            nextUnfolded().map(LocaleKey.folded)
        }

        /// Returns the key's next byte as the identifier spells it, with `-` before the region of a
        /// language-and-region key.
        ///
        /// - Returns: The next byte, not folded, or `nil` after the last.
        // Forced inline: left to the optimizer, a binary search calls out for every byte it compares.
        @inline(__always)
        mutating func nextUnfolded() -> UInt8? {
            if remaining > 0 {
                remaining -= 1
                return utf8.next()
            }

            guard let region else {
                return nil
            }

            self.region = nil
            for _ in 0 ..< region.skip {
                _ = utf8.next()
            }
            remaining = region.length

            return LocaleKey.separator
        }
    }
}
