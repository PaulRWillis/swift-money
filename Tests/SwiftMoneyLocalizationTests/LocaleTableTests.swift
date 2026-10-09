import SwiftMoneyLocalization
import Testing

// Resolving a locale identifier to the position its data sits at. What matters here is the resolution
// rules, not the bytes: either separator and either letter case read the same, a region falls back to
// its language, and an identifier no entry covers resolves to nothing rather than to a neighbour.
@Suite("Locale Table Tests")
struct LocaleTableTests {

    // Keys in the order the generator sorts them into, ASCII letters compared as small letters. "en"
    // sits next to "en-GB" so a lookup for either has to stop on the right one.
    static let keys = ["de", "en", "en-GB", "ha", "ha-Latn", "ha-SD", "ja", "sr-Latn", "zh", "zh-Hant", "zh-SG"]

    /// Returns the index of a key in the synthetic table.
    ///
    /// - Parameter key: A key the table holds, spelled as stored.
    /// - Returns: The key's index, or `nil` when the table doesn't hold it.
    static func index(ofKey key: String) -> LocaleIndex? {
        keys.firstIndex(of: key).map(LocaleIndex.init(position:))
    }

    static func makeBlob() -> (bytes: [UInt8], entriesOffset: Int) {
        var builder = BlobTestBuilder()
        let refs = keys.map { builder.pool($0) }

        let entriesOffset = builder.count
        for ref in refs {
            builder.ref(ref)
        }

        return (builder.bytes, entriesOffset)
    }

    static func withTable(_ body: (LocaleTable) -> Void) {
        let (bytes, entriesOffset) = makeBlob()
        bytes.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else {
                Issue.record("a non-empty array has a base address")
                return
            }
            body(LocaleTable(
                reader: BlobReader(base: base, count: buffer.count),
                entriesOffset: entriesOffset,
                localeCount: keys.count
            ))
        }
    }

    @Test("The identifiers are every key in the blob's sorted order")
    func identifiersAreEveryKey() {
        Self.withTable { table in
            #expect(table.identifiers() == Self.keys)
        }
    }

    @Test("Each key resolves to its own position", arguments: Array(keys.enumerated()))
    func keysResolveToTheirPosition(_ entry: (offset: Int, element: String)) {
        Self.withTable { table in
            #expect(table.index(of: LocaleIdentifier(entry.element)) == LocaleIndex(position: entry.offset))
        }
    }

    @Test("An underscore reads as a hyphen")
    func underscoreSeparator() {
        Self.withTable { table in
            #expect(table.index(of: "en_GB") == LocaleIndex(position: 2))
        }
    }

    @Test(
        "Letter case doesn't matter",
        arguments: [("EN_gb", "en-GB"), ("en-gb", "en-GB"), ("SR-LATN", "sr-Latn"), ("ZH", "zh")] as [(LocaleIdentifier, String)]
    )
    func letterCase(_ identifier: LocaleIdentifier, _ key: String) {
        Self.withTable { table in
            #expect(table.index(of: identifier) == Self.index(ofKey: key))
        }
    }

    @Test(
        "A script or region the tables don't cover falls back through the language and script, then the language and region",
        arguments: [
            ("sr-Latn_RS", "sr-Latn"), ("SR-latn-rs", "sr-Latn"), ("zh-Hant-SG", "zh-Hant"), ("en-Latn-GB", "en-GB"),
            ("en-GB-oxendict", "en-GB"), ("ha-Latn-SD", "ha-Latn"),
        ] as [(LocaleIdentifier, String)]
    )
    func scriptThenRegionFallback(_ identifier: LocaleIdentifier, _ key: String) {
        Self.withTable { table in
            #expect(table.index(of: identifier) == Self.index(ofKey: key))
        }
    }

    @Test("A region the tables do not cover falls back to its language", arguments: ["en-US", "en_US", "de-AT", "ja-JP"])
    func regionFallsBackToLanguage(_ identifier: LocaleIdentifier) {
        Self.withTable { table in
            let language = LocaleIdentifier(String(identifier.value.prefix { $0 != "-" && $0 != "_" }))
            #expect(table.index(of: identifier) == table.index(of: language))
            #expect(table.index(of: identifier) != nil)
        }
    }

    @Test("An identifier outside the tables resolves to nothing", arguments: ["zz", "zz-ZZ", "e", "eng", ""])
    func uncoveredIdentifiers(_ identifier: LocaleIdentifier) {
        Self.withTable { table in
            #expect(table.index(of: identifier) == nil)
        }
    }

    // A key that is a prefix of the next one is the case a byte comparison gets wrong by treating the
    // shorter key as equal, which would resolve every English locale to Great Britain.
    @Test("A key that prefixes another resolves to itself")
    func prefixKeyResolvesToItself() {
        Self.withTable { table in
            #expect(table.index(of: "en") == LocaleIndex(position: 1))
            #expect(table.index(of: "en-GB") == LocaleIndex(position: 2))
        }
    }

    // Every shipped key, in both cases, against the real blob: the generator's sort and the search's
    // comparison have to agree on every pair, or some key lands on a neighbour.
    @Test("Every shipped identifier, upper-cased and lower-cased, reaches its own position")
    func shippedIdentifiersInEitherCase() {
        let table = MoneyLocalization.cldr.locales

        for (position, identifier) in table.identifiers().enumerated() {
            for spelling in [identifier.uppercased(), identifier.lowercased()] {
                #expect(
                    table.index(of: LocaleIdentifier(spelling)) == LocaleIndex(position: position),
                    "\(spelling) misses \(identifier)"
                )
            }
        }
    }
}
