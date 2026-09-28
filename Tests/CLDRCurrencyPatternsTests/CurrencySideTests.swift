import CLDRCurrencyPatterns
import Testing

// The patterns here are the real ones the shipped locales use, plus the shapes that decide the edges.
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

    // "US$" and "F CFA" trailing matches khq's real data: its standard pattern trails ("#,##0.00¤"),
    // so the boundary is the symbol's *first* scalar — 'U' and 'F', both letters.
    @Test("A letter touching the number classifies as letter-adjacent", arguments: [
        ("US$", CurrencySide.trailing),
        ("F CFA", .trailing),
        ("kr", .leading),
    ])
    func letterAdjacentSymbols(_ symbol: String, _ side: CurrencySide) {
        #expect(side.letterTouchesTheNumber(in: symbol))
    }

    @Test("A glyph beside the number is not letter-adjacent", arguments: [
        ("€", CurrencySide.trailing),
        ("£", .leading),
        ("$", .leading),
    ])
    func glyphSymbols(_ symbol: String, _ side: CurrencySide) {
        #expect(!side.letterTouchesTheNumber(in: symbol))
    }

    @Test("An empty symbol touches no letter")
    func emptySymbolIsNotLetterAdjacent() {
        #expect(!CurrencySide.leading.letterTouchesTheNumber(in: ""))
    }
}
