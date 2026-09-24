import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Decoding a per-locale number-format record from a hand-built blob: the separators and grouping, and
// the symbol/full-name patterns resolved from their interned indices.
@Suite("Number Format Table Tests")
struct NumberFormatTableTests {

    static let symbolPattern = MoneyFormatPattern(
        positive: MoneyFormatAffixes(prefix: [.sign, .currency, .currencySpacing], suffix: []),
        negative: MoneyFormatAffixes(prefix: [.sign, .currency, .currencySpacing], suffix: []),
        accountingNegative: MoneyFormatAffixes(prefix: [.literal("("), .currency], suffix: [.literal(")")])
    )
    static let fullName = FullNameLayout(
        other: MoneyFormatAffixes(prefix: [.sign], suffix: [.currencySpacing, .currency])
    )

    // One locale (index 0): "." decimal, "," grouping of 3, "-", NBSP iso spacing, ascii full-name gap,
    // pattern index 0, full-name pattern index 0, and the given digit glyphs (empty = ASCII).
    static func makeBlob(digitGlyphs: String = "", minGrouping: UInt8 = 1) -> (bytes: [UInt8], recordsOffset: Int) {
        var b = BlobTestBuilder()
        let decimal = b.pool(".")
        let grouping = b.pool(",")
        let minus = b.pool("-")
        let digits = digitGlyphs.isEmpty ? StringRef.empty : b.pool(digitGlyphs)

        let recordsOffset = b.count
        b.ref(decimal)
        b.ref(grouping)
        b.ref(minus)
        b.u8(Spacing.nonBreakingSpace.blobCode)
        b.u8(Spacing.narrowNonBreakingSpace.blobCode)
        b.u8(3)
        b.u8(3)
        b.u8(Spacing.asciiSpace.blobCode)
        b.u16(0)
        b.u16(0)
        b.ref(digits)
        b.u8(minGrouping)
        return (b.bytes, recordsOffset)
    }

    static func withTable(digitGlyphs: String = "", minGrouping: UInt8 = 1, _ body: (NumberFormatTable) -> Void) {
        let (bytes, recordsOffset) = makeBlob(digitGlyphs: digitGlyphs, minGrouping: minGrouping)
        bytes.withUnsafeBufferPointer { buffer in
            let reader = BlobReader(base: buffer.baseAddress!, count: buffer.count)
            body(NumberFormatTable(
                reader: reader,
                recordsOffset: recordsOffset,
                patterns: [symbolPattern],
                fullNamePatterns: [fullName]
            ))
        }
    }

    @Test("Decodes the scalars and resolves the interned patterns")
    func decodesRecord() {
        Self.withTable { table in
            let format = table.numberFormat(localeIndex: LocaleIndex(position: 0))
            #expect(format.decimalSeparator == ".")
            #expect(format.groupingSeparator == ",")
            #expect(format.minusSign == "-")
            #expect(format.isoCodeSpacing == .nonBreakingSpace)
            #expect(format.symbolSpacing == .narrowNonBreakingSpace)
            #expect(format.primaryGroupingSize == 3)
            #expect(format.secondaryGroupingSize == 3)
            #expect(format.fullNameSpacing == .asciiSpace)
            #expect(format.pattern == Self.symbolPattern)
            #expect(format.fullNamePattern == Self.fullName)
            #expect(format.minGroupingDigits == 1)
        }
    }

    @Test("The minimum grouping digits decode from the record")
    func decodesMinGroupingDigits() {
        Self.withTable(minGrouping: 2) { table in
            #expect(table.numberFormat(localeIndex: LocaleIndex(position: 0)).minGroupingDigits == 2)
        }
    }

    @Test("An empty digit ref decodes as the ASCII digit set")
    func decodesAsciiDigits() {
        Self.withTable { table in
            #expect(table.numberFormat(localeIndex: LocaleIndex(position: 0)).digits == .ascii)
        }
    }

    @Test("A digit ref decodes as the locale's own glyphs")
    func decodesGlyphDigits() throws {
        let expected = try #require(DigitGlyphs("০১২৩৪৫৬৭৮৯"))
        Self.withTable(digitGlyphs: "০১২৩৪৫৬৭৮৯") { table in
            let digits = table.numberFormat(localeIndex: LocaleIndex(position: 0)).digits
            #expect(digits == .glyphs(expected))
        }
    }

    // The generated tables carry the pattern gap the commit adds: German bakes a non-breaking space
    // beside every symbol, English bakes none.
    @Test(
        "The generated tables carry each locale's pattern gap",
        arguments: [(locale: "de", gap: Spacing.nonBreakingSpace), (locale: "en", gap: .none)]
    )
    func generatedTablesCarryTheSymbolGap(_ row: (locale: String, gap: Spacing)) throws {
        let index = try #require(MoneyLocalization.cldr.locales.index(of: LocaleIdentifier(row.locale)))
        let format = MoneyLocalization.cldr.numberFormats.numberFormat(localeIndex: index)
        #expect(format.symbolSpacing == row.gap)
    }
}
