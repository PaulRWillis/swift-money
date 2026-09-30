import SwiftMoneyCore
import Testing

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

@Suite("MoneyOf clamping")
struct MoneyOfClampingTests {

    private let typedLimits = GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)

    @Test("A typed amount below, inside and above a closed range clamps to the lower bound, itself and the upper")
    func typedClosed() {
        #expect(GBP(minorUnits: 5_00).clamped(to: typedLimits) == GBP(minorUnits: 10_00))
        #expect(GBP(minorUnits: 100_00).clamped(to: typedLimits) == GBP(minorUnits: 100_00))
        #expect(GBP(minorUnits: 500_00).clamped(to: typedLimits) == GBP(minorUnits: 250_00))
    }

    @Test("A typed amount clamps to a range of one amount by becoming it")
    func typedEqualBounds() {
        let only = JPY(minorUnits: 7) ... JPY(minorUnits: 7)

        #expect(JPY(minorUnits: -100).clamped(to: only) == JPY(minorUnits: 7))
        #expect(JPY(minorUnits: 100).clamped(to: only) == JPY(minorUnits: 7))
    }

    @Test("A typed amount clamps to one-sided ranges")
    func typedOneSided() {
        #expect(GBP(minorUnits: 5_00).clamped(to: GBP(minorUnits: 10_00)...) == GBP(minorUnits: 10_00))
        #expect(GBP(minorUnits: 50_00).clamped(to: GBP(minorUnits: 10_00)...) == GBP(minorUnits: 50_00))
        #expect(GBP(minorUnits: 500_00).clamped(to: ...GBP(minorUnits: 250_00)) == GBP(minorUnits: 250_00))
        #expect(GBP(minorUnits: 50_00).clamped(to: ...GBP(minorUnits: 250_00)) == GBP(minorUnits: 50_00))
    }

    @Test("A runtime amount below, inside and above a closed range clamps to the lower bound, itself and the upper")
    func runtimeClosed() throws {
        let limits = try pounds(10_00)...pounds(250_00)

        #expect(try pounds(5_00).clamped(to: limits) == pounds(10_00))
        #expect(try pounds(100_00).clamped(to: limits) == pounds(100_00))
        #expect(try pounds(500_00).clamped(to: limits) == pounds(250_00))
        #expect(try pounds(5_00).clamped(to: pounds(7_00)...pounds(7_00)) == pounds(7_00))
    }

    @Test("A runtime amount clamps to one-sided ranges")
    func runtimeOneSided() throws {
        #expect(try pounds(5_00).clamped(to: pounds(10_00)...) == pounds(10_00))
        #expect(try pounds(50_00).clamped(to: pounds(10_00)...) == pounds(50_00))
        #expect(try pounds(500_00).clamped(to: ...pounds(250_00)) == pounds(250_00))
        #expect(try pounds(50_00).clamped(to: ...pounds(250_00)) == pounds(50_00))
    }

    @Test("Clamping to limits in another currency throws a mismatch, the amount's currency first")
    func runtimeMismatch() throws {
        let yen = Money(minorUnits: 500, currency: .jpy)
        let mismatch = MoneyError.currencyMismatch(lhs: .jpy, rhs: .gbp)

        #expect(throws: mismatch) { try yen.clamped(to: pounds(10_00)...pounds(250_00)) }
        #expect(throws: mismatch) { try yen.clamped(to: pounds(10_00)...) }
        #expect(throws: mismatch) { try yen.clamped(to: ...pounds(250_00)) }
    }

    @Test("A custom currency clamps in its own units")
    func customScale() throws {
        typealias Credits = MoneyOf<Millicredits>
        let runtime = Money(minorUnits: 9_999, currency: Millicredits.currency)
        let limits = try Money(minorUnits: 0, currency: Millicredits.currency)...Money(minorUnits: 1_000, currency: Millicredits.currency)

        #expect(Credits(minorUnits: 9_999).clamped(to: Credits(minorUnits: 0) ... Credits(minorUnits: 1_000)) == Credits(minorUnits: 1_000))
        #expect(try runtime.clamped(to: limits) == Money(minorUnits: 1_000, currency: Millicredits.currency))
    }
}
