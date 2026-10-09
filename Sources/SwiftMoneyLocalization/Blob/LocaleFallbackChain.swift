/// The keys a locale identifier is looked up by, in the order CLDR falls back through them.
///
/// The identifier comes first, then its language and script, then its language and region, then its
/// language. Each of the last three comes only when the identifier has more after that part, so no
/// key repeats. A script counts only as the second subtag, and a region only as the second, or third
/// after a script; nothing later is classified, so `de-u-nu-latn` has no region `nu`.
///
/// ```swift
/// LocaleFallbackChain("zh-Hant_TW")   // zh-Hant-TW, zh-Hant, zh-TW, zh
/// LocaleFallbackChain("en_US")        // en-US, en
/// LocaleFallbackChain("en_US_POSIX")  // en-US-POSIX, en-US, en
/// ```
package struct LocaleFallbackChain: Sendable {
    /// The identifier's UTF-8.
    private let utf8: String.UTF8View

    /// Creates the chain for an identifier.
    ///
    /// ```swift
    /// LocaleFallbackChain("sr-Latn-RS")  // sr-Latn-RS, sr-Latn, sr-RS, sr
    /// ```
    ///
    /// - Parameter identifier: The identifier to look up, with `-` or `_` between subtags.
    package init(_ identifier: LocaleIdentifier) {
        utf8 = identifier.value.utf8
    }

    /// Returns an iterator over the chain's keys.
    ///
    /// The identifier's subtags are read once, and only when a key after the first is asked for.
    ///
    /// - Returns: An iterator that starts at the identifier itself.
    package func makeIterator() -> Iterator {
        Iterator(utf8: utf8)
    }
}

extension LocaleFallbackChain {
    /// An iterator over a chain's keys.
    package struct Iterator: IteratorProtocol {
        /// The identifier's UTF-8.
        private let utf8: String.UTF8View

        /// Where the identifier's subtags lie, once a key after the first has needed them.
        private var parsedSubtags: Subtags?

        /// The step to try next, or `nil` once every step is tried.
        private var step: Step? = .requested

        /// Creates an iterator at a chain's first step.
        ///
        /// - Parameter utf8: The identifier's UTF-8.
        fileprivate init(utf8: String.UTF8View) {
            self.utf8 = utf8
        }

        /// Returns the chain's next key.
        ///
        /// - Returns: The next key, or `nil` after the last.
        /// - Complexity: O(*m*) for the second key, where *m* is the length of the identifier; O(1)
        ///   for the others.
        package mutating func next() -> LocaleKey? {
            nextKey()
        }

        /// Returns the chain's next key.
        ///
        /// - Returns: The next key, or `nil` after the last.
        /// - Complexity: O(*m*) for the second key, where *m* is the length of the identifier; O(1)
        ///   for the others.
        // Forced inline: left to the optimizer, every lookup calls out once per key.
        @inline(__always)
        mutating func nextKey() -> LocaleKey? {
            while let current = step {
                step = current.next

                if let key = key(at: current) {
                    return key
                }
            }

            return nil
        }

        /// Returns the key one step of the chain looks up, or `nil` when the identifier skips that
        /// step.
        ///
        /// - Parameter step: The step to build the key for.
        /// - Returns: The step's key, or `nil` when the identifier has nothing after the part the step
        ///   keeps, or lacks that part.
        @inline(__always)
        private mutating func key(at step: Step) -> LocaleKey? {
            switch step {
            case .requested: LocaleKey(utf8, prefixLength: utf8.count)
            case .languageAndScript: subtags().languageAndScriptKey(in: utf8)
            case .languageAndRegion: subtags().languageAndRegionKey(in: utf8)
            case .language: subtags().languageKey(in: utf8)
            }
        }

        /// Returns where the identifier's subtags lie, reading them the first time only.
        ///
        /// - Returns: The identifier's subtags.
        /// - Complexity: O(*m*) the first time, where *m* is the length of the identifier; O(1) after.
        // Out of line: the parse runs at most once per lookup, and inlined it is copied into each step.
        @inline(never)
        private mutating func subtags() -> Subtags {
            if let parsedSubtags {
                return parsedSubtags
            }

            let subtags = Subtags(utf8)
            parsedSubtags = subtags
            return subtags
        }
    }

