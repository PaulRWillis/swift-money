import SwiftMoneyCore
import Testing

private let amounts = [-1000, -101, -12, -3, -1, 0, 1, 3, 12, 101, 1000,]
private let partCounts = (1...12).compactMap(PartCount.init(exactly:))

@Suite("Split Tests")
struct SplitTests {

    @Test("Equatable zero-amount splits return true")
    func equatableZeroAmountSplits() {
        let a = GBP(minorUnits: 0).split(into: 5)
        let b = GBP(minorUnits: 0).split(into: 5)

        #expect(a == b)
    }

    @Test("Zero-amount splits into different part counts are not equal")
    func zeroAmountSplitsWithDifferentPartCounts() {
        let a = GBP(minorUnits: 0).split(into: 5)
        let b = GBP(minorUnits: 0).split(into: 3)

        #expect(a != b)
    }

    @Test("Equatable `even` cases return true")
    func equatableEvenCases() {
        let a = GBP(minorUnits: 1).split(into: 1)
        let b = GBP(minorUnits: 1).split(into: 1)

        #expect(a == b)
    }

    @Test("Non-equatable `even` cases return false")
    func nonEquatableEvenCases() {
        let a = GBP(minorUnits: 2).split(into: 2)
        let b = GBP(minorUnits: 4).split(into: 1)

        #expect(a != b)
    }

    @Test("`even` case is equatable to self")
    func evenCaseEquatableToSelf() {
        let a = GBP(minorUnits: 1).split(into: 1)

        #expect(a == a)
    }

    @Test("Equatable `uneven` cases return true")
    func equatableUnevenCases() {
        let a = GBP(minorUnits: 9).split(into: 2)
        let b = GBP(minorUnits: 9).split(into: 2)

        #expect(a == b)
    }

    @Test("Non-equatable `uneven` cases return false")
    func nonEquatableUnevenCases() {
        let a = GBP(minorUnits: 29).split(into: 5)
        let b = GBP(minorUnits: 9).split(into: 2)

        #expect(a != b)
    }

    @Test("`uneven` case is equatable to self")
    func unevenCaseEquatableToSelf() {
        let a = GBP(minorUnits: 9).split(into: 2)

        #expect(a == a)
    }

    @Test("Non-equatable cases return false")
    func nonEquatableCasesNotEqual() {
        let even = GBP(minorUnits: 1).split(into: 1)
        let uneven = GBP(minorUnits: 9).split(into: 2)

        #expect(even != uneven)
    }

    @Test("Zero amount produces one zero amount per part")
    func amounts_zeroAmountProducesOneZeroAmountPerPart() {
        let split = GBP(minorUnits: 0).split(into: 5)

        #expect(Array(split.amounts) == [GBP(minorUnits: 0), GBP(minorUnits: 0), GBP(minorUnits: 0), GBP(minorUnits: 0), GBP(minorUnits: 0),])
    }

    @Test("Larger amounts come before smaller amounts")
    func amounts_largerAmountsComeFirst() {
        let split = GBP(minorUnits: 11).split(into: 3)

        #expect(Array(split.amounts) == [GBP(minorUnits: 4), GBP(minorUnits: 4), GBP(minorUnits: 3),])
    }

    @Test("Amount count always matches the part count", arguments: amounts, partCounts)
    func amountCountMatchesPartCount(amount: Int, parts: PartCount) {
        let split = GBP(minorUnits: amount).split(into: parts)

        #expect(split.count == parts)
        #expect(Array(split.amounts).count == Int(parts))
    }

    @Test("Amounts always sum to the original amount", arguments: amounts, partCounts)
    func amountsSumToOriginalAmount(amount: Int, parts: PartCount) {
        let money = GBP(minorUnits: amount)

        let split = money.split(into: parts)

        #expect(split.amounts.reduce(GBP.zero, +) == money)
    }

    @Test("Amounts never differ by more than one minor unit", arguments: amounts, partCounts)
    func amountsDifferByAtMostOneMinorUnit(amount: Int, parts: PartCount) {
        let split = GBP(minorUnits: amount).split(into: parts)

        switch split {
        case .even:
            // One amount for every part, so there is no spread to check.
            break
        case let .uneven(uneven):
            let spread = uneven.largerAmount - uneven.smallerAmount

            #expect(spread == GBP(minorUnits: 1) || spread == GBP(minorUnits: -1))
        }
    }

    @Test("A part count too large to materialize still reports its count")
    func largePartCountReportsItsCount() throws {
        let parts = try #require(PartCount(exactly: Int.max))

        let split = GBP(minorUnits: 1).split(into: parts)

        #expect(split.count == parts)
    }

