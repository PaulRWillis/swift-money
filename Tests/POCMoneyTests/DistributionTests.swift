import POCMoney
import Testing

private let amounts = [-1000, -101, -12, -3, -1, 0, 1, 3, 12, 101, 1000,]
private let partCounts = (1...12).compactMap(DistributionParts.init)

@Suite("Distribution Tests")
struct DistributionTests {

    // MARK: - Equatable

    @Test("Equatable zero-amount distributions return true")
    func equatableZeroAmountDistributions() {
        let a = GBP(0).distributed(into: 5)
        let b = GBP(0).distributed(into: 5)

        #expect(a == b)
    }

    @Test("Zero-amount distributions into different part counts are not equal")
    func zeroAmountDistributionsWithDifferentPartCounts() {
        let a = GBP(0).distributed(into: 5)
        let b = GBP(0).distributed(into: 3)

        #expect(a != b)
    }

    @Test("Equatable `equal` cases return true")
    func equatableEqualCases() {
        let a = GBP(1).distributed(into: 1)
        let b = GBP(1).distributed(into: 1)

        #expect(a == b)
    }

    @Test("Non-equatable `equal` cases return false")
    func nonEquatableEqualCases() {
        let a = GBP(2).distributed(into: 2)
        let b = GBP(4).distributed(into: 1)

        #expect(a != b)
    }

    @Test("`equal` case is equatable to self")
    func equalCaseEquatableToSelf() {
        let a = GBP(1).distributed(into: 1)

        #expect(a == a)
    }

    @Test("Equatable `unequal` cases return true")
    func equatableUnequalCases() {
        let a = GBP(9).distributed(into: 2)
        let b = GBP(9).distributed(into: 2)

        #expect(a == b)
    }

    @Test("Non-equatable `unequal` cases return false")
    func nonEquatableUnequalCases() {
        let a = GBP(29).distributed(into: 5)
        let b = GBP(9).distributed(into: 2)

        #expect(a != b)
    }

    @Test("`unequal` case is equatable to self")
    func unequalCaseEquatableToSelf() {
        let a = GBP(9).distributed(into: 2)

        #expect(a == a)
    }

    @Test("Non-equatable cases return false")
    func nonEquatableCasesNotEqual() {
        let equal = GBP(1).distributed(into: 1)
        let unequal = GBP(9).distributed(into: 2)

        #expect(equal != unequal)
    }

    // MARK: - `values`

    @Test("Zero amount produces one zero share per part in `values`")
    func values_zeroAmountProducesOneZeroSharePerPart() {
        let distribution = GBP(0).distributed(into: 5)

        #expect(distribution.values == [GBP(0), GBP(0), GBP(0), GBP(0), GBP(0),])
    }

    @Test("Larger shares come before smaller shares in `values`")
    func values_largerSharesComeFirst() {
        let distribution = GBP(11).distributed(into: 3)

        #expect(distribution.values == [GBP(4), GBP(4), GBP(3),])
    }

    // MARK: - Invariants

    @Test("Share count always matches the part count", arguments: amounts, partCounts)
    func shareCountMatchesPartCount(amount: Int, parts: DistributionParts) {
        let distribution = GBP(amount).distributed(into: parts)

        #expect(distribution.values.count == Int(parts))
    }

    @Test("Shares always sum to the original amount", arguments: amounts, partCounts)
    func sharesSumToOriginalAmount(amount: Int, parts: DistributionParts) {
        let money = GBP(amount)

        let distribution = money.distributed(into: parts)

        #expect(distribution.values.reduce(.zero, +) == money)
    }

    @Test("Shares never differ by more than one minor unit", arguments: amounts, partCounts)
    func sharesDifferByAtMostOneMinorUnit(amount: Int, parts: DistributionParts) {
        let values = GBP(amount).distributed(into: parts).values

        guard let largest = values.max(), let smallest = values.min() else {
            Issue.record("Distribution produced no shares")
            return
        }

        let spread = largest - smallest

        #expect(spread == GBP(0) || spread == GBP(1))
    }

    // MARK: - Negatives

    @Test("Negative equal distribution keeps negativity")
    func negativeEqualDistribution() {
        let distribution = GBP(-9).distributed(into: 3)

        #expect(distribution.values == [GBP(-3), GBP(-3), GBP(-3),])
    }

    @Test("Negative unequal distribution keeps negativity")
    func negativeUnequalDistribution() {
        let distribution = GBP(-10).distributed(into: 3)

        #expect(distribution.values == [GBP(-4), GBP(-3), GBP(-3),])
    }

}
