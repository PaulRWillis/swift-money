import CLDRCurrencyPatterns
import Testing

// Which side of the digits a CLDR pattern puts the currency on. The patterns here are the real ones the
// shipped locales use, plus the shapes that decide the edges: a negative subpattern, and text that is
// neither currency nor digits.
@Suite("Currency Side Tests")
struct CurrencySideTests {

    @Test("Reads the side the currency sits on", arguments: [
        ("¤#,##0.00", CurrencySide.leading),
        ("#,##0.00\u{00A0}¤", .trailing),
        ("¤\u{00A0}#,##0.00", .leading),
        ("#,##0.00¤", .trailing),
    ])
    func readsSide(_ pattern: String, _ expected: CurrencySide) {
        #expect(CurrencySide(pattern: pattern) == expected)
    }

    // A negative subpattern arranges the sign, not the currency, so reading it would answer a question
    // nobody asked and, where the two subpatterns differ, answer it differently.
    @Test("Only the positive subpattern is read")
    func ignoresTheNegativeSubpattern() {
        #expect(CurrencySide(pattern: "¤#,##0.00;(¤#,##0.00)") == .leading)
        #expect(CurrencySide(pattern: "#,##0.00\u{00A0}¤;-#,##0.00\u{00A0}¤") == .trailing)
    }

    @Test("Literal text between the currency and the digits does not move it")
    func literalsDoNotMoveIt() {
        #expect(CurrencySide(pattern: "¤ de #,##0.00") == .leading)
    }

    @Test("A pattern missing the currency or the digits has no side", arguments: ["#,##0.00", "¤", ""])
    func incompletePatterns(_ pattern: String) {
        #expect(CurrencySide(pattern: pattern) == nil)
    }
}
