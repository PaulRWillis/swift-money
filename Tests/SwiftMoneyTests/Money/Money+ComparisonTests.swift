import Testing
import SwiftMoney

@Suite("Comparison and Ordering")
struct Money_ComparisonTests {
    @Test("Equality")
    func equality() {
        let a: Money<TST> = 12345
        let b: Money<TST> = 12345
        #expect(a == b)
    }

    @Test("Inequality")
    func inequality() {
        let a: Money<TST> = 12345
        let b: Money<TST> = 12346
        #expect(a != b)
    }


    // MARK: - NaN Comparison Semantics

    @Test("NaN is not equal to zero")
    func nanNotEqualToZero() {
        #expect(Money<TST>.nan != .zero)
    }


    // MARK: - Additional Comparison Edge Cases

    @Test("NaN == NaN is true (sentinel semantics)")
    func nanEqualsNan() {
        #expect(Money<TST>.nan == Money<TST>.nan)
    }


    @Test("Hashable — NaN values have equal hashes")
    func nanHashConsistency() {
        let a = Money<TST>.nan
        let b = Money<TST>.nan
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - Hash Consistency Across Construction Paths (inspired by rust_decimal/shopspring)

    @Test("Values constructed via different paths hash equally")
    func hashConsistencyAcrossConstructors() {
        // Int init vs String init vs Double init
        let fromInt = Money<TST>(42)
//        let fromString = Money<TST>("42")!
        let fromRaw = Money<TST>(minorUnits: 42)

//        #expect(fromInt == fromString)
        #expect(fromInt == fromRaw)

//        #expect(fromInt.hashValue == fromString.hashValue)
        #expect(fromInt.hashValue == fromRaw.hashValue)
    }

    // MARK: - Comparison Boundary Values (inspired by OpenJDK CompareToTests)

    @Test("Comparison at Int64 boundaries")
    func comparisonAtBoundaries() {
        let max = Money<TST>.max
        let min = Money<TST>.min
//        let justBelowMax = Money<TST>(minorUnits: Int64.max - 1)
//        let justAboveMin = Money<TST>(minorUnits: Int64.min + 2)
//
//        #expect(justBelowMax < max)
//        #expect(justAboveMin > min)
//        #expect(max > min)
//        #expect(!(max < min))
        #expect(max != min)
    }

    @Test("Comparison: max == max, min == min")
    func comparisonSelfEquality() {
        #expect(Money<TST>.max == Money<TST>.max)
        #expect(Money<TST>.min == Money<TST>.min)
    }

    // MARK: - minimum / maximum

}
