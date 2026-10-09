import SwiftMoneyCore
import Testing

// Whole-number counts spread across both signs and the range every currency here can hold.
private let wholeCounts: [Int64] = samples(
    Gen<Int64>.int(in: -1_000_000_000_000 ... 1_000_000_000_000),
    seed: PropertySeed.majorUnits,
    edges: [0, 1, -1, 15, -15, 92_233_720_368_547_758, -92_233_720_368_547_758]
)

@Suite("MoneyOf whole major units")
struct MoneyOfMajorUnitsTests {

    @Test("Fifteen pounds is fifteen hundred pence")
    func fifteenPounds() {
        #expect(GBP(majorUnits: 15) == GBP(minorUnits: 15_00))
    }

    @Test("Fifteen yen is fifteen yen, since yen have no subunit")
    func fifteenYen() {
        #expect(JPY(majorUnits: 15) == JPY(minorUnits: 15))
    }

    @Test("A negative count gives a negative amount")
    func negativeCount() {
        #expect(GBP(majorUnits: -3) == GBP(minorUnits: -3_00))
        #expect(Money(majorUnits: -3, currency: .jpy) == Money(minorUnits: -3, currency: .jpy))
    }

    @Test("A custom currency multiplies by its own scale")
    func customScale() {
        #expect(MoneyOf<Millicredits>(majorUnits: 7) == MoneyOf<Millicredits>(minorUnits: 7_000))
        #expect(
            Money(majorUnits: 7, currency: Millicredits.currency)
                == Money(minorUnits: 7_000, currency: Millicredits.currency)
        )
    }

    @Test("A runtime amount takes the named currency")
    func runtimeCurrency() {
        #expect(Money(majorUnits: 1, currency: .jpy) == Money(minorUnits: 1, currency: .jpy))
        #expect(Money(majorUnits: 1, currency: .gbp) == Money(minorUnits: 1_00, currency: .gbp))
    }

    @Test("A count too large to hold once scaled is nil")
    func tooLargeOnceScaled() {
        let count = Int64.max / 100 + 1

        #expect(GBP(majorUnits: count) == nil)
        #expect(GBP(majorUnits: Int(count)) == nil)
        #expect(GBP(majorUnits: Int32(1)) == GBP(minorUnits: 1_00))
        #expect(Money(majorUnits: count, currency: .gbp) == nil)
        #expect(Money(majorUnits: Int(count), currency: .gbp) == nil)
        #expect(Money(majorUnits: -count, currency: .gbp) == nil)
    }

    @Test("A count wider than an amount is nil, however it is scaled")
    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    func widerThanAnAmount() {
        #expect(JPY(majorUnits: Int128(Int64.max) + 1) == nil)
        #expect(JPY(majorUnits: UInt64.max) == nil)
        #expect(Money(majorUnits: Int128.min, currency: .jpy) == nil)
    }

    @Test("A wide integer type that holds a representable count still converts")
    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    func wideTypeNarrowValue() {
        #expect(GBP(majorUnits: Int128(15)) == GBP(minorUnits: 15_00))
        #expect(Money(majorUnits: UInt8(15), currency: .gbp) == Money(minorUnits: 15_00, currency: .gbp))
    }

    @Test("The largest count yen can hold converts, one more is nil")
    func yenBoundary() {
        #expect(JPY(majorUnits: Int64.max) == JPY.max)
        #expect(JPY(majorUnits: Int64.min) == JPY.min)
        #expect(JPY(majorUnits: UInt64(Int64.max) + 1) == nil)
    }

    @Test("Int, Int64 and generic counts agree, typed and runtime", arguments: wholeCounts)
    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    func overloadsAgree(_ count: Int64) {
        let fromInt64 = GBP(majorUnits: count)
        let runtimeFromInt64 = Money(majorUnits: count, currency: .gbp)

        #expect(GBP(majorUnits: Int(count)) == fromInt64)
        #expect(GBP(majorUnits: Int128(count)) == fromInt64)
        #expect(runtimeFromInt64?.minorUnits == fromInt64?.minorUnits)
        #expect(Money(majorUnits: Int(count), currency: .gbp) == runtimeFromInt64)
        #expect(Money(majorUnits: Int128(count), currency: .gbp) == runtimeFromInt64)
    }
}
