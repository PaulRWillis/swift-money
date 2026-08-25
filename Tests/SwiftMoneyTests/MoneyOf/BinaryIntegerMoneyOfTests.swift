import SwiftMoney
import Testing

@Suite("BinaryInteger From MoneyOf Tests")
struct BinaryIntegerMoneyOfTests {

    @Test("when extracting minor units from typed money should return count")
    func whenExtractingMinorUnitsFromTypedMoney_shouldReturnCount() {
        let sut = GBP(minorUnits: 4_99)

        #expect(Int(minorUnits: sut) == 499)
    }

    @Test("when extracting minor units from runtime money should return count")
    func whenExtractingMinorUnitsFromRuntimeMoney_shouldReturnCount() {
        let sut = Money(minorUnits: 4_99, currency: .gbp)

        #expect(Int(minorUnits: sut) == 499)
    }

    @Test("when extracting minor units from negative amount should keep sign")
    func whenExtractingMinorUnitsFromNegativeAmount_shouldKeepSign() {
        #expect(Int(minorUnits: GBP(minorUnits: -4_99)) == -499)
        #expect(Int(minorUnits: GBP.zero) == 0)
    }

    @Test("when extracting minor units from another currency should return same count")
    func whenExtractingMinorUnitsFromAnotherCurrency_shouldReturnSameCount() {
        #expect(Int(minorUnits: JPY(minorUnits: 499)) == 499)
        #expect(Int(minorUnits: GBP(minorUnits: 499)) == 499)
    }

    @Test("when extracting minor units at the extremes should return the bounds")
    func whenExtractingMinorUnitsAtExtremes_shouldReturnBounds() {
        #expect(Int64(minorUnits: GBP.max) == Int64.max)
        #expect(Int64(minorUnits: GBP.min) == Int64.min)
    }

    @Test("when extracting minor units into a wider integer should hold the bounds")
    func whenExtractingMinorUnitsIntoWiderInteger_shouldHoldBounds() {
        #expect(Int128(minorUnits: GBP.max) == Int128(Int64.max))
        #expect(Int128(minorUnits: GBP.min) == Int128(Int64.min))
    }

    @Test("when rebuilding money from extracted minor units should return original amount")
    func whenRebuildingMoneyFromExtractedMinorUnits_shouldReturnOriginalAmount() {
        let sut = GBP(minorUnits: -4_99)

        #expect(GBP(minorUnits: Int(minorUnits: sut)) == sut)
    }
}
