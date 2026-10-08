import SwiftMoneyCore
import Testing

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

@Suite("Sequence min and max over runtime amounts")
struct SequenceMinMaxTests {

    @Test("The least and greatest of no amounts are nil")
    func empty() throws {
        #expect(try [Money]().min() == nil)
        #expect(try [Money]().max() == nil)
    }

    @Test("The least and greatest of one amount are that amount")
    func one() throws {
        #expect(try [pounds(4_99)].min() == pounds(4_99))
        #expect(try [pounds(4_99)].max() == pounds(4_99))
    }

    @Test("The least and greatest are found first, in the middle and last")
    func anywhere() throws {
        #expect(try [pounds(1_00), pounds(5_00), pounds(3_00)].min() == pounds(1_00))
        #expect(try [pounds(5_00), pounds(1_00), pounds(3_00)].min() == pounds(1_00))
        #expect(try [pounds(5_00), pounds(3_00), pounds(1_00)].min() == pounds(1_00))
        #expect(try [pounds(9_00), pounds(5_00), pounds(3_00)].max() == pounds(9_00))
        #expect(try [pounds(5_00), pounds(9_00), pounds(3_00)].max() == pounds(9_00))
        #expect(try [pounds(5_00), pounds(3_00), pounds(9_00)].max() == pounds(9_00))
    }

    @Test("The least and greatest reach the smallest and largest amounts")
    func extremes() throws {
        let amounts = [pounds(0), pounds(Int64.max), pounds(Int64.min), pounds(-1)]

        #expect(try amounts.min() == pounds(Int64.min))
        #expect(try amounts.max() == pounds(Int64.max))
    }

    @Test("Mixed currencies throw a mismatch, naming the first amount's currency and the first that differs")
    func mixedCurrencies() {
        let amounts = [pounds(1_00), Money(minorUnits: 2_50, currency: .eur), Money(minorUnits: 300, currency: .jpy)]
        let mismatch = MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)

        #expect(throws: mismatch) { try amounts.min() }
        #expect(throws: mismatch) { try amounts.max() }
    }

    @Test("A mismatch after the least or greatest amount still throws")
    func mismatchAfterTheExtreme() {
        let amounts = [pounds(-5_00), pounds(9_00), Money(minorUnits: 1_00, currency: .eur)]
        let mismatch = MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)

        #expect(throws: mismatch) { try amounts.min() }
        #expect(throws: mismatch) { try amounts.max() }
    }

    @Test("The error stays a MoneyError, with no cast")
    func typedError() {
        let amounts = [pounds(1_00), Money(minorUnits: 2_50, currency: .eur)]

        do throws(MoneyError) {
            _ = try amounts.min()
            Issue.record("min of pounds and euros returned")
        } catch {
            #expect(error == .currencyMismatch(lhs: .gbp, rhs: .eur))
        }

        do throws(MoneyError) {
            _ = try amounts.max()
            Issue.record("max of pounds and euros returned")
        } catch {
            #expect(error == .currencyMismatch(lhs: .gbp, rhs: .eur))
        }
    }

    @Test("Finding the least and greatest reads a sequence that isn't a collection once")
    func onePass() throws {
        var reads = 0
        let source = [pounds(3_00), pounds(1_00), pounds(2_00)]
        let amounts = sequence(state: source.makeIterator()) { iterator -> Money? in
            reads += 1
            return iterator.next()
        }

        #expect(try amounts.min() == pounds(1_00))
        #expect(reads == source.count + 1)
    }

    @Test("The least and greatest of typed amounts still need no try")
    func typedUnaffected() {
        let amounts = [GBP(minorUnits: 5_00), GBP(minorUnits: 1_00), GBP(minorUnits: 9_00)]

        #expect(amounts.min() == GBP(minorUnits: 1_00))
        #expect(amounts.max() == GBP(minorUnits: 9_00))
    }
}
