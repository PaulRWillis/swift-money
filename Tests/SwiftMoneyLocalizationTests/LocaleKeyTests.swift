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

    @Test("A key's bytes are the identifier's, each folded")
    func bytesAreFolded() {
        #expect(Array(LocaleKey("en_gb").bytes) == Array("en-gb".utf8))
    }
}
