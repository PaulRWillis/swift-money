import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Decoding the currency-full-name section from a hand-built blob: the `other` name, per-category
// overrides, the fallback when a category is not overridden, and a currency the locale does not name.
@Suite("Currency Full Name Table Tests")
struct CurrencyFullNameTableTests {

    static func code(_ iso: String) -> CurrencyCode {
        guard let code = CurrencyCode(string: iso) else { preconditionFailure("\(iso) is not a code") }
        return code
    }

    // One locale (index 0) naming EUR (no override), GBP and USD (each with a `.one` override).
    static func makeBlob() -> (bytes: [UInt8], directoryOffset: Int) {
        var b = BlobTestBuilder()
        let names: [(code: CurrencyCode, other: StringRef, one: StringRef?)] = [
            (code("EUR"), b.pool("euros"), nil),
            (code("GBP"), b.pool("British pounds"), b.pool("British pound")),
            (code("USD"), b.pool("US dollars"), b.pool("US dollar")),
        ].sorted { $0.code.packedValue < $1.code.packedValue }

        var overrides: [(start: UInt32, count: UInt8)] = []
        for name in names {
            if let one = name.one {
                let start = UInt32(b.count)
                b.u8(PluralCategory.one.blobCode)
                b.ref(one)
                overrides.append((start, 1))
            } else {
                overrides.append((0, 0))
            }
        }

        let recordsStart = UInt32(b.count)
        for (index, name) in names.enumerated() {
            b.u64(name.code.packedValue)
            b.ref(name.other)
            b.u32(overrides[index].start)
            b.u8(overrides[index].count)
        }

        let directoryOffset = b.count
        b.u32(recordsStart)
        b.u16(UInt16(names.count))
        return (b.bytes, directoryOffset)
    }

    static func withTable(_ body: (CurrencyFullNameTable) -> Void) {
        let (bytes, directoryOffset) = makeBlob()
        bytes.withUnsafeBufferPointer { buffer in
            let reader = BlobReader(base: buffer.baseAddress!, count: buffer.count)
            body(CurrencyFullNameTable(reader: reader, directoryOffset: directoryOffset))
        }
    }

    @Test("Decodes the other name and a per-category override")
    func decodesOtherAndOverride() {
        Self.withTable { table in
            let usd = table.name(localeIndex: LocaleIndex(position: 0), code: Self.code("USD"))
            #expect(usd?.name(for: .other) == "US dollars")
            #expect(usd?.name(for: .one) == "US dollar")
        }
    }

    @Test("A category with no override falls back to the other name")
    func categoryFallsBackToOther() {
        Self.withTable { table in
            let eur = table.name(localeIndex: LocaleIndex(position: 0), code: Self.code("EUR"))
            #expect(eur?.name(for: .other) == "euros")
            #expect(eur?.name(for: .one) == "euros")
        }
    }

    @Test("A currency the locale does not name decodes to nil")
    func unnamedCurrencyIsNil() {
        Self.withTable { table in
            #expect(table.name(localeIndex: LocaleIndex(position: 0), code: Self.code("JPY")) == nil)
        }
    }

    // Formatting an amount needs one name, not every form, so it reads the category it resolved.
    @Test("One category's name is read without the rest")
    func decodesOneCategory() {
        Self.withTable { table in
            let locale = LocaleIndex(position: 0)
            #expect(table.name(localeIndex: locale, code: Self.code("USD"), category: .one) == "US dollar")
            #expect(table.name(localeIndex: locale, code: Self.code("USD"), category: .other) == "US dollars")
            #expect(table.name(localeIndex: locale, code: Self.code("USD"), category: .many) == "US dollars")
            #expect(table.name(localeIndex: locale, code: Self.code("EUR"), category: .one) == "euros")
            #expect(table.name(localeIndex: locale, code: Self.code("JPY"), category: .other) == nil)
        }
    }
}
