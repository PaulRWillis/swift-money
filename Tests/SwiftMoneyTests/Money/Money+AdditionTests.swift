import SwiftMoney
import Testing

@Suite("Money - Addition", .timeLimit(.minutes(1)))
struct Money_AdditionTests {

    // MARK: - Addition (Positives)

    @Test("Addition of positive values")
    func addPositive() {
        let a = Money<TST_100>(minorUnits: 2)
        let b = Money<TST_100>(minorUnits: 3)
        #expect(a + b == Money<TST_100>(minorUnits: 5))
    }

    @Test("Addition of positive to negative")
    func addPositiveToNegative() {
        let neg = Money<TST_100>(minorUnits: -3)
        let pos = Money<TST_100>(minorUnits: 2)
        #expect(neg + pos == Money<TST_100>(minorUnits: -1))
    }

    @Test("Addition of positive to zero")
    func addPositiveToZero() {
        let pos = Money<TST_100>(minorUnits: 3)
        #expect(.zero + pos == pos)
    }

    // MARK: Addition (Negatives)

    @Test("Addition of negative to positive")
    func addNegativeToPositive() {
        let pos = Money<TST_100>(minorUnits: 2)
        let neg = Money<TST_100>(minorUnits: -3)
        #expect(pos + neg == Money<TST_100>(minorUnits: -1))
    }

    @Test("Addition of negative values")
    func addNegativeToNegative() {
        let a = Money<TST_100>(minorUnits: -2)
        let b = Money<TST_100>(minorUnits: -3)
        #expect(a + b == Money<TST_100>(minorUnits: -5))
    }

    @Test("Addition of negative to zero")
    func addNegativeToZero() {
        let neg = Money<TST_100>(minorUnits: -1)
        #expect(.zero + neg == neg)
    }

    // MARK: Addition (Zero)

    @Test("Addition of zero to positive")
    func addZeroToPositive() {
        let pos = Money<TST_100>(minorUnits: 3)
        #expect(pos + .zero == pos)
    }

    @Test("Addition of zero to negative")
    func addZeroToNegative() {
        let neg = Money<TST_100>(minorUnits: -1)
        #expect(neg + .zero == neg)
    }

    @Test("Addition of zero values")
    func addZeroToZero() {
        #expect(Money<TST_100>.zero + .zero == .zero)
    }

    // MARK: Addition assignment

    @Test("Addition assignment")
    func addAssign() {
        var a = Money<TST_100>(minorUnits: 100)
        a += Money<TST_100>(minorUnits: 5)
        #expect(a == Money<TST_100>(minorUnits: 105))
    }

    @Test("Addition assignment of negative")
    func addAssignNegative() {
        var a = Money<TST_100>(minorUnits: 100)
        a += Money<TST_100>(minorUnits: -5)
        #expect(a == Money<TST_100>(minorUnits: 95))
    }

    @Test("Addition assignment of two negatives")
    func addAssignTwoNegatives() {
        var a = Money<TST_100>(minorUnits: -50)
        a += Money<TST_100>(minorUnits: -5)
        #expect(a == Money<TST_100>(minorUnits: -55))
    }

    // MARK: Addition assignment (Money RHS)

    @Test("Addition assignment with Money value")
    func addAssignMoneyValue() {
        var price = Money<TST_100>(minorUnits: 100)
        price += Money<TST_100>(minorUnits: 25)
        #expect(price == Money<TST_100>(minorUnits: 125))
    }

    @Test("Addition assignment with negative Money value")
    func addAssignNegativeMoneyValue() {
        var price = Money<TST_100>(minorUnits: 200)
        price += Money<TST_100>(minorUnits: -50)
        #expect(price == Money<TST_100>(minorUnits: 150))
    }

    // MARK: - Reduce

    @Test("Reduce empty array to zero")
    func reduceEmptyArray() {
        let amounts: [Money<TST_100>] = []
        #expect(amounts.reduce(.zero, +) == .zero)
    }

    @Test("Reduce three-element array")
    func reduceThreeElements() {
        let amounts: [Money<TST_100>] = [
            Money(minorUnits: 100),
            Money(minorUnits: 250),
            Money(minorUnits: 75)
        ]
        #expect(amounts.reduce(.zero, +) == Money<TST_100>(minorUnits: 425))
    }

    @Test("Reduce single-element array")
    func reduceSingleElement() {
        let amounts: [Money<TST_100>] = [Money(minorUnits: 42)]
        #expect(amounts.reduce(.zero, +) == Money<TST_100>(minorUnits: 42))
    }

    @Test("Reduce array with negatives")
    func reduceWithNegatives() {
        let amounts: [Money<TST_100>] = [
            Money(minorUnits: 100),
            Money(minorUnits: -30),
            Money(minorUnits: 50)
        ]
        #expect(amounts.reduce(.zero, +) == Money<TST_100>(minorUnits: 120))
    }

    // MARK: - Overflow traps

    @Test("Addition traps on overflow")
    func addOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Money<TST_100>.max + Money<TST_100>(minorUnits: 1)
        }
    }

    @Test("Addition traps on underflow")
    func addUnderflowTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Money<TST_100>.min + Money<TST_100>(minorUnits: -1)
        }
    }
}
