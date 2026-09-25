import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Decoding the numbering-system section: names resolve to indices by binary search, digits decode as ASCII
// or a glyph set, and provenance decodes into the sum type so a reuse record never shows phantom separators.
@Suite("Numbering System Table Tests")
struct NumberingSystemTableTests {

    // A two-record section sorted by name: "arab" (imposes ٫/٬ and its own digits) then "deva" (reuses the
    // locale's separators, swapping digits only).
    static func withTable(_ body: (NumberingSystemTable) throws -> Void) rethrows {
        var b = BlobTestBuilder()
        let arabName = b.pool("arab")
        let arabDigits = b.pool("٠١٢٣٤٥٦٧٨٩")
        let decimal = b.pool("٫")
        let grouping = b.pool("٬")
        let minus = b.pool("\u{061C}-")
        let devaName = b.pool("deva")
        let devaDigits = b.pool("०१२३४५६७८९")

        let sectionOffset = b.count
        b.u16(2)
        // arab: imposesOwn
        b.ref(arabName)
        b.u8(NumberingSystemTable.ProvenanceTag.imposesOwn)
        b.ref(arabDigits)
        b.ref(decimal)
        b.ref(grouping)
        b.ref(minus)
        // deva: reusesLocale (empty separators)
        b.ref(devaName)
        b.u8(NumberingSystemTable.ProvenanceTag.reusesLocale)
        b.ref(devaDigits)
        b.ref(.empty)
        b.ref(.empty)
        b.ref(.empty)

        try b.bytes.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else {
                Issue.record("empty test blob buffer")
                return
            }
            let reader = BlobReader(base: base, count: buffer.count)
            try body(NumberingSystemTable(reader: reader, sectionOffset: sectionOffset))
        }
    }

    @Test("An imposing system decodes its own separators and digits")
    func decodesImposing() throws {
        try Self.withTable { table in
            let index = try #require(table.index(of: "arab"))
            let arabGlyphs = try #require(DigitGlyphs("٠١٢٣٤٥٦٧٨٩"))
            #expect(table.digits(at: index) == .glyphs(arabGlyphs))
            guard case .imposesOwn(let symbols) = table.provenance(at: index) else {
                Issue.record("arab should impose its own separators")
                return
            }
            #expect(symbols.decimalSeparator == "٫")
            #expect(symbols.groupingSeparator == "٬")
            #expect(symbols.minusSign == "\u{061C}-")
        }
    }

    @Test("A reusing system decodes its digits and no separators")
    func decodesReusing() throws {
        try Self.withTable { table in
            let index = try #require(table.index(of: "deva"))
            let devaGlyphs = try #require(DigitGlyphs("०१२३४५६७८९"))
            #expect(table.digits(at: index) == .glyphs(devaGlyphs))
            #expect(table.provenance(at: index) == .reusesLocale)
        }
    }

    @Test("An unknown name resolves to nil")
    func rejectsUnknown() {
        Self.withTable { table in
            #expect(table.index(of: "hanidec") == nil)
            #expect(table.index(of: "zzzz") == nil)
        }
    }

    // MARK: - The generated section

    @Test("The generated section holds all 77 systems")
    func generatedCount() {
        #expect(MoneyLocalization.cldr.numberingSystems.count == 77)
    }

    @Test("Generated arab imposes the CLDR-root separators and its digits")
    func generatedArab() throws {
        let systems = MoneyLocalization.cldr.numberingSystems
        let index = try #require(systems.index(of: "arab"))
        let arabGlyphs = try #require(DigitGlyphs("٠١٢٣٤٥٦٧٨٩"))
        #expect(systems.digits(at: index) == .glyphs(arabGlyphs))
        guard case .imposesOwn(let symbols) = systems.provenance(at: index) else {
            Issue.record("generated arab should impose its own separators")
            return
        }
        #expect(symbols.decimalSeparator == "\u{066B}")
        #expect(symbols.groupingSeparator == "\u{066C}")
        #expect(symbols.minusSign == "\u{061C}-")
    }

    @Test("Generated arabext imposes the CLDR-root separators")
    func generatedArabext() throws {
        let systems = MoneyLocalization.cldr.numberingSystems
        let index = try #require(systems.index(of: "arabext"))
        guard case .imposesOwn(let symbols) = systems.provenance(at: index) else {
            Issue.record("generated arabext should impose its own separators")
            return
        }
        #expect(symbols.decimalSeparator == "\u{066B}")
        #expect(symbols.groupingSeparator == "\u{066C}")
        #expect(symbols.minusSign == "\u{200E}-\u{200E}")
    }

    @Test(
        "The five reclassified systems reuse the locale's separators",
        arguments: ["adlm", "nkoo", "java", "khmr", "laoo", "deva", "beng"]
    )
    func generatedReuse(_ name: String) throws {
        let systems = MoneyLocalization.cldr.numberingSystems
        let index = try #require(systems.index(of: name))
        #expect(systems.provenance(at: index) == .reusesLocale)
    }

    @Test("Latin decodes as the ASCII digit set, reusing the locale's separators")
    func generatedLatin() throws {
        let systems = MoneyLocalization.cldr.numberingSystems
        let index = try #require(systems.index(of: "latn"))
        #expect(systems.digits(at: index) == .ascii)
        #expect(systems.provenance(at: index) == .reusesLocale)
    }

    @Test("hanidec is absent from the generated section")
    func generatedHanidecAbsent() {
        #expect(MoneyLocalization.cldr.numberingSystems.index(of: "hanidec") == nil)
    }
}
