import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Decoding the currency-display section from a hand-built blob: a currency's symbol, narrow symbol and
// their spacings, and a currency with no distinct symbol decoding to nil.
@Suite("Currency Display Table Tests")
struct CurrencyDisplayTableTests {

    // One locale (index 0) displaying GBP (£, no gap, a glyph both forms) and USD (US$ standard, a
    // letter-adjacent form as in a locale that takes it through `-alphaNextToNumber`; $ narrow, a glyph).
    static func makeBlob() throws -> (bytes: [UInt8], directoryOffset: Int) {
        var b = BlobTestBuilder()
        let gbp = try tableCode("GBP")
        let usd = try tableCode("USD")
        let records: [(
            code: Localization.CurrencyCode, standard: StringRef, standardGap: Spacing,
            standardForm: SymbolForm, narrow: StringRef, narrowGap: Spacing, narrowForm: SymbolForm
        )] = [
            (gbp, b.pool("£"), .none, .glyph, b.pool("£"), .none, .glyph),
            (usd, b.pool("US$"), .nonBreakingSpace, .letters, b.pool("$"), .none, .glyph),
        ].sorted { $0.code < $1.code }

        let recordsStart = b.count
        for record in records {
            b.currencyCode(record.code)
            b.ref(record.standard)
            b.u8(record.standardGap.blobCode)
            b.ref(record.narrow)
            b.u8(record.narrowGap.blobCode)
            b.u8(record.standardForm.blobBit | (record.narrowForm.blobBit << 1))
        }

        let directoryOffset = b.count
        b.offsetField(recordsStart)
        b.u16(UInt16(records.count))
        return (b.bytes, directoryOffset)
    }

    static func withTable(_ body: (CurrencyDisplayTable) -> Void) throws {
        let (bytes, directoryOffset) = try makeBlob()
        try bytes.withUnsafeBufferPointer { buffer in
            let reader = BlobReader(base: try #require(buffer.baseAddress), count: buffer.count)
            body(CurrencyDisplayTable(reader: reader, directoryOffset: directoryOffset))
        }
    }

    @Test("Decodes a currency's symbols, spacings and letter forms")
    func decodesSymbols() throws {
        try Self.withTable { table in
            let usd = table.display(localeIndex: LocaleIndex(position: 0), code: "USD")
            #expect(usd == CurrencyDisplay(
                standardSymbol: "US$", standardSpacing: .nonBreakingSpace, standardForm: .letters,
                narrowSymbol: "$", narrowSpacing: .none, narrowForm: .glyph
            ))
        }
    }

    @Test("A currency with no distinct symbol decodes to nil")
    func undisplayedCurrencyIsNil() throws {
        try Self.withTable { table in
            #expect(table.display(localeIndex: LocaleIndex(position: 0), code: "EUR") == nil)
        }
    }

    @Test("A code longer than the tables hold decodes to nil")
    func longerCodeIsNil() throws {
        try Self.withTable { table in
            #expect(table.display(localeIndex: LocaleIndex(position: 0), code: "USDT") == nil)
        }
    }
}
