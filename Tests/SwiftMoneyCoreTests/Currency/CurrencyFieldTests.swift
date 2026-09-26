import SwiftMoneyCore
import Testing

@Suite("CurrencyField Tests")
struct CurrencyFieldTests {

    @Test("No code and no scale is none, whatever a stray scale value might be")
    func noCodeIsNone() {
        #expect(CurrencyField(code: nil, rawScale: nil) == .none)
        #expect(CurrencyField(code: nil, rawScale: 2) == .none)
    }

    @Test("A code alone, with no scale, is code")
    func codeAloneIsCode() throws {
        let code = try #require(CurrencyCode(string: "GBP"))

        #expect(CurrencyField(code: code, rawScale: nil) == .code(code))
    }

    @Test("A code together with a scale is custom")
    func codeWithScaleIsCustom() throws {
        let code = try #require(CurrencyCode(string: "POINTS"))

        #expect(CurrencyField(code: code, rawScale: 2) == .custom(code: code, rawScale: 2))
    }
}
