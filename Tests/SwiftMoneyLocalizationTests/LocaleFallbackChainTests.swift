import SwiftMoneyLocalization
import Testing

// The keys a locale identifier is looked up by, in the order CLDR falls back through them. Each
// expected key is compared through `LocaleKey`'s bytes, so the comparison reads both sides the same
// way whatever the fold maps.
@Suite("Locale Fallback Chain Tests")
struct LocaleFallbackChainTests {

    /// Returns the bytes of each key a chain yields, in order.
    ///
    /// - Parameter identifier: The identifier to build the chain from.
    /// - Returns: Each key's bytes, in the order the chain yields them.
    private static func keys(of identifier: LocaleIdentifier) -> [[UInt8]] {
        IteratorSequence(LocaleFallbackChain(identifier).makeIterator()).map(bytes(of:))
    }

    /// Returns a key's bytes.
    ///
    /// - Parameter key: The key to read.
    /// - Returns: The key's bytes, folded.
    private static func bytes(of key: LocaleKey) -> [UInt8] {
        Array(IteratorSequence(key.bytes.makeIterator()))
    }

    /// Returns the bytes of each identifier read as a whole key.
    ///
    /// - Parameter identifiers: The identifiers to read.
    /// - Returns: Each identifier's key bytes, in order.
    private static func keys(_ identifiers: [String]) -> [[UInt8]] {
        identifiers.map { bytes(of: LocaleKey(LocaleIdentifier($0))) }
    }

    @Test(
        "An identifier yields itself, then its language and script, language and region, and language",
        arguments: [
            ("zh-Hant_TW", ["zh-Hant_TW", "zh-Hant", "zh-TW", "zh"]),
            ("sr-Latn-rs", ["sr-Latn-rs", "sr-Latn", "sr-rs", "sr"]),
            ("en_US", ["en_US", "en"]),
            ("en_US_POSIX", ["en_US_POSIX", "en-US", "en"]),
            ("en", ["en"]),
            ("ca-ES-valencia", ["ca-ES-valencia", "ca-ES", "ca"]),
        ] as [(LocaleIdentifier, [String])]
    )
    func chain(_ identifier: LocaleIdentifier, _ expected: [String]) {
        #expect(Self.keys(of: identifier) == Self.keys(expected))
    }

    // A subtag is a script only second, and a region only second or third after a script, so an
    // extension's `nu`, a codeset's `TW.UTF` and a region after a non-script never count.
    @Test(
        "A subtag out of position or shape is neither script nor region",
        arguments: [
            ("de-u-nu-latn", ["de-u-nu-latn", "de"]),
            ("zh_TW.UTF-8", ["zh_TW.UTF-8", "zh"]),
            ("xx-Ääää-ZZ", ["xx-Ääää-ZZ", "xx"]),
        ] as [(LocaleIdentifier, [String])]
    )
    func unclassifiedSubtags(_ identifier: LocaleIdentifier, _ expected: [String]) {
        #expect(Self.keys(of: identifier) == Self.keys(expected))
    }

    @Test(
        "A leading, doubled or trailing separator leaves an empty subtag with no shape",
        arguments: [
            ("en-", ["en-", "en"]),
            ("en--US", ["en--US", "en"]),
            ("en-Latn--US", ["en-Latn--US", "en-Latn", "en"]),
            ("-en", ["-en", ""]),
        ] as [(LocaleIdentifier, [String])]
    )
    func emptySubtags(_ identifier: LocaleIdentifier, _ expected: [String]) {
        #expect(Self.keys(of: identifier) == Self.keys(expected))
    }

    @Test(
        "A subtag longer than a script or a region is neither, however long",
        arguments: [
            ("en-Latnx-US", ["en-Latnx-US", "en"]),
            ("en-Latn-USA", ["en-Latn-USA", "en-Latn", "en"]),
            ("en-" + String(repeating: "B", count: 1_000), ["en-" + String(repeating: "B", count: 1_000), "en"]),
            (
                "en-Latn-" + String(repeating: "U", count: 1_000),
                ["en-Latn-" + String(repeating: "U", count: 1_000), "en-Latn", "en"]
            ),
            (
                "en-Latn-US-" + String(repeating: "x", count: 1_000),
                ["en-Latn-US-" + String(repeating: "x", count: 1_000), "en-Latn", "en-US", "en"]
            ),
        ] as [(String, [String])]
    )
    func longSubtags(_ identifier: String, _ expected: [String]) {
        #expect(Self.keys(of: LocaleIdentifier(identifier)) == Self.keys(expected))
    }

    // BCP 47's longest language subtag is 8 letters, and no stored key's language is longer, so a
    // longer language leaves nothing after the identifier that could match.
    @Test(
        "A language longer than 8 bytes yields the identifier alone",
        arguments: [
            ("abcdefgh-US", ["abcdefgh-US", "abcdefgh"]),
            ("abcdefghi-US", ["abcdefghi-US"]),
            ("abcdefghi_Latn_US", ["abcdefghi_Latn_US"]),
            ("abcdefghi-", ["abcdefghi-"]),
            (String(repeating: "b", count: 1_000) + "-US", [String(repeating: "b", count: 1_000) + "-US"]),
        ] as [(String, [String])]
    )
    func longLanguages(_ identifier: String, _ expected: [String]) {
        #expect(Self.keys(of: LocaleIdentifier(identifier)) == Self.keys(expected))
    }

    @Test("An empty identifier yields itself alone")
    func emptyIdentifier() {
        #expect(Self.keys(of: "") == [[]])
    }
}
