import POCMoney
import Testing

private let amounts = [-1000, -101, -12, -3, -1, 0, 1, 3, 12, 101, 1000,]
private let partCounts = (1...12).compactMap(PartCount.init)

@Suite("Split Tests")
struct SplitTests {

    // MARK: - Equatable

    @Test("Equatable zero-amount splits return true")
    func equatableZeroAmountSplits() {
        let a = GBP(0).split(into: 5)
        let b = GBP(0).split(into: 5)

        #expect(a == b)
    }

    @Test("Zero-amount splits into different part counts are not equal")
    func zeroAmountSplitsWithDifferentPartCounts() {
        let a = GBP(0).split(into: 5)
        let b = GBP(0).split(into: 3)

        #expect(a != b)
    }

    @Test("Equatable `even` cases return true")
    func equatableEvenCases() {
        let a = GBP(1).split(into: 1)
        let b = GBP(1).split(into: 1)

        #expect(a == b)
    }

    @Test("Non-equatable `even` cases return false")
    func nonEquatableEvenCases() {
        let a = GBP(2).split(into: 2)
        let b = GBP(4).split(into: 1)

        #expect(a != b)
    }

    @Test("`even` case is equatable to self")
    func evenCaseEquatableToSelf() {
        let a = GBP(1).split(into: 1)

        #expect(a == a)
    }

    @Test("Equatable `uneven` cases return true")
    func equatableUnevenCases() {
        let a = GBP(9).split(into: 2)
        let b = GBP(9).split(into: 2)

        #expect(a == b)
    }

    @Test("Non-equatable `uneven` cases return false")
    func nonEquatableUnevenCases() {
        let a = GBP(29).split(into: 5)
        let b = GBP(9).split(into: 2)

        #expect(a != b)
    }

    @Test("`uneven` case is equatable to self")
    func unevenCaseEquatableToSelf() {
        let a = GBP(9).split(into: 2)

        #expect(a == a)
    }

    @Test("Non-equatable cases return false")
    func nonEquatableCasesNotEqual() {
        let even = GBP(1).split(into: 1)
        let uneven = GBP(9).split(into: 2)

        #expect(even != uneven)
    }

    // MARK: - `amounts`

    @Test("Zero amount produces one zero amount per part")
    func amounts_zeroAmountProducesOneZeroAmountPerPart() {
        let split = GBP(0).split(into: 5)

        #expect(Array(split.amounts) == [GBP(0), GBP(0), GBP(0), GBP(0), GBP(0),])
    }

    @Test("Larger amounts come before smaller amounts")
    func amounts_largerAmountsComeFirst() {
        let split = GBP(11).split(into: 3)

        #expect(Array(split.amounts) == [GBP(4), GBP(4), GBP(3),])
    }

    // MARK: - Invariants

    @Test("Amount count always matches the part count", arguments: amounts, partCounts)
    func amountCountMatchesPartCount(amount: Int, parts: PartCount) {
        let split = GBP(amount).split(into: parts)

        #expect(split.count == parts)
        #expect(Array(split.amounts).count == Int(parts))
    }

    @Test("Amounts always sum to the original amount", arguments: amounts, partCounts)
    func amountsSumToOriginalAmount(amount: Int, parts: PartCount) {
        let money = GBP(amount)

        let split = money.split(into: parts)

        #expect(split.amounts.reduce(GBP.zero, +) == money)
    }

    @Test("Amounts never differ by more than one minor unit", arguments: amounts, partCounts)
    func amountsDifferByAtMostOneMinorUnit(amount: Int, parts: PartCount) {
        let split = GBP(amount).split(into: parts)

        switch split {
        case .even:
            // One amount for every part, so there is no spread to check.
            break
        case let .uneven(larger, smaller):
            let spread = larger.amount - smaller.amount

            #expect(spread == GBP(1) || spread == GBP(-1))
        }
    }

    // MARK: - Negatives

    @Test("Negative even split keeps negativity")
    func negativeEvenSplit() {
        let split = GBP(-9).split(into: 3)

        #expect(Array(split.amounts) == [GBP(-3), GBP(-3), GBP(-3),])
    }

    @Test("Negative uneven split keeps negativity")
    func negativeUnevenSplit() {
        let split = GBP(-10).split(into: 3)

        #expect(Array(split.amounts) == [GBP(-4), GBP(-3), GBP(-3),])
    }

}
