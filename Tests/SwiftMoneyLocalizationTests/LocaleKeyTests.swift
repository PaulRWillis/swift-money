import SwiftMoneyLocalization
import Testing

@Suite("Locale Key Tests")
struct LocaleKeyTests {

    @Test("An underscore folds to a hyphen")
    func underscoreFoldsToHyphen() {
        #expect(LocaleKey.folded(UInt8(ascii: "_")) == UInt8(ascii: "-"))
    }

    @Test(
        "A hyphen, a digit, a small letter and a non-ASCII byte are unchanged",
        arguments: [UInt8(ascii: "-"), UInt8(ascii: "0"), UInt8(ascii: "a"), 0xC3]
    )
    func unchangedBytes(_ byte: UInt8) {
        #expect(LocaleKey.folded(byte) == byte)
    }

    @Test("A capital ASCII letter folds to its small letter")
    func capitalFoldsToSmall() {
        #expect(LocaleKey.folded(UInt8(ascii: "A")) == UInt8(ascii: "a"))
        #expect(LocaleKey.folded(UInt8(ascii: "Z")) == UInt8(ascii: "z"))
    }

    // The bytes either side of `A` to `Z` and `a` to `z`, where an off-by-one range would fold them.
    @Test(
        "A byte just outside the capital letters is unchanged",
        arguments: [UInt8(ascii: "@"), UInt8(ascii: "["), UInt8(ascii: "`"), UInt8(ascii: "{"), UInt8(ascii: "9")]
    )
    func neighboursOfTheLettersAreUnchanged(_ byte: UInt8) {
        #expect(LocaleKey.folded(byte) == byte)
    }

    @Test("Keys differing only in letter case and separator have the same bytes")
    func caseAndSeparatorDoNotMatter() {
        #expect(Array(LocaleKey("ZH_Hant").bytes) == Array(LocaleKey("zh-hant").bytes))
    }

    @Test("A key's bytes are the identifier's, each folded")
    func bytesAreFolded() {
        #expect(Array(LocaleKey("en_gb").bytes) == Array("en-gb".utf8))
    }
}
