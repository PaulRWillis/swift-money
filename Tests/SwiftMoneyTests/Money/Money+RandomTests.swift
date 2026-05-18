import SwiftMoney
import Testing

@Suite("Money - Random")
struct Money_RandomTests {

    // MARK: - ClosedRange

    @Test("random(in: ClosedRange) returns value within bounds")
    func closedRangeWithinBounds() {
        let lower = Money<TST_100>(minorUnits: 0)
        let upper = Money<TST_100>(minorUnits: 100)
        for _ in 0..<100 {
            let value = Money<TST_100>.random(in: lower...upper)
            #expect(value >= lower)
            #expect(value <= upper)
        }
    }

    @Test("random(in: ClosedRange) with single-element range returns that value")
    func closedRangeSingleElement() {
        let only = Money<TST_100>(minorUnits: 42)
        let value = Money<TST_100>.random(in: only...only)
        #expect(value == only)
    }

    @Test("random(in: .min ... .max) returns a value")
    func closedRangeFullFiniteDomain() {
        let value = Money<TST_100>.random(in: .min ... .max)
        #expect(value >= .min)
        #expect(value <= .max)
    }

    @Test("random(in: ClosedRange, using:) is deterministic with seeded generator")
    func closedRangeDeterministic() {
        let range = Money<TST_100>(minorUnits: 0)...Money<TST_100>(minorUnits: 1000)
        var gen1 = SeededRandomNumberGenerator(seed: 12345)
        var gen2 = SeededRandomNumberGenerator(seed: 12345)
        let a = Money<TST_100>.random(in: range, using: &gen1)
        let b = Money<TST_100>.random(in: range, using: &gen2)
        #expect(a == b)
    }

    @Test("random(in: ClosedRange) produces at least 2 distinct values over 100 calls")
    func closedRangeDistinct() {
        let range = Money<TST_100>(minorUnits: 0)...Money<TST_100>(minorUnits: 1_000_000)
        var values: Set<Int64> = []
        for _ in 0..<100 {
            values.insert(Money<TST_100>.random(in: range).minorUnits)
        }
        #expect(values.count >= 2)
    }

    // MARK: - Range

    @Test("random(in: Range) returns value within bounds")
    func rangeWithinBounds() {
        let lower = Money<TST_100>(minorUnits: 0)
        let upper = Money<TST_100>(minorUnits: 100)
        for _ in 0..<100 {
            let value = Money<TST_100>.random(in: lower..<upper)
            #expect(value >= lower)
            #expect(value < upper)
        }
    }

    @Test("random(in: Range, using:) is deterministic with seeded generator")
    func rangeDeterministic() {
        let range = Money<TST_100>(minorUnits: 0)..<Money<TST_100>(minorUnits: 1000)
        var gen1 = SeededRandomNumberGenerator(seed: 67890)
        var gen2 = SeededRandomNumberGenerator(seed: 67890)
        let a = Money<TST_100>.random(in: range, using: &gen1)
        let b = Money<TST_100>.random(in: range, using: &gen2)
        #expect(a == b)
    }

    @Test("random(in: Range) produces at least 2 distinct values over 100 calls")
    func rangeDistinct() {
        let range = Money<TST_100>(minorUnits: 0)..<Money<TST_100>(minorUnits: 1_000_000)
        var values: Set<Int64> = []
        for _ in 0..<100 {
            values.insert(Money<TST_100>.random(in: range).minorUnits)
        }
        #expect(values.count >= 2)
    }

    @Test("random(in: Range) traps on empty range")
    func rangeEmptyTraps() async {
        await #expect(processExitsWith: .failure) {
            let bound = Money<TST_100>(minorUnits: 5)
            _ = Money<TST_100>.random(in: bound..<bound)
        }
    }

}

// MARK: - Seeded Random Number Generator

/// A deterministic linear congruential generator for testing.
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
        for _ in 0..<10 { _ = next() }
    }

    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}
