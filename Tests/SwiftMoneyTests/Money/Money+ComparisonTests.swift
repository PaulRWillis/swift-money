import Testing
import SwiftMoney

@Suite("Money - Comparison and Ordering")
struct Money_ComparisonTests {
    
    @Test("Equality")
    func equality() {
        let a: Money<TST_100> = 12345
        let b: Money<TST_100> = 12345
        #expect(a == b)
    }

    @Test("Inequality")
    func inequality() {
        let a: Money<TST_100> = 12345
        let b: Money<TST_100> = 12346
        #expect(a != b)
    }

    @Test("Less than")
    func lessThan() {
        let a: Money<TST_100> = 10
        let b: Money<TST_100> = 20
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test("Less than or equal")
    func lessThanOrEqual() {
        let a: Money<TST_100> = 10
        let b: Money<TST_100> = 10
        #expect(a <= b)
    }

    @Test("Greater than")
    func greaterThan() {
        let a: Money<TST_100> = 20
        let b: Money<TST_100> = 10
        #expect(a > b)
    }

    @Test("Negative comparison")
    func negativeComparison() {
        let a: Money<TST_100> = -5
        let b: Money<TST_100> = 5
        #expect(a < b)
    }

    @Test("Zero comparison")
    func zeroComparison() {
        let a: Money<TST_100> = 0
        let b = Money<TST_100>.zero
        #expect(a == b)
        #expect(!(a < b))
        #expect(!(a > b))
    }

    @Test("Sorting")
    func sorting() {
        var values: [Money<TST_100>] = [5, 1, 3, 2, 4]
        values.sort()
        let expected: [Money<TST_100>] = [1, 2, 3, 4, 5]
        #expect(values == expected)
    }

    @Test("Sorting with negatives")
    func sortingWithNegatives() {
        var values: [Money<TST_100>] = [3, -1, 0, -3, 1]
        values.sort()
        let expected: [Money<TST_100>] = [-3, -1, 0, 1, 3]
        #expect(values == expected)
    }

    @Test("Hashable — equal values have equal hashes")
    func hashableConsistency() {
        let a: Money<TST_100> = 12345
        let b: Money<TST_100> = 12345
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Hashable — use in Set")
    func hashableInSet() {
        let values: Set<Money<TST_100>> = [1, 2, 3, 2, 1]
        #expect(values.count == 3)
    }

    @Test("Hashable — use as Dictionary key")
    func hashableAsDictKey() {
        let price: Money<TST_100> = 9995
        var dict: [Money<TST_100>: String] = [:]
        dict[price] = "test"
        #expect(dict[price] == "test")
    }

    // MARK: - NaN Comparison Semantics

    @Test("NaN is not equal to zero")
    func nanNotEqualToZero() {
        #expect(Money<TST_100>.nan != .zero)
    }

    @Test("NaN sorts below everything")
    func nanSortsBelowAll() {
        let nan = Money<TST_100>.nan
        let neg: Money<TST_100> = -99999
        #expect(nan < neg)
        #expect(!(neg < nan))
    }

    // MARK: - Additional Comparison Edge Cases

    @Test("NaN == NaN is true (sentinel semantics)")
    func nanEqualsNan() {
        #expect(Money<TST_100>.nan == Money<TST_100>.nan)
    }

    @Test("min < max")
    func minLessThanMax() {
        #expect(Money<TST_100>.min < Money<TST_100>.max)
    }

    @Test("Hashable — NaN values have equal hashes")
    func nanHashConsistency() {
        let a = Money<TST_100>.nan
        let b = Money<TST_100>.nan
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - Hash Consistency Across Construction Paths (inspired by rust_decimal/shopspring)

    #warning("Uncomment string init once ParseableFormatStyle is added")
    @Test("Values constructed via different paths hash equally")
    func hashConsistencyAcrossConstructors() {
        let fromInt = Money<TST_100>(42)
//        let fromString = Money<TST>("42")!
        let fromRaw = Money<TST_100>(minorUnits: 42)

//        #expect(fromInt == fromString)
        #expect(fromInt == fromRaw)

//        #expect(fromInt.hashValue == fromString.hashValue)
        #expect(fromInt.hashValue == fromRaw.hashValue)
    }

    // MARK: - Comparison Boundary Values (inspired by OpenJDK CompareToTests)

    @Test("Comparison at Int64 boundaries")
    func comparisonAtBoundaries() {
        let max = Money<TST_100>.max
        let min = Money<TST_100>.min
        let justBelowMax = Money<TST_100>(minorUnits: Int64.max - 1)
        let justAboveMin = Money<TST_100>(minorUnits: Int64.min + 2)

        #expect(justBelowMax < max)
        #expect(justAboveMin > min)
        #expect(max > min)
        #expect(!(max < min))
        #expect(max != min)
    }

    @Test("Comparison: max == max, min == min")
    func comparisonSelfEquality() {
        #expect(Money<TST_100>.max == Money<TST_100>.max)
        #expect(Money<TST_100>.min == Money<TST_100>.min)
    }

    // MARK: - minimum / maximum

    @Test("minimum returns lesser value")
    func minimumBasic() {
        let a: Money<TST_100> = 3
        let b: Money<TST_100> = 5
        #expect(Money<TST_100>.minimum(a, b) == a)
        #expect(Money<TST_100>.minimum(b, a) == a)
    }

    @Test("maximum returns greater value")
    func maximumBasic() {
        let a: Money<TST_100> = 3
        let b: Money<TST_100> = 5
        #expect(Money<TST_100>.maximum(a, b) == b)
        #expect(Money<TST_100>.maximum(b, a) == b)
    }

    @Test("minimum/maximum with equal values")
    func minimumMaximumEqual() {
        let a: Money<TST_100> = 42
        let b: Money<TST_100> = 42
        #expect(Money<TST_100>.minimum(a, b) == a)
        #expect(Money<TST_100>.maximum(a, b) == a)
    }

    @Test("minimum/maximum with negative values")
    func minimumMaximumNegative() {
        let a: Money<TST_100> = -10
        let b: Money<TST_100> = 5
        #expect(Money<TST_100>.minimum(a, b) == a)
        #expect(Money<TST_100>.maximum(a, b) == b)
    }

    @Test("minimum/maximum with .min and .max")
    func minimumMaximumBoundaries() {
        #expect(Money<TST_100>.minimum(.min, .max) == .min)
        #expect(Money<TST_100>.maximum(.min, .max) == .max)
    }

    @Test("minimum/maximum with zero")
    func minimumMaximumZero() {
        let pos: Money<TST_100> = 1
        let neg: Money<TST_100> = -1
        #expect(Money<TST_100>.minimum(.zero, pos) == .zero)
        #expect(Money<TST_100>.maximum(.zero, neg) == .zero)
    }
}
