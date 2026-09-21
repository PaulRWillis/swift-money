import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Decoding the currency-full-name section from a hand-built blob: the `other` name, per-category
// overrides, the fallback when a category is not overridden, and a currency the locale does not name.
@Suite("Currency Full Name Table Tests")
struct CurrencyFullNameTableTests {

    // A minimal byte builder mirroring the section's layout, so the test writes exactly what the decoder
    // reads. Little-endian, matching BlobReader.
    struct Builder {
        var bytes: [UInt8] = []
        var count: Int { bytes.count }
        mutating func u8(_ v: UInt8) { bytes.append(v) }
        mutating func u16(_ v: UInt16) { u8(UInt8(v & 0xFF)); u8(UInt8(v >> 8)) }
        mutating func u32(_ v: UInt32) { for shift in stride(from: 0, to: 32, by: 8) { u8(UInt8((v >> shift) & 0xFF)) } }
        mutating func u64(_ v: UInt64) { for shift in stride(from: 0, to: 64, by: 8) { u8(UInt8((v >> shift) & 0xFF)) } }
        mutating func ref(_ r: StringRef) { u32(r.offset); u32(r.length) }
        mutating func pool(_ s: String) -> StringRef {
            let ref = StringRef(offset: UInt32(count), length: UInt32(s.utf8.count))
            bytes.append(contentsOf: s.utf8)
            return ref
        }
    }

    static func code(_ iso: String) -> CurrencyCode {
        guard let code = CurrencyCode(string: iso) else { preconditionFailure("\(iso) is not a code") }
        return code
    }

    // One locale (index 0) naming EUR (no override), GBP and USD (each with a `.one` override).
    static func makeBlob() -> (bytes: [UInt8], directoryOffset: Int) {
        var b = Builder()
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
            let usd = table.name(localeIndex: 0, code: Self.code("USD"))
            #expect(usd?.name(for: .other) == "US dollars")
            #expect(usd?.name(for: .one) == "US dollar")
        }
    }

    @Test("A category with no override falls back to the other name")
    func categoryFallsBackToOther() {
        Self.withTable { table in
            let eur = table.name(localeIndex: 0, code: Self.code("EUR"))
            #expect(eur?.name(for: .other) == "euros")
            #expect(eur?.name(for: .one) == "euros")
        }
    }

    @Test("A currency the locale does not name decodes to nil")
    func unnamedCurrencyIsNil() {
        Self.withTable { table in
            #expect(table.name(localeIndex: 0, code: Self.code("JPY")) == nil)
        }
    }
}
