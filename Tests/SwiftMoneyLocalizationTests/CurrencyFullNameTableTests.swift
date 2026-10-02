import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Decoding the currency-full-name section from a hand-built blob: the `other` name, per-category
// overrides, the fallback when a category is not overridden, and a currency the locale does not name.
@Suite("Currency Full Name Table Tests")
struct CurrencyFullNameTableTests {

    /// Returns a blob of one locale (index 0) naming EUR (no override), GBP and USD (each with a
    /// `.one` override).
    ///
    /// - Returns: The blob's bytes, and the offset of its directory.
    /// - Throws: The error `#require` throws if a fixture's code isn't one the tables hold.
    static func makeBlob() throws -> (bytes: [UInt8], directoryOffset: Int) {
        var b = BlobTestBuilder()
        let eur = try tableCode("EUR")
        let gbp = try tableCode("GBP")
        let usd = try tableCode("USD")
        let names: [(code: Localization.CurrencyCode, other: StringRef, one: StringRef?)] = [
            (eur, b.pool("euros"), nil),
            (gbp, b.pool("British pounds"), b.pool("British pound")),
            (usd, b.pool("US dollars"), b.pool("US dollar")),
        ].sorted { $0.code < $1.code }

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

        let recordsStart = b.count
        for (index, name) in names.enumerated() {
            b.currencyCode(name.code)
            b.ref(name.other)
            b.offsetField(Int(overrides[index].start))
            b.u8(overrides[index].count)
        }

        let directoryOffset = b.count
        b.offsetField(recordsStart)
        b.u16(UInt16(names.count))
        return (b.bytes, directoryOffset)
    }

    /// Calls `body` with a table over the fixture blob.
    ///
    /// - Parameter body: The checks to run against the table.
    /// - Throws: The error `#require` throws if the fixture can't be built or has no base address.
    static func withTable(_ body: (CurrencyFullNameTable) -> Void) throws {
        let (bytes, directoryOffset) = try makeBlob()
        try bytes.withUnsafeBufferPointer { buffer in
            let reader = BlobReader(base: try #require(buffer.baseAddress), count: buffer.count)
            body(CurrencyFullNameTable(reader: reader, directoryOffset: directoryOffset))
        }
    }

    @Test("Decodes the other name and a per-category override")
    func decodesOtherAndOverride() throws {
        try Self.withTable { table in
            let usd = table.name(localeIndex: LocaleIndex(position: 0), code: "USD")
            #expect(usd?.name(for: .other) == "US dollars")
            #expect(usd?.name(for: .one) == "US dollar")
        }
    }

    @Test("A category with no override falls back to the other name")
    func categoryFallsBackToOther() throws {
        try Self.withTable { table in
            let eur = table.name(localeIndex: LocaleIndex(position: 0), code: "EUR")
            #expect(eur?.name(for: .other) == "euros")
            #expect(eur?.name(for: .one) == "euros")
        }
    }

    @Test("A currency the locale does not name decodes to nil")
    func unnamedCurrencyIsNil() throws {
        try Self.withTable { table in
            #expect(table.name(localeIndex: LocaleIndex(position: 0), code: "JPY") == nil)
        }
    }

    @Test("A code longer than the tables hold decodes to nil")
    func longerCodeIsNil() throws {
        try Self.withTable { table in
            let locale = LocaleIndex(position: 0)
            #expect(table.name(localeIndex: locale, code: "USDT") == nil)
            #expect(table.name(localeIndex: locale, code: "USDT", category: .other) == nil)
        }
    }

    // Formatting an amount needs one name, not every form, so it reads the category it resolved.
    @Test("One category's name is read without the rest")
    func decodesOneCategory() throws {
        try Self.withTable { table in
            let locale = LocaleIndex(position: 0)
            #expect(table.name(localeIndex: locale, code: "USD", category: .one) == "US dollar")
            #expect(table.name(localeIndex: locale, code: "USD", category: .other) == "US dollars")
            #expect(table.name(localeIndex: locale, code: "USD", category: .many) == "US dollars")
            #expect(table.name(localeIndex: locale, code: "EUR", category: .one) == "euros")
            #expect(table.name(localeIndex: locale, code: "JPY", category: .other) == nil)
        }
    }
}
