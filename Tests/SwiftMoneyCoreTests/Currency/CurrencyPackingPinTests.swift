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

    @Test("A currency's dump shows its code and unit scale")
    func mirrorShowsCodeAndUnitScale() {
        let children = Array(Mirror(reflecting: Currency.gbp).children)

        #expect(children.map(\.label) == ["code", "unitScale"])
        #expect(children.first?.value as? CurrencyCode == "GBP")
        #expect(children.last?.value as? UnitScale == 100)
    }

    @Test("The widest code at the largest scale encodes big-endian")
    func widestCurrencyBytes() throws {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let widest = try #require(Currency(code: "99999999", unitScale: 1_000_000_000_000_000_000))
        let money = Money(minorUnits: 1, currency: widest)
        let expected: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 1, 0x92, 0x49, 0x24, 0x92, 0x49, 0x24, 0x12]

        #expect((0 ..< 15).map { money.bytes[$0] } == expected)
        #expect(Money(bytes: money.bytes)?.currency == widest)
    }

    @Test("A code filling its last character's bits encodes big-endian")
    func fullLastCharacterBytes() throws {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let currency = try #require(Currency(code: "99999994", unitScale: 1_000_000_000_000_000_000))
        let money = Money(minorUnits: 1, currency: currency)
        let expected: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 1, 0x92, 0x49, 0x24, 0x92, 0x49, 0x1F, 0x12]

        #expect((0 ..< 15).map { money.bytes[$0] } == expected)
        #expect(Money(bytes: money.bytes)?.currency == currency)
    }
}
