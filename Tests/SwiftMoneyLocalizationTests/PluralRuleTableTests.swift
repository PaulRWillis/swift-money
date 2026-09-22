import SwiftMoneyLocalization
import Testing

// Decoding the plural-rule section from a hand-built blob: a language's rule per category, built back into
// the model, exercising modulus, equals/notEquals, single and span ranges, and multi-relation multi-group
// rules.
@Suite("Plural Rule Table Tests")
struct PluralRuleTableTests {

    // "en": one = (i = 1 and v = 0). "fr": many = (e = 0 and i != 0 and i % 1000000 = 0 and v = 0) or
    // (e != 0..5). The rule bytes come before the directory, which each entry points back at.
    static func makeBlob() -> (bytes: [UInt8], sectionOffset: Int) {
        var b = BlobTestBuilder()
        let en = b.pool("en")
        let fr = b.pool("fr")

        let enRules = b.count
        b.u8(PluralCategory.one.blobCode)
        b.u8(1)   // one group
        b.u8(2)   // two relations
        b.relation(.integerPart, equals: true, ranges: [1 ... 1])
        b.relation(.fractionDigitCount, equals: true, ranges: [0 ... 0])

        let frRules = b.count
        b.u8(PluralCategory.many.blobCode)
        b.u8(2)   // two groups
        b.u8(4)   // group one: four relations
        b.relation(.compactExponent, equals: true, ranges: [0 ... 0])
        b.relation(.integerPart, equals: false, ranges: [0 ... 0])
        b.relation(.integerPart, modulus: 1_000_000, equals: true, ranges: [0 ... 0])
        b.relation(.fractionDigitCount, equals: true, ranges: [0 ... 0])
        b.u8(1)   // group two: one relation
        b.relation(.compactExponent, equals: false, ranges: [0 ... 5])

        let sectionOffset = b.count
        b.u32(2)   // language count
        b.ref(en); b.u32(UInt32(enRules)); b.u8(1)
        b.ref(fr); b.u32(UInt32(frRules)); b.u8(1)

        return (b.bytes, sectionOffset)
    }

    static func withTable(_ body: (PluralRuleTable) -> Void) {
        let (bytes, sectionOffset) = makeBlob()
        bytes.withUnsafeBufferPointer { buffer in
            let reader = BlobReader(base: buffer.baseAddress!, count: buffer.count)
            body(PluralRuleTable(reader: reader, sectionOffset: sectionOffset))
        }
    }

    @Test("Decodes a simple rule of one and-group")
    func decodesSimpleRule() {
        Self.withTable { table in
            let expected = PluralRule(orOfAndGroups: NonEmpty(NonEmpty(
                PluralRelation(operand: .integerPart, comparison: .equals(NonEmpty(PluralRange(1)))),
                [PluralRelation(operand: .fractionDigitCount, comparison: .equals(NonEmpty(PluralRange(0))))]
            )))
            #expect(table.allRules()["en"] == [.one: expected])
        }
    }

    @Test("Decodes modulus, notEquals, a span range and an or of and-groups")
    func decodesComplexRule() {
        Self.withTable { table in
            let expected = PluralRule(orOfAndGroups: NonEmpty(
                NonEmpty(
                    PluralRelation(operand: .compactExponent, comparison: .equals(NonEmpty(PluralRange(0)))),
                    [
                        PluralRelation(operand: .integerPart, comparison: .notEquals(NonEmpty(PluralRange(0)))),
                        PluralRelation(operand: .integerPart, modulus: 1_000_000, comparison: .equals(NonEmpty(PluralRange(0)))),
                        PluralRelation(operand: .fractionDigitCount, comparison: .equals(NonEmpty(PluralRange(0)))),
                    ]
                ),
                [NonEmpty(PluralRelation(operand: .compactExponent, comparison: .notEquals(NonEmpty(PluralRange(0 ... 5)))))]
            ))
            #expect(table.allRules()["fr"] == [.many: expected])
        }
    }

    @Test("Decodes both languages")
    func decodesEveryLanguage() {
        Self.withTable { table in
            #expect(Set(table.allRules().keys) == ["en", "fr"])
        }
    }
}

private extension BlobTestBuilder {
    // One relation: operand, optional modulus (0 = none), comparison sign, and its ranges.
    mutating func relation(
        _ operand: PluralOperand,
        modulus: UInt32 = 0,
        equals: Bool,
        ranges: [ClosedRange<UInt32>]
    ) {
        u8(operand.blobCode)
        u32(modulus)
        u8(equals ? 0 : 1)
        u8(UInt8(ranges.count))
        for range in ranges {
            u32(range.lowerBound)
            u32(range.upperBound)
        }
    }
}
