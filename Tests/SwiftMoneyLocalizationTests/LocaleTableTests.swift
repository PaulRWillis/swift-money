import SwiftMoneyLocalization
import Testing

// Resolving a locale identifier to the position its data sits at. What matters here is the resolution
// rules, not the bytes: either separator reads the same, a region falls back to its language, and an
// identifier no entry covers resolves to nothing rather than to a neighbour.
@Suite("Locale Table Tests")
struct LocaleTableTests {

    // Keys in the byte order the generator sorts them into. "en" sits next to "en-GB" so a lookup for
    // either has to stop on the right one.
    static let keys = ["de", "en", "en-GB", "ja"]

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
}
