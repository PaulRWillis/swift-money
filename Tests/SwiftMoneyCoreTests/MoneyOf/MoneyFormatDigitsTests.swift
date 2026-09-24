import SwiftMoneyCore
import Testing

// The engine renders a format's own digit set in place of ASCII, at both the string and the run seams,
// while the default `.ascii` path is left exactly as it was.
@Suite("MoneyFormat non-ASCII digits")
struct MoneyFormatDigitsTests {

    static func money(_ minorUnits: Int64, _ iso: CurrencyCode) -> Money {
        guard let currency = Currency(iso: iso) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return Money(minorUnits: minorUnits, currency: currency)
    }

    static func dollar(digits: Digits) -> MoneyFormat {
        MoneyFormat(
            symbol: "$",
            pattern: MoneyFormatTests.pattern(currencyFirst: true),
            digits: digits
        )
    }

    @Test("A glyph set renders the digits, keeping ASCII separators and symbol")
    func rendersGlyphDigits() throws {
        let bengali = Self.dollar(digits: .glyphs(try #require(DigitGlyphs("০১২৩৪৫৬৭৮৯"))))

        // Grouping separator, decimal separator and symbol stay ASCII; only the digits change.
        #expect(bengali.format(Self.money(1_234_56, "USD")) == "$১,২৩৪.৫৬")
        #expect(bengali.format(Self.money(0, "USD")) == "$০.০০")
        #expect(bengali.format(Self.money(-1_234_567_89, "USD")) == "-$১,২৩৪,৫৬৭.৮৯")
    }

    @Test("An astral glyph set is sized and written correctly")
    func rendersAstralGlyphDigits() throws {
        // Adlam digits are one scalar of four UTF-8 bytes each; a mis-sized buffer would corrupt these.
        let adlam = Self.dollar(digits: .glyphs(try #require(DigitGlyphs("𞥐𞥑𞥒𞥓𞥔𞥕𞥖𞥗𞥘𞥙"))))
        #expect(adlam.format(Self.money(1_234_56, "USD")) == "$𞥑,𞥒𞥓𞥔.𞥕𞥖")
    }

    @Test("The run seam carries the glyph digits too")
    func rendersGlyphDigitsInRuns() throws {
        let bengali = Self.dollar(digits: .glyphs(try #require(DigitGlyphs("০১২৩৪৫৬৭৮৯"))))
        let text = bengali.runs(Self.money(1_234_56, "USD"), options: MoneyFormatOptions())
            .map(\.text).joined()
        #expect(text == "$১,২৩৪.৫৬")
    }

    @Test("The default ASCII path is unchanged")
    func asciiPathUnchanged() {
        let ascii = Self.dollar(digits: .ascii)
        #expect(ascii.format(Self.money(1_234_56, "USD")) == "$1,234.56")
        #expect(ascii.format(Self.money(-1_234_567_89, "USD")) == "-$1,234,567.89")
    }
}
