import SwiftMoney
import Testing

@Suite("Money BinaryInteger Tests")
struct MoneyBinaryIntegerTests {

    @Test("when extracting minor units from typed money should return count")
    func whenExtractingMinorUnitsFromTypedMoney_shouldReturnCount() {
        let sut = GBP(minorUnits: 4_99)

        #expect(Int(minorUnitsOf: sut) == 499)
    }

    @Test("when extracting minor units from runtime money should return count")
    func whenExtractingMinorUnitsFromRuntimeMoney_shouldReturnCount() {
        let sut = Money(minorUnits: 4_99, currency: .gbp)

        #expect(Int(minorUnitsOf: sut) == 499)
    }

    @Test("when extracting minor units from negative amount should keep sign")
    func whenExtractingMinorUnitsFromNegativeAmount_shouldKeepSign() {
        #expect(Int(minorUnitsOf: GBP(minorUnits: -4_99)) == -499)
        #expect(Int(minorUnitsOf: GBP.zero) == 0)
    }

    @Test("when extracting minor units from another currency should return same count")
    func whenExtractingMinorUnitsFromAnotherCurrency_shouldReturnSameCount() {
        #expect(Int(minorUnitsOf: JPY(minorUnits: 499)) == 499)
        #expect(Int(minorUnitsOf: GBP(minorUnits: 499)) == 499)
    }

    // These two are the storage-width tripwire. They read the bound an amount is stored in, so
    // widening `MoneyOf.MinorUnits` past `Int64` makes them fail. That failure is the signal to
    // decide what the extraction API should promise at the new width, not a test to repair.
    @Test("when extracting minor units at the extremes should return the bounds")
    func whenExtractingMinorUnitsAtExtremes_shouldReturnBounds() {
        #expect(Int64(minorUnitsOf: GBP.max) == Int64.max)
        #expect(Int64(minorUnitsOf: GBP.min) == Int64.min)
    }

    @Test("when extracting minor units into a wider integer should hold the bounds")
    func whenExtractingMinorUnitsIntoWiderInteger_shouldHoldBounds() {
        #expect(Int128(minorUnitsOf: GBP.max) == Int128(Int64.max))
        #expect(Int128(minorUnitsOf: GBP.min) == Int128(Int64.min))
    }

    @Test("when rebuilding money from extracted minor units should return original amount")
    func whenRebuildingMoneyFromExtractedMinorUnits_shouldReturnOriginalAmount() throws {
        let sut = GBP(minorUnits: -4_99)
        let count = try #require(Int(minorUnitsOf: sut))

        #expect(GBP(minorUnits: count) == sut)
    }

    @Test("when extracting minor units into a narrow integer should return nil")
    func whenExtractingMinorUnitsIntoNarrowInteger_shouldReturnNil() {
        #expect(Int8(minorUnitsOf: GBP(minorUnits: 4_99)) == nil)
    }

    @Test("when extracting a negative amount into an unsigned integer should return nil")
    func whenExtractingNegativeAmountIntoUnsignedInteger_shouldReturnNil() {
        #expect(UInt(minorUnitsOf: GBP(minorUnits: -1)) == nil)
    }
}
