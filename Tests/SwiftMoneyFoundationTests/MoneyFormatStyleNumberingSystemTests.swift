import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

// The bridge reads the locale's numbering system: a modelled one renders through the engine (imposing or
// reuse), the locale's default stays byte-identical, and an unmodelled one falls back to ICU rather than
// silently emitting the locale's default digits.
@Suite("Money Format Style Numbering System Tests")
struct MoneyFormatStyleNumberingSystemTests {

    static func formatted(_ localeID: String) -> String {
        GBP.FormatStyle().locale(Locale(identifier: localeID)).format(GBP(minorUnits: 1_234_56))
    }

    @Test("A plain locale renders exactly as before")
    func defaultUnchanged() {
        #expect(Self.formatted("en_GB") == "£1,234.56")
    }

    @Test("An imposing numbering system renders its digits and separators")
    func imposingSystem() {
        #expect(Self.formatted("en_GB@numbers=arab") == "£١٬٢٣٤٫٥٦")
    }

    @Test("A reuse numbering system swaps digits, keeping the locale's separators")
    func reuseSystem() {
        #expect(Self.formatted("en_GB@numbers=nkoo") == "£߁,߂߃߄.߅߆")
    }

    @Test("An unmodelled numbering system falls back to ICU, not the locale's default digits")
    func unmodelledFallsBackToICU() {
        let out = Self.formatted("en_GB@numbers=hanidec")
        // The ICU fallback renders hanidec's ideographic digits; our engine would have emitted ASCII.
        #expect(!out.contains { $0.isASCII && $0.isNumber })
        #expect(out != "£1,234.56")
    }

    @Test("A locale whose Foundation numbering system is non-Latin renders those digits")
    func nonLatinDefault() {
        // Foundation resolves `ne` to deva, so the engine renders Devanagari digits.
        let ne = GBP.FormatStyle().locale(Locale(identifier: "ne")).format(GBP(minorUnits: 1_234_56))
        #expect(!ne.contains { $0.isASCII && $0.isNumber })
        #expect(ne.contains("४"))   // Devanagari 4
    }

    @Test("The bridge follows Foundation's numbering system, not the blob's baked default")
    func followsFoundationNotBlob() {
        // Foundation resolves `bn` to latn even though CLDR bakes beng, so honoring the locale renders
        // Latin digits — matching the rest of Foundation and fixing the previous mixed-numerals divergence.
        let bn = Self.formatted("bn")
        #expect(bn.contains("4"))     // Latin digits, as Foundation asks
        #expect(!bn.contains("৪"))    // not the baked Bengali digits
    }

    @Test("The attributed output matches the plain output for a numbering system")
    func attributedMatches() {
        let style = GBP.FormatStyle().locale(Locale(identifier: "en_GB@numbers=arab"))
        let attributed = GBP(minorUnits: 1_234_56).formatted(style.attributed)
        #expect(String(attributed.characters) == style.format(GBP(minorUnits: 1_234_56)))
    }
}