    /// One step of the chain, in the order CLDR falls back through them.
    private enum Step {
        /// The identifier as given.
        case requested

        /// The language and script.
        case languageAndScript

        /// The language and region, leaving out any script between them.
        case languageAndRegion

        /// The language alone.
        case language

        /// The step after this one, or `nil` after the last.
        var next: Step? {
            switch self {
            case .requested: .languageAndScript
            case .languageAndScript: .languageAndRegion
            case .languageAndRegion: .language
            case .language: nil
            }
        }
    }

    /// Where an identifier's language, script and region lie, as byte offsets.
    private struct Subtags: Sendable {
        /// The identifier's length in bytes.
        private let length: Int

        /// The length of the language subtag, which starts the identifier.
        private let language: Int

        /// Where the script lies, when the second subtag has a script's shape.
        private let script: Range<Int>?

        /// Where the region lies, when the second subtag, or the third after a script, has a region's
        /// shape.
        private let region: Range<Int>?

        /// Reads where an identifier's subtags lie, in one pass over at most its first three subtags.
        ///
        /// - Parameter utf8: The identifier's UTF-8.
        /// - Complexity: O(*m*), where *m* is the length of the identifier.
        init(_ utf8: String.UTF8View) {
            var bytes = utf8.makeIterator()
            let length = utf8.count
            let language = Self.subtag(&bytes, from: 0).range.upperBound

            self.length = length
            self.language = language

            guard language < length else {
                script = nil
                region = nil
                return
            }

            let second = Self.subtag(&bytes, from: language + 1)

            switch second.shape {
            case .script where second.range.upperBound < length:
                let third = Self.subtag(&bytes, from: second.range.upperBound + 1)
                script = second.range
                region = third.shape == .region ? third.range : nil
            case .script:
                script = second.range
                region = nil
            case .region:
                script = nil
                region = second.range
            case nil:
                script = nil
                region = nil
            }
        }

        /// Returns the key for the language and script, or `nil` when there is no script or nothing
        /// after it.
        ///
        /// - Parameter utf8: The identifier's UTF-8.
        /// - Returns: The key for the identifier up to the end of its script.
        func languageAndScriptKey(in utf8: String.UTF8View) -> LocaleKey? {
            guard let script, script.upperBound < length else {
                return nil
            }
            return LocaleKey(utf8, prefixLength: script.upperBound)
        }

        /// Returns the key for the language and region, or `nil` when there is no region, or neither a
        /// script before it nor anything after it.
        ///
        /// - Parameter utf8: The identifier's UTF-8.
        /// - Returns: The key for the language, a separator, then the region.
        func languageAndRegionKey(in utf8: String.UTF8View) -> LocaleKey? {
            guard let region, script != nil || region.upperBound < length else {
                return nil
            }
            return LocaleKey(utf8, language: language, region: region)
        }

        /// Returns the key for the language, or `nil` when nothing follows it.
        ///
        /// - Parameter utf8: The identifier's UTF-8.
        /// - Returns: The key for the language subtag alone.
        func languageKey(in utf8: String.UTF8View) -> LocaleKey? {
            guard language < length else {
                return nil
            }
            return LocaleKey(utf8, prefixLength: language)
        }

        /// Reads one subtag and the separator after it.
        ///
        /// - Parameters:
        ///   - bytes: The identifier's bytes, from the subtag's first.
        ///   - start: The offset of the subtag's first byte.
        /// - Returns: The subtag's byte offsets, and its shape.
        private static func subtag(
            _ bytes: inout String.UTF8View.Iterator,
            from start: Int
        ) -> (range: Range<Int>, shape: LocaleSubtagShape?) {
            var tally = LocaleSubtagShape.Tally.empty
            var length = 0

            while let byte = bytes.next(), LocaleKey.folded(byte) != LocaleKey.separator {
                tally.count(byte)
                length += 1
            }

            return (start ..< start + length, tally.shape)
        }
    }
}
