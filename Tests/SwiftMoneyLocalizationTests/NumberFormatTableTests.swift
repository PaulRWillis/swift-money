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
    // pattern index 0, full-name pattern index 0.
    static func makeBlob() -> (bytes: [UInt8], recordsOffset: Int) {
        var b = BlobTestBuilder()
        let decimal = b.pool(".")
        let grouping = b.pool(",")
        let minus = b.pool("-")
        let iso = b.pool("\u{00A0}")

        let recordsOffset = b.count
        b.ref(decimal)
        b.ref(grouping)
        b.ref(minus)
        b.ref(iso)
        b.u8(3)
        b.u8(3)
        b.u8(Spacing.asciiSpace.blobCode)
        b.u16(0)
        b.u16(0)
        return (b.bytes, recordsOffset)
    }

    static func withTable(_ body: (NumberFormatTable) -> Void) {
        let (bytes, recordsOffset) = makeBlob()
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
            let format = table.numberFormat(localeIndex: 0)
            #expect(format.decimalSeparator == ".")
            #expect(format.groupingSeparator == ",")
            #expect(format.minusSign == "-")
            #expect(format.isoCodeSpacing == "\u{00A0}")
            #expect(format.primaryGroupingSize == 3)
            #expect(format.secondaryGroupingSize == 3)
            #expect(format.fullNameSpacing == .asciiSpace)
            #expect(format.pattern == Self.symbolPattern)
            #expect(format.fullNamePattern == Self.fullName)
        }
    }
}
