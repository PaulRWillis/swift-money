import SwiftMoneyCore
import Testing

// The sizes are a 64-bit target's. A 32-bit target lays out its word-sized fields differently.
#if _pointerBitWidth(_64)

@Suite("Currency layout")
struct CurrencyLayoutTests {
    private static let bytesPerWord = 8

    private static let optionalTagBytes = 1

    private static func words(_ count: Int) -> Int {
        count * bytesPerWord
    }

    @Test("A currency is one machine word")
    func currencyIsOneWord() {
        #expect(MemoryLayout<Currency>.size == Self.words(1))
        #expect(MemoryLayout<Currency>.stride == Self.words(1))
    }

    @Test("A runtime amount is two machine words")
    func runtimeAmountIsTwoWords() {
        #expect(MemoryLayout<Money>.size == Self.words(2))
        #expect(MemoryLayout<Money>.stride == Self.words(2))
    }

    @Test("A typed amount is one machine word")
    func typedAmountIsOneWord() {
        #expect(MemoryLayout<GBP>.size == Self.words(1))
        #expect(MemoryLayout<GBP>.stride == Self.words(1))
    }

    @Test("A weighted part of a runtime amount is three words")
    func weightedPartIsThreeWords() {
        #expect(MemoryLayout<WeightedSplit<AnyCurrency>.Part>.stride == Self.words(3))
    }

    @Test("A split of a typed amount is four words")
    func typedSplitIsFourWords() {
        #expect(MemoryLayout<Split<Currencies.GBP>>.stride == Self.words(4))
    }

    @Test("A split of a runtime amount is five words")
    func runtimeSplitIsFiveWords() {
        #expect(MemoryLayout<Split<AnyCurrency>>.stride == Self.words(5))
    }

    @Test("A runtime stride iterator is four words and a tag byte, five words in an array")
    func runtimeStrideIteratorIsFourWordsAndATag() {
        #expect(MemoryLayout<Money.StrideTo.Iterator>.size == Self.words(4) + Self.optionalTagBytes)
        #expect(MemoryLayout<Money.StrideTo.Iterator>.stride == Self.words(5))
        #expect(MemoryLayout<MoneyStrideThroughIterator<AnyCurrency>>.size == Self.words(4) + Self.optionalTagBytes)
        #expect(MemoryLayout<MoneyStrideThroughIterator<AnyCurrency>>.stride == Self.words(5))
    }

    @Test("A typed stride iterator is three words and a tag byte, four words in an array")
    func typedStrideIteratorIsThreeWordsAndATag() {
        #expect(MemoryLayout<GBP.StrideTo.Iterator>.size == Self.words(3) + Self.optionalTagBytes)
        #expect(MemoryLayout<GBP.StrideTo.Iterator>.stride == Self.words(4))
        #expect(MemoryLayout<MoneyStrideThroughIterator<Currencies.GBP>>.size == Self.words(3) + Self.optionalTagBytes)
        #expect(MemoryLayout<MoneyStrideThroughIterator<Currencies.GBP>>.stride == Self.words(4))
    }

    @Test("A money error is two machine words")
    func moneyErrorIsTwoWords() {
        #expect(MemoryLayout<MoneyError>.stride == Self.words(2))
    }
}

#endif
