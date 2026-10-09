import CLDRLocaleIdentifiers
import SwiftMoneyLocalization
import Testing

@Suite("FoldedLocaleName")
struct FoldedLocaleNameTests {

    @Test("Spellings differing only in letter case and separator are one name")
    func caseAndSeparatorFold() {
        #expect(FoldedLocaleName("zh-Hant") == FoldedLocaleName("ZH_hant"))
        #expect(FoldedLocaleName("zh-Hant").hashValue == FoldedLocaleName("ZH_hant").hashValue)
    }

    @Test("Different names stay different")
    func differentNamesDiffer() {
        #expect(FoldedLocaleName("zh-Hant") != FoldedLocaleName("zh-TW"))
    }

    @Test("A name from a lookup key equals the same name from its spelling")
    func keyAndSpellingAgree() {
        #expect(FoldedLocaleName(LocaleKey("ZH_hant")) == FoldedLocaleName("zh-Hant"))
        #expect(FoldedLocaleName(LocaleKey("zh-TW")) != FoldedLocaleName("zh-Hant"))
    }
}
