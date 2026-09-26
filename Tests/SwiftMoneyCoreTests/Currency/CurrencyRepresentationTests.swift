import SwiftMoneyCore
import Testing

private enum LoyaltyPoints: CurrencyType {
    static let currency = customCurrency(code: "LTY", unitScale: 1)
}

@Suite("CurrencyRepresentation Tests")
struct CurrencyRepresentationTests {

    @Test("A fixed currency type always resolves its own currency from its code alone")
    func fixedTypeResolvesItsOwnCodeAlone() {
        #expect(LoyaltyPoints.currency(resolvedFromCodeAlone: LoyaltyPoints.currency.code) == LoyaltyPoints.currency)
    }

    @Test("A runtime currency resolves an ISO code from the code alone")
    func runtimeResolvesAnISOCodeAlone() {
        #expect(AnyCurrency.currency(resolvedFromCodeAlone: Currency.gbp.code) == .gbp)
    }

    @Test("A runtime currency cannot resolve a non-ISO code from the code alone")
    func runtimeCannotResolveANonISOCodeAlone() throws {
        let code = try #require(CurrencyCode(string: "POINTS"))

        #expect(AnyCurrency.currency(resolvedFromCodeAlone: code) == nil)
    }
}
