import SwiftMoney
import Testing

@Suite("Money - Addition")
struct Money_AdditionTests {

    // MARK: - Addition (Positives)

    @Test("Addition of positive values")
    func addPositive() {
        let a: Money<TST_100> = 2
        let b: Money<TST_100> = 3
        #expect(a + b == 5)
    }

    @Test("Addition of positive to negative")
    func addPositiveToNegative() {
        let neg: Money<TST_100> = -3
        let pos: Money<TST_100> = 2
        #expect(neg + pos == -1)
    }

    @Test("Addition of positive to zero")
    func addPositiveToZero() {
        let pos = Money<TST_100>(minorUnits: 3)
        #expect(.zero + pos == pos)
    }

    // MARK: Addition (Negatives)

    @Test("Addition of negative to positive")
    func addNegativeToPositive() {
        let pos: Money<TST_100> = 2
        let neg: Money<TST_100> = -3
        #expect(pos + neg == -1)
    }

    @Test("Addition of negative values")
    func addNegativeToNegative() {
        let a: Money<TST_100> = -2
        let b: Money<TST_100> = -3
        #expect(a + b == -5)
    }

    @Test("Addition of negative to zero")
    func addNegativeToZero() {
        let neg: Money<TST_100> = -1
        #expect(.zero + neg == neg)
    }

    // MARK: Addition (Zero)

    @Test("Addition of zero to positive")
    func addZeroToPositive() {
        let pos: Money<TST_100> = 3
        #expect(pos + .zero == pos)
    }

    @Test("Addition of zero to negative")
    func addZeroToNegative() {
        let neg: Money<TST_100> = -1
        #expect(neg + .zero == neg)
    }

    @Test("Addition of zero values")
    func addZeroToZero() {
        #expect(Money<TST_100>.zero + .zero == .zero)
    }

    // MARK: Addition assignment

    @Test("Addition assignment")
    func addAssign() {
        var a: Money<TST_100> = 100
        a += 5
        #expect(a == 105)
    }

    @Test("Addition assignment of negative")
    func addAssignNegative() {
        var a: Money<TST_100> = 100
        a += -5
        #expect(a == 95)
    }

    @Test("Addition assignment of two negatives")
    func addAssignTwoNegatives() {
        var a: Money<TST_100> = -50
        a += -5
        #expect(a == -55)
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

    // MARK: - NaN traps

    @Test("Addition traps on NaN lhs")
    func addNaNLhsTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Money<TST_100>.nan + Money<TST_100>(minorUnits: 1)
        }
    }

    @Test("Addition traps on NaN rhs")
    func addNaNRhsTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Money<TST_100>(minorUnits: 1) + Money<TST_100>.nan
        }
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

    @Test("Addition assignment traps on NaN rhs")
    func addAssignNaNRhsTraps() async {
        await #expect(processExitsWith: .failure) {
            var a = Money<TST_100>(minorUnits: 100)
            a += .nan
            _ = a
        }
    }

    @Test("Addition assignment traps on NaN lhs")
    func addAssignNaNLhsTraps() async {
        await #expect(processExitsWith: .failure) {
            var a = Money<TST_100>.nan
            a += Money<TST_100>(minorUnits: 1)
            _ = a
        }
    }

    @Test("Reduce traps when array contains NaN")
    func reduceTrapsOnNaN() async {
        await #expect(processExitsWith: .failure) {
            let amounts: [Money<TST_100>] = [
                Money(minorUnits: 100),
                .nan,
                Money(minorUnits: 200)
            ]
            _ = amounts.reduce(.zero, +)
        }
    }
}
