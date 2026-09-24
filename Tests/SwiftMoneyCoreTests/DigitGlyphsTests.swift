import SwiftMoneyCore
import Testing

@Suite("DigitGlyphs")
struct DigitGlyphsTests {

    @Test("Ten glyphs of a uniform width are accepted, with the width reported")
    func acceptsTenUniformGlyphs() throws {
        let bengali = try #require(DigitGlyphs("০১২৩৪৫৬৭৮৯"))
        #expect(bengali.bytesPerDigit == 3)
        #expect(bengali[0] == "০")
        #expect(bengali[9] == "৯")

        // An astral set: one scalar each, four UTF-8 bytes each.
        let adlam = try #require(DigitGlyphs("𞥐𞥑𞥒𞥓𞥔𞥕𞥖𞥗𞥘𞥙"))
        #expect(adlam.bytesPerDigit == 4)
        #expect(adlam[7] == "𞥗")

        // The ASCII digits are a valid set too, one byte each.
        let ascii = try #require(DigitGlyphs("0123456789"))
        #expect(ascii.bytesPerDigit == 1)
    }

    @Test("A set that is not exactly ten glyphs is rejected")
    func rejectsWrongCount() {
        #expect(DigitGlyphs("০১২৩৪৫৬৭৮") == nil)       // nine
        #expect(DigitGlyphs("০১২৩৪৫৬৭৮৯০") == nil)      // eleven
        #expect(DigitGlyphs("") == nil)
    }

    @Test("A set whose glyphs differ in width is rejected")
    func rejectsMixedWidth() {
        // Nine Bengali glyphs (3 bytes) and one ASCII digit (1 byte).
        #expect(DigitGlyphs("০১২৩৪৫৬৭৮9") == nil)
    }
}
