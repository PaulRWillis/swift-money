import SwiftMoneyCore
import Testing

@Suite("Currency packing pins")
struct CurrencyPackingPinTests {

    @Test("A currency at the largest scale is not the same as one differing only in its last code character at the smallest")
    func scaleNeverCollidesWithTheCodesLastCharacter() throws {
        let largeScale = try #require(Currency(code: "ABCDEFGH", unitScale: 10_000_000_000_000_000))
        let smallScale = try #require(Currency(code: "ABCDEFGI", unitScale: 1))

        #expect(largeScale != smallScale)
    }

    @Test(
        "Every scale reads back unchanged beside a code that fills every bit of its last character",
        arguments: [
            1 as UnitScale, 10, 100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000, 100_000_000,
            1_000_000_000, 10_000_000_000, 100_000_000_000, 1_000_000_000_000, 10_000_000_000_000,
            100_000_000_000_000, 1_000_000_000_000_000, 10_000_000_000_000_000,
            100_000_000_000_000_000, 1_000_000_000_000_000_000,
        ]
    )
    func everyScaleReadsBackBesideAFullCode(scale: UnitScale) throws {
        let currency = try #require(Currency(code: "99999994", unitScale: scale))

        #expect(currency.code == "99999994")
        #expect(currency.unitScale == scale)
    }

    @Test("A currency's mirror shows its code and unit scale")
    func mirrorShowsCodeAndUnitScale() {
        let mirror = Mirror(reflecting: Currency.gbp)
        let children = Array(mirror.children)

        #expect(mirror.displayStyle == .struct)
        #expect(children.map(\.label) == ["code", "unitScale"])
        #expect(children.first?.value as? CurrencyCode == "GBP")
        #expect(children.last?.value as? UnitScale == 100)
    }
}
