import POCMoney
import Testing

private let amounts = [-1000, -101, -12, -3, -1, 0, 1, 3, 12, 101, 1000,]
private let partCounts = (1...12).compactMap(PartCount.init)

@Suite("Split Tests")
struct SplitTests {

    // MARK: - Equatable

    @Test("Equatable zero-amount splits return true")
    func equatableZeroAmountSplits() {
        let a = GBP(0).distributed(into: 5)
        let b = GBP(0).distributed(into: 5)

        #expect(a == b)
    }

    @Test("Zero-amount splits into different part counts are not equal")
    func zeroAmountSplitsWithDifferentPartCounts() {
        let a = GBP(0).distributed(into: 5)
        let b = GBP(0).distributed(into: 3)

        #expect(a != b)
    }

    @Test("Equatable `even` cases return true")
    func equatableEvenCases() {
        let a = GBP(1).distributed(into: 1)
        let b = GBP(1).distributed(into: 1)

        #expect(a == b)
    }

    @Test("Non-equatable `even` cases return false")
    func nonEquatableEvenCases() {
        let a = GBP(2).distributed(into: 2)
        let b = GBP(4).distributed(into: 1)

        #expect(a != b)
    }

    @Test("`even` case is equatable to self")
    func evenCaseEquatableToSelf() {
        let a = GBP(1).distributed(into: 1)

        #expect(a == a)
    }

    @Test("Equatable `uneven` cases return true")
    func equatableUnevenCases() {
        let a = GBP(9).distributed(into: 2)
        let b = GBP(9).distributed(into: 2)

        #expect(a == b)
    }

    @Test("Non-equatable `uneven` cases return false")
    func nonEquatableUnevenCases() {
        let a = GBP(29).distributed(into: 5)
        let b = GBP(9).distributed(into: 2)

        #expect(a != b)
    }

    @Test("`uneven` case is equatable to self")
    func unevenCaseEquatableToSelf() {
        let a = GBP(9).distributed(into: 2)

        #expect(a == a)
    }

    @Test("Non-equatable cases return false")
    func nonEquatableCasesNotEqual() {
        let even = GBP(1).distributed(into: 1)
        let uneven = GBP(9).distributed(into: 2)

        #expect(even != uneven)
    }

    // MARK: - `values`

    @Test("Zero amount produces one zero share per part in `values`")
    func values_zeroAmountProducesOneZeroSharePerPart() {
        let split = GBP(0).distributed(into: 5)

        #expect(split.values == [GBP(0), GBP(0), GBP(0), GBP(0), GBP(0),])
    }

    @Test("Larger shares come before smaller shares in `values`")
    func values_largerSharesComeFirst() {
        let split = GBP(11).distributed(into: 3)

        #expect(split.values == [GBP(4), GBP(4), GBP(3),])
    }

    // MARK: - Invariants

    @Test("Share count always matches the part count", arguments: amounts, partCounts)
    func shareCountMatchesPartCount(amount: Int, parts: PartCount) {
        let split = GBP(amount).distributed(into: parts)

        #expect(split.values.count == Int(parts))
    }

    @Test("Shares always sum to the original amount", arguments: amounts, partCounts)
    func sharesSumToOriginalAmount(amount: Int, parts: PartCount) {
        let money = GBP(amount)

        let split = money.distributed(into: parts)

        #expect(split.values.reduce(.zero, +) == money)
    }

    @Test("Shares never differ by more than one minor unit", arguments: amounts, partCounts)
    func sharesDifferByAtMostOneMinorUnit(amount: Int, parts: PartCount) {
        let values = GBP(amount).distributed(into: parts).values

        guard let largest = values.max(), let smallest = values.min() else {
            Issue.record("Split produced no shares")
            return
        }

        let spread = largest - smallest

        #expect(spread == GBP(0) || spread == GBP(1))
    }

    // MARK: - Negatives

    @Test("Negative even split keeps negativity")
    func negativeEvenSplit() {
        let split = GBP(-9).distributed(into: 3)

        #expect(split.values == [GBP(-3), GBP(-3), GBP(-3),])
    }

    @Test("Negative uneven split keeps negativity")
    func negativeUnevenSplit() {
        let split = GBP(-10).distributed(into: 3)

        #expect(split.values == [GBP(-4), GBP(-3), GBP(-3),])
    }

}
