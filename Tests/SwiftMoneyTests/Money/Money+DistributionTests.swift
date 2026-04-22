import SwiftMoney
import Testing

@Suite("Money - Distribution")
struct Money_DistributionTests {

    // MARK: - Sum invariant (parameterized)

    @Test("Sum invariant: distribution.sum == original amount",
          arguments: zip(
              [900, 1000, -1000, 999, 5, 3, 0, -900, 1, 11, -1, 2] as [Int64],
              [3,   3,    3,     1,   5, 10, 5, 3,    3, 3,  3,  3] as [DistributionParts]
          ))
    func sumInvariant(minorUnits: Int64, n: DistributionParts) {
        let amount = Money<TST_100>(minorUnits: minorUnits)
        #expect(amount.distributed(into: n).sum == amount)
    }

    // MARK: - totalCount equals n (parameterized)

    @Test("totalCount equals n",
          arguments: zip(
              [900, 1000, 0, 3, -10] as [Int64],
              [3,   3,    5, 10, 3  ] as [DistributionParts]
          ))
    func totalCountEqualsN(minorUnits: Int64, n: DistributionParts) {
        let amount = Money<TST_100>(minorUnits: minorUnits)
        #expect(amount.distributed(into: n).totalCount == n.intValue)
    }

    // MARK: - .exact case (parameterized)

    struct ExactCase: Sendable {
        let minorUnits: Int64
        let n: DistributionParts
        let expectedShare: Int64
        let expectedCount: Int
    }

    @Test("Produces .exact for divisible amounts", arguments: [
        ExactCase(minorUnits: 900,  n: 3, expectedShare: 300,  expectedCount: 3),
        ExactCase(minorUnits: 500,  n: 1, expectedShare: 500,  expectedCount: 1),
        ExactCase(minorUnits: 0,    n: 5, expectedShare: 0,    expectedCount: 5),
        ExactCase(minorUnits: 5,    n: 5, expectedShare: 1,    expectedCount: 5),
        ExactCase(minorUnits: -900, n: 3, expectedShare: -300, expectedCount: 3),
        ExactCase(minorUnits: 999,  n: 1, expectedShare: 999,  expectedCount: 1),
    ])
    func exactCase(_ c: ExactCase) {
        let d = Money<TST_100>(minorUnits: c.minorUnits).distributed(into: c.n)
        guard case let .exact(share, count) = d else {
            Issue.record("Expected .exact for \(c.minorUnits) into \(c.n), got \(d)")
            return
        }
        #expect(share == Money<TST_100>(minorUnits: c.expectedShare))
        #expect(count == c.expectedCount)
    }

    // MARK: - .uneven case (parameterized)

    struct UnevenCase: Sendable {
        let minorUnits: Int64
        let n: DistributionParts
        let expectedLarger: Int64
        let expectedLargerCount: Int
        let expectedSmaller: Int64
        let expectedSmallerCount: Int
    }

    @Test("Produces .uneven when remainder exists", arguments: [
        // Positive amounts
        UnevenCase(minorUnits: 1000, n: 3,  expectedLarger: 334, expectedLargerCount: 1, expectedSmaller: 333, expectedSmallerCount: 2),
        UnevenCase(minorUnits: 7,    n: 3,  expectedLarger: 3,   expectedLargerCount: 1, expectedSmaller: 2,   expectedSmallerCount: 2),
        UnevenCase(minorUnits: 10,   n: 3,  expectedLarger: 4,   expectedLargerCount: 1, expectedSmaller: 3,   expectedSmallerCount: 2),
        UnevenCase(minorUnits: 11,   n: 3,  expectedLarger: 4,   expectedLargerCount: 2, expectedSmaller: 3,   expectedSmallerCount: 1),
        UnevenCase(minorUnits: 1,    n: 3,  expectedLarger: 1,   expectedLargerCount: 1, expectedSmaller: 0,   expectedSmallerCount: 2),
        UnevenCase(minorUnits: 2,    n: 3,  expectedLarger: 1,   expectedLargerCount: 2, expectedSmaller: 0,   expectedSmallerCount: 1),
        UnevenCase(minorUnits: 3,    n: 10, expectedLarger: 1,   expectedLargerCount: 3, expectedSmaller: 0,   expectedSmallerCount: 7),
        // Negative amounts
        UnevenCase(minorUnits: -10,  n: 3,  expectedLarger: -4,  expectedLargerCount: 1, expectedSmaller: -3,  expectedSmallerCount: 2),
        UnevenCase(minorUnits: -1,   n: 3,  expectedLarger: -1,  expectedLargerCount: 1, expectedSmaller: 0,   expectedSmallerCount: 2),
    ])
    func unevenCase(_ c: UnevenCase) {
        let d = Money<TST_100>(minorUnits: c.minorUnits).distributed(into: c.n)
        guard case let .uneven(larger, largerCount, smaller, smallerCount) = d else {
            Issue.record("Expected .uneven for \(c.minorUnits) into \(c.n), got \(d)")
            return
        }
        #expect(larger == Money<TST_100>(minorUnits: c.expectedLarger))
        #expect(largerCount == c.expectedLargerCount)
        #expect(smaller == Money<TST_100>(minorUnits: c.expectedSmaller))
        #expect(smallerCount == c.expectedSmallerCount)
    }

    // MARK: - Precondition traps

    @Test("distributed(into:) traps on NaN")
    func distributedNaNTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Money<TST_100>.nan.distributed(into: 3)
        }
    }

}

