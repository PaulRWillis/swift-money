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
        let symbol = body.pool("£")
        let name = body.pool("British pounds")

        let localesOffset = body.count
        body.ref(key)

        let numberFormatsOffset = body.count
        body.ref(decimalSeparator)
        body.ref(groupingSeparator)
        body.ref(minusSign)
        body.u8(Spacing.nonBreakingSpace.blobCode)
        body.u8(3)
        body.u8(3)
        body.u8(Spacing.asciiSpace.blobCode)
        body.u16(0)
        body.u16(0)
        body.ref(StringRef.empty)

        let displayRecordsStart = body.count
        body.currencyCode(gbp.compactValue)
        body.ref(symbol)
        body.u8(Spacing.none.blobCode)
        body.ref(symbol)
        body.u8(Spacing.none.blobCode)

        let displaysOffset = body.count
        body.offsetField(displayRecordsStart)
        body.u16(1)

        let fullNameRecordsStart = body.count
        body.currencyCode(gbp.compactValue)
        body.ref(name)
        body.offsetField(0)
        body.u8(0)

        let fullNamesOffset = body.count
        body.offsetField(fullNameRecordsStart)
        body.u16(1)

        // "en" with a single .one rule: i = 1 and v = 0.
        let pluralRuleEntry = body.count
        body.u8(PluralCategory.one.blobCode)
        body.u8(1)   // one group
        body.u8(2)   // two relations
        body.u8(PluralOperand.integerPart.blobCode); body.u32(0); body.u8(0); body.u8(1); body.u32(1); body.u32(1)
        body.u8(PluralOperand.fractionDigitCount.blobCode); body.u32(0); body.u8(0); body.u8(1); body.u32(0); body.u32(0)

        let pluralRulesOffset = body.count
        body.u32(1)   // one language
        body.ref(key); body.offsetField(pluralRuleEntry); body.u8(1)

        var header = BlobTestBuilder()
        header.u32(1)
        header.offsetField(localesOffset)
        header.offsetField(numberFormatsOffset)
        header.offsetField(displaysOffset)
        header.offsetField(fullNamesOffset)
        header.offsetField(pluralRulesOffset)

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
            #expect(blob.pluralRules.allRules()["en"]?[.one] != nil)
        }
    }

    @Test("A header offset is where the generator lays out the first section")
    func headerPrecedesTheSections() {
        // A locale count then five section offsets.
        #expect(CLDRBlob.headerWidth == BlobDigits.u32 + BlobDigits.offset * 5)
    }
}