    @Test("A part count too large to materialize can still be iterated")
    func largePartCountCanBeIterated() throws {
        let parts = try #require(PartCount(exactly: Int.max))

        let split = GBP(minorUnits: 1).split(into: parts)

        var iterator = split.amounts.makeIterator()

        #expect(iterator.next() == GBP(minorUnits: 1))
        #expect(iterator.next() == GBP(minorUnits: 0))
    }

    @Test("Negative even split keeps negativity")
    func negativeEvenSplit() {
        let split = GBP(minorUnits: -9).split(into: 3)

        #expect(Array(split.amounts) == [GBP(minorUnits: -3), GBP(minorUnits: -3), GBP(minorUnits: -3),])
    }

    @Test("For a refund, the larger amount is the more negative one")
    func negativeSplitComparesByMagnitude() {
        let split = GBP(minorUnits: -10).split(into: 3)

        switch split {
        case .even:
            Issue.record("Expected an uneven split")
        case let .uneven(uneven):
            #expect(uneven.largerCount == 1)
            #expect(uneven.largerAmount == GBP(minorUnits: -4))
            #expect(uneven.smallerCount == 2)
            #expect(uneven.smallerAmount == GBP(minorUnits: -3))
            #expect(uneven.count == 3)
        }
    }

    @Test("Negative uneven split keeps negativity")
    func negativeUnevenSplit() {
        let split = GBP(minorUnits: -10).split(into: 3)

        #expect(Array(split.amounts) == [GBP(minorUnits: -4), GBP(minorUnits: -3), GBP(minorUnits: -3),])
    }

    @Test("A zero split into the most parts reports that count")
    func zeroIntoMostParts() throws {
        let maxParts = try #require(PartCount(exactly: .max))

        let split = GBP(minorUnits: 0).split(into: maxParts)

        #expect(split.count == maxParts)
        guard case let .even(even) = split else {
            Issue.record("Expected an even split")
            return
        }
        #expect(even.count == maxParts)
        #expect(even.amount == GBP(minorUnits: 0))
    }

    @Test("A one-unit refund into the most parts has one part of -1 and the rest zero")
    func refundIntoMostParts() throws {
        let maxParts = try #require(PartCount(exactly: .max))
        let smallerCount = try #require(PartCount(exactly: .max - 1))

        let split = GBP(minorUnits: -1).split(into: maxParts)

        #expect(split.count == maxParts)
        var iterator = split.amounts.makeIterator()
        #expect(iterator.next() == GBP(minorUnits: -1))
        #expect(iterator.next() == GBP(minorUnits: 0))
        guard case let .uneven(uneven) = split else {
            Issue.record("Expected an uneven split")
            return
        }
        #expect(uneven.largerCount == 1)
        #expect(uneven.largerAmount == GBP(minorUnits: -1))
        #expect(uneven.smallerCount == smallerCount)
        #expect(uneven.smallerAmount == GBP(minorUnits: 0))
        #expect(uneven.count == maxParts)
    }

    #if _pointerBitWidth(_64)
    @Test("The smallest amount into the most parts has one part of -2 and the rest -1")
    func smallestAmountIntoMostParts() throws {
        let maxParts = try #require(PartCount(exactly: .max))
        let smallerCount = try #require(PartCount(exactly: .max - 1))

        let split = GBP.min.split(into: maxParts)

        #expect(split.count == maxParts)
        var iterator = split.amounts.makeIterator()
        #expect(iterator.next() == GBP(minorUnits: -2))
        #expect(iterator.next() == GBP(minorUnits: -1))
        guard case let .uneven(uneven) = split else {
            Issue.record("Expected an uneven split")
            return
        }
        #expect(uneven.largerCount == 1)
        #expect(uneven.largerAmount == GBP(minorUnits: -2))
        #expect(uneven.smallerCount == smallerCount)
        #expect(uneven.smallerAmount == GBP(minorUnits: -1))
        #expect(Int(uneven.largerCount) + Int(uneven.smallerCount) == Int.max)
        #expect(uneven.count == maxParts)
    }

    @Test("The largest amount into the most parts is even")
    func largestAmountIntoMostPartsIsEven() throws {
        let maxParts = try #require(PartCount(exactly: .max))

        let split = GBP.max.split(into: maxParts)

        guard case let .even(even) = split else {
            Issue.record("Expected an even split")
            return
        }
        #expect(even.count == maxParts)
        #expect(even.amount == GBP(minorUnits: 1))
    }
    #endif

