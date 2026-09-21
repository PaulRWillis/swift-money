import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Decoding the currency-display section from a hand-built blob: a currency's symbol, narrow symbol and
// their spacings, and a currency with no distinct symbol decoding to nil.
@Suite("Currency Display Table Tests")
struct CurrencyDisplayTableTests {

    static func code(_ iso: String) -> CurrencyCode {
        guard let code = CurrencyCode(string: iso) else { preconditionFailure("\(iso) is not a code") }
        return code
    }

    // One locale (index 0) displaying GBP (£, no gap) and USD (US$ standard, $ narrow).
    static func makeBlob() -> (bytes: [UInt8], directoryOffset: Int) {
        var b = BlobTestBuilder()
        let records: [(code: CurrencyCode, standard: StringRef, standardGap: StringRef, narrow: StringRef, narrowGap: StringRef)] = [
            (code("GBP"), b.pool("£"), b.pool(""), b.pool("£"), b.pool("")),
            (code("USD"), b.pool("US$"), b.pool("\u{00A0}"), b.pool("$"), b.pool("")),
        ].sorted { $0.code.packedValue < $1.code.packedValue }

        let recordsStart = UInt32(b.count)
        for record in records {
            b.u64(record.code.packedValue)
            b.ref(record.standard)
            b.ref(record.standardGap)
            b.ref(record.narrow)
            b.ref(record.narrowGap)
        }

        let directoryOffset = b.count
        b.u32(recordsStart)
        b.u16(UInt16(records.count))
        return (b.bytes, directoryOffset)
    }

    static func withTable(_ body: (CurrencyDisplayTable) -> Void) {
        let (bytes, directoryOffset) = makeBlob()
        bytes.withUnsafeBufferPointer { buffer in
            let reader = BlobReader(base: buffer.baseAddress!, count: buffer.count)
            body(CurrencyDisplayTable(reader: reader, directoryOffset: directoryOffset))
        }
    }

    @Test("Decodes a currency's symbols and spacings")
    func decodesSymbols() {
        Self.withTable { table in
            let usd = table.display(localeIndex: LocaleIndex(position: 0), code: Self.code("USD"))
            #expect(usd == CurrencyDisplay(
                standardSymbol: "US$", standardSpacing: "\u{00A0}", narrowSymbol: "$", narrowSpacing: ""
            ))
        }
    }

    @Test("A currency with no distinct symbol decodes to nil")
    func undisplayedCurrencyIsNil() {
        Self.withTable { table in
            #expect(table.display(localeIndex: LocaleIndex(position: 0), code: Self.code("EUR")) == nil)
        }
    }
}
