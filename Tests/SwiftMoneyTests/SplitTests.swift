import SwiftMoney
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
        case let .uneven(larger, smaller):
            let spread = larger.amount - smaller.amount

            #expect(spread == GBP(minorUnits: 1) || spread == GBP(minorUnits: -1))
        }
    }

    @Test("A part count too large to materialise still reports its count")
    func largePartCountReportsItsCount() throws {
        let parts = try #require(PartCount(exactly: Int.max))

        let split = GBP(minorUnits: 1).split(into: parts)

        #expect(split.count == parts)
    }

    @Test("A part count too large to materialise can still be iterated")
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

    @Test("For a refund, the larger group holds the larger refund")
    func negativeSplitComparesByMagnitude() {
        let split = GBP(minorUnits: -10).split(into: 3)

        switch split {
        case .even:
            Issue.record("Expected an uneven split")
        case let .uneven(larger, smaller):
            #expect(larger.count == 1)
            #expect(larger.amount == GBP(minorUnits: -4))
            #expect(smaller.count == 2)
            #expect(smaller.amount == GBP(minorUnits: -3))
        }
    }

    @Test("Negative uneven split keeps negativity")
    func negativeUnevenSplit() {
        let split = GBP(minorUnits: -10).split(into: 3)

        #expect(Array(split.amounts) == [GBP(minorUnits: -4), GBP(minorUnits: -3), GBP(minorUnits: -3),])
    }

}
