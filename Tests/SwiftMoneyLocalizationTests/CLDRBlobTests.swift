import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Reading the whole packed buffer through its header. Each section here holds content only it could
// return, so a header field pointing at the wrong section shows up as the wrong answer rather than as a
// crash: the sections are otherwise the ones their own suites cover.
@Suite("CLDR Blob Tests")
struct CLDRBlobTests {

    static let pattern = MoneyFormatPattern(
        positive: MoneyFormatAffixes(prefix: [.sign, .currency, .currencySpacing], suffix: []),
        negative: MoneyFormatAffixes(prefix: [.sign, .currency, .currencySpacing], suffix: []),
        accountingNegative: MoneyFormatAffixes(prefix: [.literal("("), .currency], suffix: [.literal(")")])
    )
    static let fullNamePattern = FullNameLayout(
        other: MoneyFormatAffixes(prefix: [.sign], suffix: [.currencySpacing, .currency])
    )

    static let gbp: CurrencyCode = "GBP"

    // One locale, "en", naming and displaying GBP alone.
    static func makeBlob() -> [UInt8] {
        var body = BlobTestBuilder(base: CLDRBlob.headerWidth)

        let key = body.pool("en")
        let decimalSeparator = body.pool(".")
        let groupingSeparator = body.pool(",")
        let minusSign = body.pool("-")
        let isoCodeSpacing = body.pool("\u{00A0}")
        let symbol = body.pool("£")
        let noSpacing = body.pool("")
        let name = body.pool("British pounds")

        let localesOffset = body.count
        body.ref(key)

        let numberFormatsOffset = body.count
        body.ref(decimalSeparator)
        body.ref(groupingSeparator)
        body.ref(minusSign)
        body.ref(isoCodeSpacing)
        body.u8(3)
        body.u8(3)
        body.u8(Spacing.asciiSpace.blobCode)
        body.u16(0)
        body.u16(0)

        let displayRecordsStart = body.count
        body.u64(gbp.packedValue)
        body.ref(symbol)
        body.ref(noSpacing)
        body.ref(symbol)
        body.ref(noSpacing)

        let displaysOffset = body.count
        body.u32(UInt32(displayRecordsStart))
        body.u16(1)

        let fullNameRecordsStart = body.count
        body.u64(gbp.packedValue)
        body.ref(name)
        body.u32(0)
        body.u8(0)

        let fullNamesOffset = body.count
        body.u32(UInt32(fullNameRecordsStart))
        body.u16(1)

        var header = BlobTestBuilder()
        header.u32(1)
        header.u32(UInt32(localesOffset))
        header.u32(UInt32(numberFormatsOffset))
        header.u32(UInt32(displaysOffset))
        header.u32(UInt32(fullNamesOffset))

        return header.bytes + body.bytes
    }

    static func withBlob(_ body: (CLDRBlob) -> Void) {
        makeBlob().withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else {
                Issue.record("a non-empty array has a base address")
                return
            }
            body(CLDRBlob(
                reader: BlobReader(base: base, count: buffer.count),
                patterns: [pattern],
                fullNamePatterns: [fullNamePattern]
            ))
        }
    }

    @Test("The header gives the locale count and resolves a locale")
    func readsTheLocaleSection() {
        Self.withBlob { blob in
            #expect(blob.locales.localeCount == 1)
            #expect(blob.locales.index(of: "en") == LocaleIndex(position: 0))
            #expect(blob.locales.index(of: "de") == nil)
        }
    }

    @Test("Each table reads its own section")
    func readsEachTable() {
        Self.withBlob { blob in
            let locale = LocaleIndex(position: 0)

            #expect(blob.numberFormats.numberFormat(localeIndex: locale).decimalSeparator == ".")
            #expect(blob.currencyDisplays.display(localeIndex: locale, code: Self.gbp)?.standardSymbol == "£")
            #expect(blob.currencyFullNames.name(localeIndex: locale, code: Self.gbp)?.name(for: .other)
                == "British pounds")
        }
    }

    @Test("A header offset is where the generator lays out the first section")
    func headerPrecedesTheSections() {
        #expect(CLDRBlob.headerWidth == BlobDigits.u32 * 5)
    }
}
