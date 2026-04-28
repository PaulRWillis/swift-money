import Testing
import SwiftMoney

@Suite("MoneyBag – Arithmetic")
struct MoneyBag_ArithmeticTests {

    // MARK: - adding (non-mutating)

    @Test("adding accumulates within same currency")
    func addingAccumulatesSameCurrency() throws {
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_100>(minorUnits: 200))
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 500))
    }

    @Test("adding keeps currencies independent")
    func addingKeepsCurrenciesIndependent() throws {
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_1>(minorUnits: 900))
        let tst100 = try #require(bag.balance(of: TST_100.self))
        let tst1 = try #require(bag.balance(of: TST_1.self))
        #expect(tst100 == Money<TST_100>(minorUnits: 300))
        #expect(tst1 == Money<TST_1>(minorUnits: 900))
    }

    @Test("adding returns a new bag, leaving the original unchanged")
    func addingIsNonMutating() {
        let original = MoneyBag()
        let modified = original.adding(Money<TST_100>(minorUnits: 500))
        #expect(original.isEmpty)
        #expect(!modified.isEmpty)
    }

    @Test("adding a zero value introduces currency with zero amount")
    func addingZeroIntroducesCurrency() throws {
        let bag = MoneyBag().adding(Money<TST_100>.zero)
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == .zero)
        #expect(!bag.isEmpty)
    }

    // MARK: - subtracting (non-mutating)

    @Test("subtracting reduces an existing entry")
    func subtractingReducesEntry() throws {
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .subtracting(Money<TST_100>(minorUnits: 200))
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 300))
    }

    @Test("subtracting produces a negative entry when currency not yet present")
    func subtractingProducesNegativeEntry() throws {
        let bag = MoneyBag().subtracting(Money<TST_100>(minorUnits: 100))
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: -100))
    }

    @Test("subtracting returns a new bag, leaving the original unchanged")
    func subtractingIsNonMutating() throws {
        let original = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let modified = original.subtracting(Money<TST_100>(minorUnits: 200))
        let originalAmount = try #require(original.balance(of: TST_100.self))
        let modifiedAmount = try #require(modified.balance(of: TST_100.self))
        #expect(originalAmount == Money<TST_100>(minorUnits: 500))
        #expect(modifiedAmount == Money<TST_100>(minorUnits: 300))
    }

    @Test("add then subtract same amount produces zero entry, bag is not empty")
    func addThenSubtractProducesZeroEntry() throws {
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .subtracting(Money<TST_100>(minorUnits: 500))
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == .zero)
        #expect(!bag.isEmpty)
        #expect(bag.balances.count == 1)
    }

    // MARK: - mutating add

    @Test("mutating add accumulates within same currency")
    func mutatingAddAccumulatesSameCurrency() throws {
        var bag = MoneyBag()
        bag.add(Money<TST_100>(minorUnits: 300))
        bag.add(Money<TST_100>(minorUnits: 200))
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 500))
    }

    @Test("mutating subtract reduces an existing entry")
    func mutatingSubtractReducesEntry() throws {
        var bag = MoneyBag()
        bag.add(Money<TST_100>(minorUnits: 500))
        bag.subtract(Money<TST_100>(minorUnits: 200))
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 300))
    }

    // MARK: - += / -=

    @Test("+= behaves identically to mutating add")
    func plusEqualsMatchesMutatingAdd() throws {
        var bag = MoneyBag()
        bag += Money<TST_100>(minorUnits: 400)
        bag += Money<TST_100>(minorUnits: 100)
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 500))
    }

    @Test("-= behaves identically to mutating subtract")
    func minusEqualsMatchesMutatingSubtract() throws {
        var bag = MoneyBag()
        bag += Money<TST_100>(minorUnits: 500)
        bag -= Money<TST_100>(minorUnits: 200)
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 300))
    }

    @Test("+= keeps currencies independent")
    func plusEqualsKeepsCurrenciesIndependent() throws {
        var bag = MoneyBag()
        bag += Money<TST_100>(minorUnits: 300)
        bag += Money<TST_1>(minorUnits: 900)
        let tst100 = try #require(bag.balance(of: TST_100.self))
        let tst1 = try #require(bag.balance(of: TST_1.self))
        #expect(tst100 == Money<TST_100>(minorUnits: 300))
        #expect(tst1 == Money<TST_1>(minorUnits: 900))
    }

    // MARK: - reduce(into:) pattern

    @Test("reduce(into:) accumulates correctly using add")
    func reduceIntoUsingAdd() throws {
        let amounts: [Money<TST_100>] = [
            Money(minorUnits: 100),
            Money(minorUnits: 200),
            Money(minorUnits: 300),
        ]
        let bag = amounts.reduce(into: MoneyBag()) { $0.add($1) }
        let total = try #require(bag.balance(of: TST_100.self))
        #expect(total == Money<TST_100>(minorUnits: 600))
    }

    // MARK: - NaN traps

    @Test("adding NaN traps")
    func addingNaNTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = MoneyBag().adding(Money<TST_100>.nan)
        }
    }

    @Test("subtracting NaN traps")
    func subtractingNaNTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = MoneyBag().subtracting(Money<TST_100>.nan)
        }
    }

    @Test("mutating add of NaN traps")
    func mutatingAddNaNTraps() async {
        await #expect(processExitsWith: .failure) {
            var bag = MoneyBag()
            bag.add(Money<TST_100>.nan)
        }
    }

    @Test("+= NaN traps")
    func plusEqualsNaNTraps() async {
        await #expect(processExitsWith: .failure) {
            var bag = MoneyBag()
            bag += Money<TST_100>.nan
        }
    }

    @Test("mutating subtract of NaN traps")
    func mutatingSubtractNaNTraps() async {
        await #expect(processExitsWith: .failure) {
            var bag = MoneyBag()
            bag.subtract(Money<TST_100>.nan)
        }
    }

    @Test("-= NaN traps")
    func minusEqualsNaNTraps() async {
        await #expect(processExitsWith: .failure) {
            var bag = MoneyBag()
            bag -= Money<TST_100>.nan
        }
    }

    // MARK: - Overflow traps

    @Test("mutating add traps on overflow")
    func mutatingAddOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            var bag = MoneyBag()
            bag.add(Money<TST_100>.max)
            bag.add(Money<TST_100>(minorUnits: 1))
        }
    }

    @Test("mutating subtract traps on overflow")
    func mutatingSubtractOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            var bag = MoneyBag()
            bag.add(Money<TST_100>.min)
            bag.subtract(Money<TST_100>.max)
        }
    }

    @Test("bag-to-bag add traps on overflow")
    func bagToBagAddOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            var bag = MoneyBag()
            bag.add(Money<TST_100>.max)
            let other = MoneyBag().adding(Money<TST_100>(minorUnits: 1))
            bag.add(other)
        }
    }

    @Test("bag-to-bag subtract traps on overflow")
    func bagToBagSubtractOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            var bag = MoneyBag()
            bag.add(Money<TST_100>.min)
            let other = MoneyBag().adding(Money<TST_100>.max)
            bag.subtract(other)
        }
    }

    // MARK: - Bag-to-bag addition

    @Test("adding another bag accumulates overlapping currencies")
    func addingBagOverlapping() throws {
        let bag1 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_1>(minorUnits: 100))
        let bag2 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 200))
        let result = bag1.adding(bag2)
        let tst100 = try #require(result.balance(of: TST_100.self))
        let tst1 = try #require(result.balance(of: TST_1.self))
        #expect(tst100 == Money<TST_100>(minorUnits: 500))
        #expect(tst1 == Money<TST_1>(minorUnits: 100))
    }

    @Test("adding another bag introduces new currencies")
    func addingBagNewCurrency() throws {
        let bag1 = MoneyBag().adding(Money<TST_100>(minorUnits: 300))
        let bag2 = MoneyBag().adding(Money<TST_1>(minorUnits: 900))
        let result = bag1.adding(bag2)
        let tst100 = try #require(result.balance(of: TST_100.self))
        let tst1 = try #require(result.balance(of: TST_1.self))
        #expect(tst100 == Money<TST_100>(minorUnits: 300))
        #expect(tst1 == Money<TST_1>(minorUnits: 900))
    }

    @Test("adding an empty bag is identity")
    func addingEmptyBagIsIdentity() throws {
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let result = bag.adding(MoneyBag())
        #expect(result == bag)
    }

    @Test("adding bag is non-mutating")
    func addingBagIsNonMutating() {
        let original = MoneyBag().adding(Money<TST_100>(minorUnits: 300))
        let other = MoneyBag().adding(Money<TST_100>(minorUnits: 200))
        let result = original.adding(other)
        #expect(original != result)
    }

    @Test("mutating add of another bag")
    func mutatingAddBag() throws {
        var bag = MoneyBag().adding(Money<TST_100>(minorUnits: 300))
        let other = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 200))
            .adding(Money<TST_1>(minorUnits: 50))
        bag.add(other)
        let tst100 = try #require(bag.balance(of: TST_100.self))
        let tst1 = try #require(bag.balance(of: TST_1.self))
        #expect(tst100 == Money<TST_100>(minorUnits: 500))
        #expect(tst1 == Money<TST_1>(minorUnits: 50))
    }

    @Test("+= with another bag")
    func plusEqualsBag() throws {
        var bag = MoneyBag().adding(Money<TST_100>(minorUnits: 300))
        bag += MoneyBag().adding(Money<TST_100>(minorUnits: 200))
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 500))
    }

    // MARK: - Bag-to-bag subtraction

    @Test("subtracting another bag reduces overlapping currencies")
    func subtractingBagOverlapping() throws {
        let bag1 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: 100))
        let bag2 = MoneyBag().adding(Money<TST_100>(minorUnits: 200))
        let result = bag1.subtracting(bag2)
        let tst100 = try #require(result.balance(of: TST_100.self))
        let tst1 = try #require(result.balance(of: TST_1.self))
        #expect(tst100 == Money<TST_100>(minorUnits: 300))
        #expect(tst1 == Money<TST_1>(minorUnits: 100))
    }

    @Test("subtracting another bag creates negative entries for new currencies")
    func subtractingBagNewCurrency() throws {
        let bag1 = MoneyBag().adding(Money<TST_100>(minorUnits: 300))
        let bag2 = MoneyBag().adding(Money<TST_1>(minorUnits: 100))
        let result = bag1.subtracting(bag2)
        let tst1 = try #require(result.balance(of: TST_1.self))
        #expect(tst1 == Money<TST_1>(minorUnits: -100))
    }

    @Test("subtracting an empty bag is identity")
    func subtractingEmptyBagIsIdentity() throws {
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let result = bag.subtracting(MoneyBag())
        #expect(result == bag)
    }

    @Test("mutating subtract of another bag")
    func mutatingSubtractBag() throws {
        var bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        bag.subtract(MoneyBag().adding(Money<TST_100>(minorUnits: 200)))
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 300))
    }

    @Test("-= with another bag")
    func minusEqualsBag() throws {
        var bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        bag -= MoneyBag().adding(Money<TST_100>(minorUnits: 200))
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 300))
    }
}