    @Test("The smallest amount into three")
    func smallestAmountIntoThree() {
        let split = GBP.min.split(into: 3)

        #expect(split.amounts.reduce(GBP.zero, +) == GBP.min)
        guard case let .uneven(uneven) = split else {
            Issue.record("Expected an uneven split")
            return
        }
        #expect(uneven.largerCount == 2)
        #expect(uneven.largerAmount == GBP(minorUnits: -3_074_457_345_618_258_603))
        #expect(uneven.smallerCount == 1)
        #expect(uneven.smallerAmount == GBP(minorUnits: -3_074_457_345_618_258_602))
    }

    @Test("The largest amount into three")
    func largestAmountIntoThree() {
        let split = GBP.max.split(into: 3)

        #expect(split.amounts.reduce(GBP.zero, +) == GBP.max)
        guard case let .uneven(uneven) = split else {
            Issue.record("Expected an uneven split")
            return
        }
        #expect(uneven.largerCount == 1)
        #expect(uneven.largerAmount == GBP(minorUnits: 3_074_457_345_618_258_603))
        #expect(uneven.smallerCount == 2)
        #expect(uneven.smallerAmount == GBP(minorUnits: 3_074_457_345_618_258_602))
    }

    @Test("An uneven refund reports its part count")
    func unevenRefundReportsItsPartCount() {
        #expect(GBP(minorUnits: -10).split(into: 3).count == 3)
    }

    @Test("A typed split names its currency")
    func typedSplitNamesItsCurrency() {
        let split: Split<Currencies.GBP> = GBP(minorUnits: 100_00).split(into: 3)

        #expect(Array(split.amounts) == [
            GBP(minorUnits: 33_34), GBP(minorUnits: 33_33), GBP(minorUnits: 33_33),
        ])
    }

    @Test("An uneven split holds an UnevenSplit")
    func unevenSplitHoldsAnUnevenSplit() {
        let split = GBP(minorUnits: 11).split(into: 3)

        guard case let .uneven(uneven) = split else {
            Issue.record("Expected an uneven split")
            return
        }
        let _: UnevenSplit<Currencies.GBP> = uneven
    }

    @Test("An even split holds an EvenSplit")
    func evenSplitHoldsAnEvenSplit() {
        let split = GBP(minorUnits: 12).split(into: 3)

        guard case let .even(even) = split else {
            Issue.record("Expected an even split")
            return
        }
        let _: EvenSplit<Currencies.GBP> = even
    }

    @Test("Equal splits hash equally")
    func equalSplitsHashEqually() {
        #expect(
            GBP(minorUnits: 11).split(into: 3).hashValue
                == GBP(minorUnits: 11).split(into: 3).hashValue
        )
        #expect(
            GBP(minorUnits: 12).split(into: 3).hashValue
                == GBP(minorUnits: 12).split(into: 3).hashValue
        )
    }

    @Test("A set holds one copy of equal splits")
    func setHoldsOneCopyOfEqualSplits() {
        let splits = Set([
            GBP(minorUnits: 11).split(into: 3),
            GBP(minorUnits: 11).split(into: 3),
            GBP(minorUnits: 0).split(into: 3),
        ])

        #expect(splits.count == 2)
    }

    @Test("Splits of the same minor units in two runtime currencies are distinct")
    func splitsInDifferentRuntimeCurrenciesAreDistinct() {
        let gbpSplit: Split<AnyCurrency> = Money(minorUnits: 100, currency: .gbp).split(into: 3)
        let usdSplit: Split<AnyCurrency> = Money(minorUnits: 100, currency: .usd).split(into: 3)

        #expect(gbpSplit != usdSplit)
        #expect(Set([gbpSplit, usdSplit]).count == 2)
    }

    @Test("Equal payloads hash equally")
    func equalPayloadsHashEqually() {
        guard
            case let .even(even) = GBP(minorUnits: 12).split(into: 3),
            case let .even(sameEven) = GBP(minorUnits: 12).split(into: 3)
        else {
            Issue.record("Expected even splits")
            return
        }
        guard
            case let .uneven(uneven) = GBP(minorUnits: 11).split(into: 3),
            case let .uneven(sameUneven) = GBP(minorUnits: 11).split(into: 3)
        else {
            Issue.record("Expected uneven splits")
            return
        }

        #expect(even.hashValue == sameEven.hashValue)
        #expect(uneven.hashValue == sameUneven.hashValue)
    }

}
