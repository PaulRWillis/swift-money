import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// The digits the packed tables write integers with. They have to survive being written into a Swift
// string literal and read back as bytes, so what matters is that each is printable, that none is a
// character a literal would escape, and that the two directions agree.
@Suite("Blob Digits Tests")
struct BlobDigitsTests {

    @Test("Every six-bit value round-trips through its digit")
    func valuesRoundTrip() {
        for value in UInt8(0) ... 63 {
            #expect(BlobDigits.value(of: BlobDigits.digit(for: value)) == value)
        }
    }

    // A digit outside printable ASCII would be re-encoded as a multi-byte scalar by the compiler, and a
    // quote or a backslash would end or escape the literal, so the offsets written here would not be the
    // offsets read back.
    @Test("Every digit is printable ASCII and not a literal's own punctuation")
    func digitsArePrintable() {
        for value in UInt8(0) ... 63 {
            let digit = BlobDigits.digit(for: value)
            #expect((0x21 ... 0x7E).contains(digit), "digit \(value) is \(digit)")
            #expect(digit != UInt8(ascii: "\""))
            #expect(digit != UInt8(ascii: "\\"))
        }
    }

    // Ascending digits mean a run of records sorted by a numeric key is also sorted as text, so a
    // generated table can be checked by reading it.
    @Test("The alphabet ascends with the value it stands for")
    func digitsAscend() {
        for value in UInt8(1) ... 63 {
            #expect(BlobDigits.digit(for: value) > BlobDigits.digit(for: value - 1))
        }
    }

    @Test("Each width carries its integer's full range")
    func widthsCoverTheirIntegers() {
        #expect(BlobDigits.u8 * BlobDigits.bits >= 8)
        #expect(BlobDigits.u16 * BlobDigits.bits >= 16)
        #expect(BlobDigits.u32 * BlobDigits.bits >= 32)
        #expect(BlobDigits.u64 * BlobDigits.bits >= 64)
    }

    // The blob stores only three-letter codes, so a code that is exactly three symbols has a wire form
    // and any longer code does not, which is what keeps a longer code from aliasing onto a stored one.
    @Test("A three-symbol code has a wire form; a longer one does not")
    func currencyCodeWire() throws {
        let gbp: CurrencyCode = "GBP"
        let eur: CurrencyCode = "EUR"
        let usdt: CurrencyCode = "USDT"

        let gbpWire = try #require(BlobDigits.currencyCodeWire(gbp.compactValue))
        let eurWire = try #require(BlobDigits.currencyCodeWire(eur.compactValue))

        #expect(BlobDigits.currencyCodeWire(usdt.compactValue) == nil)
        #expect(gbpWire != eurWire)
        // Order preserved, so a run stays sorted for the binary search: G is after E.
        #expect(gbpWire > eurWire)
        // The wire form fits the field's width.
        #expect(gbpWire >> (BlobDigits.currencyCode * BlobDigits.bits) == 0)
    }
}
