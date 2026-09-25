import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Decoding the per-locale override section: a composite (localeIndex, systemIndex) key resolves to a
// separator set by binary search, a reuse system (no rows) always misses, and a non-overriding locale
// misses too.
@Suite("Numbering System Override Table Tests")
struct NumberingSystemOverrideTableTests {

    // Two rows, sorted by (localeIndex, systemIndex): locale 3 overrides system 2 (Central Kurdish arab),
    // locale 5 overrides system 4 (Persian arabext).
    static func withTable(_ body: (NumberingSystemOverrideTable) throws -> Void) rethrows {
        var b = BlobTestBuilder()
        let kurdishMinus = b.pool("\u{200F}-")
        let persianMinus = b.pool("\u{200E}\u{2212}")
        let decimal = b.pool("٫")
        let grouping = b.pool("٬")

        let sectionOffset = b.count
        b.u16(2)
        // locale 3, system 2
        b.u16(3)
        b.u8(2)
        b.ref(decimal)
        b.ref(grouping)
        b.ref(kurdishMinus)
        // locale 5, system 4
        b.u16(5)
        b.u8(4)
        b.ref(decimal)
        b.ref(grouping)
        b.ref(persianMinus)

        try b.bytes.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else {
                Issue.record("empty test blob buffer")
                return
            }
            let reader = BlobReader(base: base, count: buffer.count)
            try body(NumberingSystemOverrideTable(reader: reader, sectionOffset: sectionOffset))
        }
    }

    @Test("An overriding locale resolves to its own separators")
    func resolvesOverride() throws {
        try Self.withTable { table in
            let symbols = try #require(table.symbols(
                localeIndex: LocaleIndex(position: 5), systemIndex: SystemIndex(position: 4)
            ))
            #expect(symbols.decimalSeparator == "٫")
            #expect(symbols.groupingSeparator == "٬")
            #expect(symbols.minusSign == "\u{200E}\u{2212}")
        }
    }

    @Test("The first row resolves too")
    func resolvesFirstRow() throws {
        try Self.withTable { table in
            let symbols = try #require(table.symbols(
                localeIndex: LocaleIndex(position: 3), systemIndex: SystemIndex(position: 2)
            ))
            #expect(symbols.minusSign == "\u{200F}-")
        }
    }

    @Test("A locale with no override for the system misses")
    func nonOverridingMisses() throws {
        try Self.withTable { table in
            #expect(table.symbols(localeIndex: LocaleIndex(position: 3), systemIndex: SystemIndex(position: 4)) == nil)
            #expect(table.symbols(localeIndex: LocaleIndex(position: 99), systemIndex: SystemIndex(position: 2)) == nil)
        }
    }

    // MARK: - The generated section

    // Every locale whose arab/arabext block differs from the system default (ckb, fa, sd and their variants)
    // is currently skipped for an unrelated reason, so no covered locale overrides an imposing system yet.
    // The section is present and correct; it populates once those locales become renderable.
    // Of the locales whose arab/arabext block differs from the system default (ckb, fa, sd families), only
    // fa-AF is currently covered; the rest are skipped for unrelated reasons. So the section holds one row.
    @Test("fa-AF is the one covered locale that overrides arabext")
    func generatedFaAF() throws {
        let cldr = MoneyLocalization.cldr
        #expect(cldr.numberingSystemOverrides.count == 1)

        let faAF = try #require(cldr.locales.index(of: "fa-AF"))
        let arabext = try #require(cldr.numberingSystems.index(of: "arabext"))
        let symbols = try #require(cldr.numberingSystemOverrides.symbols(localeIndex: faAF, systemIndex: arabext))
        #expect(symbols.decimalSeparator == "\u{066B}")
        #expect(symbols.groupingSeparator == "\u{066C}")
        #expect(symbols.minusSign == "\u{200E}\u{2212}")
    }

    @Test("A covered locale with no arabext override misses")
    func generatedNonOverridingMisses() throws {
        let cldr = MoneyLocalization.cldr
        let en = try #require(cldr.locales.index(of: "en"))
        let arab = try #require(cldr.numberingSystems.index(of: "arab"))
        let arabext = try #require(cldr.numberingSystems.index(of: "arabext"))
        #expect(cldr.numberingSystemOverrides.symbols(localeIndex: en, systemIndex: arab) == nil)
        #expect(cldr.numberingSystemOverrides.symbols(localeIndex: en, systemIndex: arabext) == nil)
    }

    @Test("A reuse system never has an override row")
    func reuseSystemMisses() throws {
        let systems = MoneyLocalization.cldr.numberingSystems
        let deva = try #require(systems.index(of: "deva"))
        let en = try #require(MoneyLocalization.cldr.locales.index(of: "en"))
        #expect(MoneyLocalization.cldr.numberingSystemOverrides.symbols(localeIndex: en, systemIndex: deva) == nil)
    }
}
