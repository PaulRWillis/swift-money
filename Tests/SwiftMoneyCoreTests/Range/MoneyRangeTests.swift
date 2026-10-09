import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

private func euros(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .eur)
}

private typealias BuildError = MoneyRangeParsingError<AnyCurrency>

@Suite("MoneyRange")
struct MoneyRangeTests {

    @Test("Bounds in one currency build a range holding them")
    func buildsFromSameCurrency() throws {
        let range = try pounds(10_00)..<pounds(250_00)

        #expect(range.lowerBound == pounds(10_00))
        #expect(range.upperBound == pounds(250_00))
        #expect(range.currency == .gbp)
        #expect(range.isEmpty == false)
    }

    @Test("Bounds in two currencies throw a mismatch with the upper bound's currency")
    func mismatchThrows() {
        #expect(throws: BuildError.currencyMismatch(.eur)) {
            try pounds(10_00)..<euros(250_00)
        }
    }

    @Test("A switch over a build error binds the upper bound's currency")
    func mismatchBindsCurrency() {
        do throws(BuildError) {
            _ = try pounds(10_00)..<euros(250_00)
            Issue.record("Expected a mismatch to throw")
        } catch {
            switch error {
            case .invertedBounds:
                Issue.record("Expected a mismatch, not inverted bounds")
            case let .currencyMismatch(currency):
                #expect(currency == .eur)
            }
        }
    }

    @Test("Inverted bounds throw invertedBounds with both bounds as given")
    func invertedThrows() {
        #expect(throws: BuildError.invertedBounds(lowerBound: pounds(250_00), upperBound: pounds(10_00))) {
            try pounds(250_00)..<pounds(10_00)
        }
    }

    @Test("Inverted bounds in two currencies report the mismatch")
    func mismatchBeforeInverted() {
        #expect(throws: BuildError.currencyMismatch(.eur)) {
            try pounds(250_00)..<euros(10_00)
        }
    }

    @Test("Equal bounds build an empty range")
    func equalBounds() throws {
        let range = try pounds(5_00)..<pounds(5_00)

        #expect(range.isEmpty)
        #expect(try range.contains(pounds(5_00)) == false)
    }

    @Test("init(checkedBounds:) builds and throws as the operator does")
    func checkedBoundsEqualsOperator() throws {
        let checked = try MoneyRange(checkedBounds: (lower: pounds(1_00), upper: pounds(2_00)))

        #expect(try checked == pounds(1_00)..<pounds(2_00))
        #expect(throws: BuildError.currencyMismatch(.gbp)) {
            try MoneyRange(checkedBounds: (lower: euros(1_00), upper: pounds(2_00)))
        }
        #expect(throws: BuildError.invertedBounds(lowerBound: pounds(2_00), upperBound: pounds(1_00))) {
            try MoneyRange(checkedBounds: (lower: pounds(2_00), upper: pounds(1_00)))
        }
    }

    @Test("A typed range becomes the runtime range the operator builds")
    func typedToRuntime() throws {
        let typed = GBP(minorUnits: 10_00) ..< GBP(minorUnits: 250_00)

        #expect(try MoneyRange(typed) == pounds(10_00)..<pounds(250_00))
        #expect(MoneyRange(JPY(minorUnits: 1) ..< JPY(minorUnits: 9)).currency == .jpy)
    }

    @Test("A closed range becomes the half-open range ending one minor unit higher")
    func fromClosed() throws {
        let closed = try pounds(1_00)...pounds(1_99)

        #expect(try MoneyRange(closed) == pounds(1_00)..<pounds(2_00))
        #expect(MoneyRange(closed)?.currency == .gbp)
    }

    @Test("A closed range ending at the largest amount has no half-open equivalent")
    func fromClosedAtMaximum() throws {
        let closed = try pounds(0)...pounds(Int64.max)

        #expect(MoneyRange(closed) == nil)
    }

    @Test("Closed ranges at the extremes of Int64 convert while the upper bound has room above it")
    func fromClosedAtExtremes() throws {
        let lowest = pounds(Int64.min)
        let highest = pounds(Int64.max)

        #expect(try MoneyRange(lowest...lowest) == lowest..<pounds(Int64.min + 1))
        #expect(try MoneyRange(lowest...pounds(Int64.max - 1)) == lowest..<highest)
        #expect(MoneyRange(try highest...highest) == nil)
    }

    @Test("Contains its lower bound but not its upper")
    func containsLowerNotUpper() throws {
        let range = try pounds(10_00)..<pounds(250_00)

        #expect(try range.contains(pounds(10_00)))
        #expect(try range.contains(pounds(249_99)))
        #expect(try range.contains(pounds(250_00)) == false)
        #expect(try range.contains(pounds(9_99)) == false)
    }

    @Test("Asking about an amount in another currency throws a mismatch, range's currency first")
    func containsMismatch() throws {
        let range = try pounds(10_00)..<pounds(250_00)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try range.contains(euros(100_00))
        }
    }

    @Test("Contains a nested half-open range, itself and any empty one, but not one reaching past")
    func containsHalfOpenRange() throws {
        let range = try pounds(10_00)..<pounds(250_00)

        #expect(try range.contains(pounds(20_00)..<pounds(250_00)))
        #expect(try range.contains(range))
        #expect(try range.contains(pounds(500_00)..<pounds(500_00)))
        #expect(try range.contains(pounds(20_00)..<pounds(250_01)) == false)
    }

    @Test("Contains a closed range only when its upper bound is below this one's")
    func containsClosedRange() throws {
        let range = try pounds(0)..<pounds(1_01)

        #expect(try range.contains(pounds(0)...pounds(1_00)))
        #expect(try range.contains(pounds(0)...pounds(1_01)) == false)
    }

    @Test("Overlaps what shares an amount, not a range it only touches or an empty one")
    func overlaps() throws {
        let range = try pounds(10_00)..<pounds(20_00)

        #expect(try range.overlaps(pounds(19_99)..<pounds(30_00)))
        #expect(try range.overlaps(pounds(20_00)..<pounds(30_00)) == false)
        #expect(try range.overlaps(pounds(15_00)..<pounds(15_00)) == false)
        #expect(try range.overlaps(pounds(5_00)...pounds(10_00)))
        #expect(try range.overlaps(pounds(20_00)...pounds(30_00)) == false)
    }

    @Test("Clamping narrows to the limits, and collapses to an empty range when disjoint")
    func clampedToRange() throws {
        let limits = try pounds(10_00)..<pounds(250_00)

        #expect(try (pounds(5_00)..<pounds(500_00)).clamped(to: limits) == limits)
        #expect(try (pounds(300_00)..<pounds(400_00)).clamped(to: limits).isEmpty)
    }

    @Test("Comparing with a range in another currency throws a mismatch, receiver's currency first")
    func rangeOperationsMismatch() throws {
        let range = try pounds(10_00)..<pounds(20_00)
        let closedEuros = try euros(10_00)...euros(20_00)
        let halfOpenEuros = try euros(10_00)..<euros(20_00)
        let mismatch = MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)

        #expect(throws: mismatch) { try range.contains(closedEuros) }
        #expect(throws: mismatch) { try range.contains(halfOpenEuros) }
        #expect(throws: mismatch) { try range.overlaps(closedEuros) }
        #expect(throws: mismatch) { try range.overlaps(halfOpenEuros) }
        #expect(throws: mismatch) { try range.clamped(to: halfOpenEuros) }
    }

    @Test("A range in a custom currency differs from one at the same code and another scale")
    func customScale() throws {
        let fine = Millicredits.currency
        let coarse = customCurrency(code: "MCR", unitScale: 1)
        let fineRange = try Money(minorUnits: 1, currency: fine)..<Money(minorUnits: 2, currency: fine)
        let coarseRange = try Money(minorUnits: 1, currency: coarse)..<Money(minorUnits: 2, currency: coarse)

        #expect(fineRange != coarseRange)
        #expect(throws: MoneyError.currencyMismatch(lhs: fine, rhs: coarse)) {
            try fineRange.contains(Money(minorUnits: 1, currency: coarse))
        }
    }

    @Test("Empty ranges at different bounds are unequal, as the standard library's are")
    func emptyRangesCompareBounds() throws {
        #expect((5..<5) != (6..<6))
        #expect(try pounds(5_00)..<pounds(5_00) != pounds(6_00)..<pounds(6_00))
    }

    @Test("Bounds at the extremes of Int64 build a range that holds the lower and not the upper")
    func int64Extremes() throws {
        let range = try pounds(.min)..<pounds(.max)

        #expect(range.lowerBound == pounds(.min))
        #expect(range.upperBound == pounds(.max))
        #expect(try range.contains(pounds(.min)))
        #expect(try range.contains(pounds(.max - 1)))
        #expect(try range.contains(pounds(.max)) == false)
        #expect(throws: BuildError.invertedBounds(lowerBound: pounds(.max), upperBound: pounds(.min))) {
            try pounds(.max)..<pounds(.min)
        }
    }

    @Test("Equal ranges hash equally, and the same bounds in another currency are unequal")
    func hashAndEquality() throws {
        let first = try pounds(1_00)..<pounds(2_00)
        let second = try pounds(1_00)..<pounds(2_00)

        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
        #expect(try first != euros(1_00)..<euros(2_00))
    }

    @Test("Describes itself as the standard library writes a half-open range")
    func descriptions() throws {
        let sterling = try pounds(10_00)..<pounds(250_00)
        let yen = try Money(minorUnits: 10, currency: .jpy)..<Money(minorUnits: 250, currency: .jpy)

        #expect(sterling.description == "GBP 10.00..<GBP 250.00")
        #expect(sterling.debugDescription == "MoneyRange(GBP 10.00..<GBP 250.00)")
        #expect(yen.description == "JPY 10..<JPY 250")
        #expect(yen.debugDescription == "MoneyRange(JPY 10..<JPY 250)")
    }
}
