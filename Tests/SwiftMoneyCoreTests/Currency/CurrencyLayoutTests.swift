import SwiftMoneyCore
import Testing

// The sizes are a 64-bit target's. A 32-bit target lays out its word-sized fields differently.
#if _pointerBitWidth(_64)

@Suite("Currency layout")
struct CurrencyLayoutTests {

    @Test("A currency is one machine word")
    func currencyIsOneWord() {
        #expect(MemoryLayout<Currency>.size == 8)
        #expect(MemoryLayout<Currency>.stride == 8)
    }

    @Test("A runtime amount is two machine words")
    func runtimeAmountIsTwoWords() {
        #expect(MemoryLayout<Money>.size == 16)
        #expect(MemoryLayout<Money>.stride == 16)
    }

    @Test("A typed amount is one machine word")
    func typedAmountIsOneWord() {
        #expect(MemoryLayout<GBP>.size == 8)
        #expect(MemoryLayout<GBP>.stride == 8)
    }

    @Test("A weighted part of a runtime amount is three words")
    func weightedPartIsThreeWords() {
        #expect(MemoryLayout<WeightedSplit<Money>.Part>.stride == 24)
    }

    @Test("A split of a runtime amount is seven words")
    func runtimeSplitIsSevenWords() {
        #expect(MemoryLayout<Split<Money>>.stride == 56, "shrinking to 48 is welcome; update this literal")
    }

    @Test("A money error is two machine words")
    func moneyErrorIsTwoWords() {
        #expect(MemoryLayout<MoneyError>.stride == 16)
    }
}

#endif
